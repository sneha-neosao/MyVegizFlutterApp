import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import '../../../../routes/app_route_path.dart';
import '../../data/models/address_model.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../bloc/places_bloc.dart';
import '../../bloc/address_bloc.dart';
import '../../bloc/address_event.dart';
import '../../bloc/address_state.dart';

class MapLocationPage extends StatefulWidget {
  /// Passed when opening from Home/SelectLocation — just set location, don't save.
  final bool fromHome;

  /// Jump to live GPS on open (add-new-address flow).
  final bool fetchCurrentLocation;

  /// Non-null when opening for editing an existing address.
  final AddressModel? existingAddress;

  const MapLocationPage({
    super.key,
    this.fromHome = false,
    this.fetchCurrentLocation = false,
    this.existingAddress,
  });

  @override
  State<MapLocationPage> createState() => _MapLocationPageState();
}

class _MapLocationPageState extends State<MapLocationPage> {
  // ── Map state ────────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng _lastMapPosition = const LatLng(0.0, 0.0);
  String _currentAddress = 'Fetching address…';
  String _currentCity = '';
  String _currentPincode = '';
  bool _isReverseGeocoding = false;

  /// Flips to true the moment GoogleMap fires onMapCreated — until then the
  /// skeleton shimmer is shown instead of the real UI.
  bool _mapLoaded = false;

  // ── Forward Geocoding state ──────────────────────────────────────────────────
  Timer? _geocodeDebounce;
  bool _isForwardGeocoding = false;
  final _geocoding = Geocoding();

  // ── Search state ─────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showSuggestions = false;

  // ── Form state ────────────────────────────────────────────────────────────────
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  String _selectedLabel = 'Home';
  bool _isAttemptedSave = false;

  @override
  void initState() {
    super.initState();
    logger.i(
      '📍 MapLocationPage: Initializing — '
      'editMode=${widget.existingAddress != null}',
    );

    if (widget.existingAddress != null) {
      // ── Edit mode — centre on saved address ──────────────────────────────────
      final addr = widget.existingAddress!;
      if (addr.lat != null && addr.lng != null) {
        _lastMapPosition = LatLng(addr.lat!, addr.lng!);
      }
      _currentAddress = addr.addressLine;
      _currentCity = addr.city ?? '';
      _currentPincode = addr.pincode ?? '';
      _selectedLabel = addr.label.isEmpty ? 'Home' : addr.label;
      _addressCtrl.text = addr.addressLine;
      _cityCtrl.text = addr.city ?? '';
      _pincodeCtrl.text = addr.pincode ?? '';
    } else {
      // ── Add mode — use last known location as starting point ─────────────────
      final loc = locationService.locationNotifier.value;
      if (loc != null) {
        _lastMapPosition = LatLng(loc.lat, loc.lng);
        _currentAddress = loc.address;
        _currentCity = loc.city ?? '';
        _currentPincode = loc.pincode ?? '';
      }
    }

    // Pre-load customer name / phone from secure storage.
    _loadCustomerDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingAddress == null) {
        // Add-mode: jump to live GPS.
        _getCurrentLocation();
      }
    });
  }

  Future<void> _loadCustomerDetails() async {
    final existingAddr = widget.existingAddress;
    if (existingAddr != null) {
      // Edit mode — pre-fill from the existing address record.
      setState(() {
        _nameCtrl.text = existingAddr.deliveryName;
        _phoneCtrl.text = existingAddr.deliveryPhone;
      });
    } else {
      // Add mode — pull from secure storage.
      final name = await SecureStorage.getCustomerName() ?? '';
      final contact = await SecureStorage.getCustomerContact() ?? '';
      if (mounted) {
        setState(() {
          _nameCtrl.text = name;
          _phoneCtrl.text = contact;
        });
      }
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  // ── Map callbacks ─────────────────────────────────────────────────────────────

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  Future<void> _onCameraIdle() async {
    if (!_showSuggestions) {
      logger.d('📍 MapLocationPage: Camera idle at $_lastMapPosition');
      await _reverseGeocode(_lastMapPosition);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    if (_isReverseGeocoding) return;
    setState(() => _isReverseGeocoding = true);
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e!.isNotEmpty).toList();

        final fullAddress = parts.join(', ');
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final pincode = place.postalCode ?? '';

        setState(() {
          _currentAddress = fullAddress;
          _currentCity = city;
          _currentPincode = pincode;
          _addressCtrl.text = fullAddress;
          _cityCtrl.text = city;
          _pincodeCtrl.text = pincode;
          _isReverseGeocoding = false;
        });
      }
    } catch (e) {
      logger.e('Geocoding error: $e');
      setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _forwardGeocode() async {
    final query = [
      _addressCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _pincodeCtrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    if (query.isEmpty) return;
    if (_isReverseGeocoding) return;

    setState(() => _isForwardGeocoding = true);
    try {
      logger.i('📍 MapLocationPage: Forward geocoding "$query"');
      final locations = await _geocoding.locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        _lastMapPosition = target;
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(target, 16.0),
        );
        logger.i('📍 MapLocationPage: Map moved to $target via forward geocoding');
      }
    } catch (e) {
      logger.e('Forward geocoding error: $e');
    } finally {
      if (mounted) {
        setState(() => _isForwardGeocoding = false);
      }
    }
  }

  void _onAddressFieldChanged({bool immediate = false}) {
    _geocodeDebounce?.cancel();
    if (immediate) {
      _forwardGeocode();
    } else {
      _geocodeDebounce = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _forwardGeocode();
        }
      });
    }
  }

  // ── Current location ──────────────────────────────────────────────────────────

  Future<void> _getCurrentLocation() async {
    try {
      logger.i('📍 MapLocationPage: Fetching current location…');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Location services are disabled.',
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            SnackbarUtils.showErrorSnackbar(
              context,
              'Location permissions are denied.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Location permissions are permanently denied.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      logger.i(
        '📍 MapLocationPage: Current position acquired: '
        '${position.latitude}, ${position.longitude}',
      );

      if (_mapController != null && mounted) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0,
          ),
        );
      }
    } catch (e) {
      logger.e('Error getting current location: $e');
    }
  }

  // ── Search helpers ────────────────────────────────────────────────────────────

  void _onSearchChanged(String value, BuildContext blocCtx) {
    if (value.trim().isEmpty) {
      setState(() => _showSuggestions = false);
      blocCtx.read<PlacesBloc>().add(ClearSuggestionsEvent());
    } else {
      setState(() => _showSuggestions = true);
      blocCtx.read<PlacesBloc>().add(SearchPlacesEvent(value));
    }
  }

  void _clearSearch(BuildContext blocCtx) {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
    blocCtx.read<PlacesBloc>().add(ClearSuggestionsEvent());
  }

  void _selectSuggestion(BuildContext blocCtx, String placeId) {
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
    blocCtx.read<PlacesBloc>().add(SelectPlaceEvent(placeId));
  }

  // ── Form validation ───────────────────────────────────────────────────────────

  bool get _isFormValid {
    return _nameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressCtrl.text.trim().isNotEmpty;
  }

  // ── Confirm / Save ────────────────────────────────────────────────────────────

  void _onConfirm(BuildContext parentCtx) {
    setState(() => _isAttemptedSave = true);
    if (!_isFormValid) {
      SnackbarUtils.showErrorSnackbar(
        parentCtx,
        'Please fill in all required fields.',
      );
      return;
    }

    final addressData = AddressModel(
      uuId: widget.existingAddress?.uuId,
      label: _selectedLabel,
      deliveryName: _nameCtrl.text.trim(),
      deliveryPhone: _phoneCtrl.text.trim(),
      addressLine: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      pincode:
          _pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim(),
      lat: _lastMapPosition.latitude,
      lng: _lastMapPosition.longitude,
      isDefault: false,
    );

    // Update location service notifier and persist.
    final newLocState = LocationState(
      lat: _lastMapPosition.latitude,
      lng: _lastMapPosition.longitude,
      address: _addressCtrl.text.trim(),
      label: _selectedLabel,
      city: _cityCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
    );
    locationService.setLocation(newLocState, isManual: true);

    if (widget.existingAddress != null &&
        widget.existingAddress!.uuId != null) {
      logger.i('📍 MapLocationPage: Dispatching UpdateAddressEvent');
      parentCtx.read<AddressBloc>().add(
        UpdateAddressEvent(
          uuId: widget.existingAddress!.uuId!,
          address: addressData,
        ),
      );
    } else {
      logger.i('📍 MapLocationPage: Dispatching AddAddressEvent');
      parentCtx.read<AddressBloc>().add(AddAddressEvent(addressData));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlacesBloc>(
      create: (_) => getIt<PlacesBloc>(),
      child: Builder(
        builder: (blocCtx) {
          return BlocListener<PlacesBloc, PlacesState>(
            listener: (context, state) {
              if (state is PlaceSelected) {
                final target = LatLng(state.details.lat, state.details.lng);
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(target, 16.0),
                );
                _lastMapPosition = target;
                setState(() {
                  _currentAddress = state.details.formattedAddress;
                  _addressCtrl.text = state.details.formattedAddress;
                  _searchCtrl.text = state.details.name;
                });
                logger.i(
                  '📍 MapLocationPage: Camera moved to '
                  '${state.details.lat}, ${state.details.lng}',
                );
              } else if (state is PlacesError) {
                SnackbarUtils.showErrorSnackbar(context, state.message);
              }
            },
            child: BlocListener<AddressBloc, AddressState>(
              listener: (context, state) async {
                if (state is AddressActionSuccess) {
                  SnackbarUtils.showSuccessSnackbar(context, state.message);

                  final newLocState = LocationState(
                    lat: _lastMapPosition.latitude,
                    lng: _lastMapPosition.longitude,
                    address: _addressCtrl.text.trim(),
                    label: _selectedLabel,
                    city: _cityCtrl.text.trim(),
                    pincode: _pincodeCtrl.text.trim(),
                  );
                  await locationService.setLocation(newLocState, isManual: true);

                  if (context.mounted) {
                    logger.i('📍 MapLocationPage: Address saved successfully, navigating directly to home');
                    context.go(AppRoutePath.home);
                  }
                } else if (state is AddressError) {
                  SnackbarUtils.showErrorSnackbar(context, state.message);
                }
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                resizeToAvoidBottomInset: true,
                // ── AppBar — same style as WishlistPage ──────────────────────
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      logger.i('📍 MapLocationPage: Back pressed');
                      if (_showSuggestions) {
                        _clearSearch(blocCtx);
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutePath.address);
                      }
                    },
                  ),
                  title: Text(
                    widget.existingAddress != null
                        ? 'Edit Address'
                        : 'Add New Address',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                body: Stack(
                  children: [
                    // ── Map takes up roughly top half ──────────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _lastMapPosition,
                          zoom: 16.0,
                        ),
                        onMapCreated: (controller) {
                            _mapController = controller;
                            if (!_mapLoaded) {
                              setState(() => _mapLoaded = true);
                            }
                          },
                        onCameraMove: _onCameraMove,
                        onCameraIdle: _onCameraIdle,
                        zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                      ),
                    ),

                    // ── Centre pin overlay ─────────────────────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      // pin sits above the bottom sheet (~45% of screen height)
                      bottom: MediaQuery.of(context).size.height * 0.47,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: Colors.deepOrange,
                                size: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── "Drag map to adjust" label ────────────────────────────
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.46,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C2E),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.location_on,
                                color: Color(0xFF3DCFB0),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Drag map to adjust',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Search bar ────────────────────────────────────────────
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            // Search input
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchCtrl,
                                        focusNode: _searchFocus,
                                        onChanged: (v) =>
                                            _onSearchChanged(v, blocCtx),
                                        textInputAction: TextInputAction.search,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search for area, street…',
                                          hintStyle: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    if (_searchCtrl.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        onPressed: () => _clearSearch(blocCtx),
                                      )
                                    else
                                      // "Go" arrow button (teal/green like image)
                                      Container(
                                        margin: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F8F0),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.send,
                                            color: Color(0xFF1DA462),
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            if (_searchCtrl.text.isNotEmpty) {
                                              _onSearchChanged(
                                                _searchCtrl.text,
                                                blocCtx,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Suggestions overlay ───────────────────────────────────
                    if (_showSuggestions)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 64,
                        left: 16,
                        right: 16,
                        child: BlocBuilder<PlacesBloc, PlacesState>(
                          builder: (context, state) {
                            if (state is PlacesLoading) {
                              return _suggestionShell(
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            if (state is PlacesSuggested &&
                                state.suggestions.isNotEmpty) {
                              return _suggestionShell(
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      state.suggestions.length > 5
                                      ? 5
                                      : state.suggestions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                    indent: 48,
                                  ),
                                  itemBuilder: (context, i) {
                                    final s = state.suggestions[i];
                                    return ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      leading: const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.deepOrange,
                                        size: 22,
                                      ),
                                      title: Text(
                                        s.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      onTap: () {
                                        _searchCtrl.text = s.description;
                                        _selectSuggestion(blocCtx, s.placeId);
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                            if (state is PlacesSuggested &&
                                state.suggestions.isEmpty) {
                              return _suggestionShell(
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'No results found',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),

                    // ── Bottom form container (fitted to content) ────────────
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, -3),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              12.h,
                              16.w,
                              12.h,
                            ),
                            child: _buildForm(blocCtx),
                          ),
                        ),
                      ),
                    ),

                    // ── Shimmer Overlay ───────────────────────────────────────
                    if (!_mapLoaded)
                      Positioned.fill(
                        child: _buildSkeletonBody(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Full address form ─────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext blocCtx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SAVE ADDRESS AS ───────────────────────────────────────────────────
        Text(
          'SAVE ADDRESS AS',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: ['Home', 'Work', 'Other'].map((label) {
            final bool selected = _selectedLabel == label;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedLabel = label),
                child: Container(
                  margin: EdgeInsets.only(
                    right: label == 'Other' ? 0 : 8.w,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE8F8F0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1DA462)
                          : Colors.grey.shade300,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        label == 'Home'
                            ? Icons.home_outlined
                            : label == 'Work'
                            ? Icons.work_outline
                            : Icons.favorite_border,
                        size: 15.w,
                        color: selected
                            ? const Color(0xFF1DA462)
                            : Colors.black54,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF1DA462)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 10.h),

        // ── RECEIVER NAME / PHONE ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'RECEIVER NAME',
                controller: _nameCtrl,
                hint: 'Full name',
                showError: _isAttemptedSave &&
                    _nameCtrl.text.trim().isEmpty,
                errorMsg: 'Name is required',
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildLabeledField(
                label: 'RECEIVER PHONE',
                controller: _phoneCtrl,
                hint: 'Phone number',
                keyboardType: TextInputType.phone,
                showError: _isAttemptedSave &&
                    _phoneCtrl.text.trim().isEmpty,
                errorMsg: 'Phone is required',
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // ── COMPLETE ADDRESS ──────────────────────────────────────────────────
        Text(
          'COMPLETE ADDRESS',
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.w),
            border: Border.all(
              color: _isAttemptedSave && _addressCtrl.text.trim().isEmpty
                  ? Colors.red
                  : const Color(0xFF1DA462),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _addressCtrl,
            maxLines: 2,
            style: TextStyle(fontSize: 12.sp),
            onChanged: (_) {
              setState(() {});
              _onAddressFieldChanged();
            },
            onSubmitted: (_) => _onAddressFieldChanged(immediate: true),
            decoration: InputDecoration(
              hintText: 'Full address',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 8.h,
              ),
              suffixIcon: (_isReverseGeocoding || _isForwardGeocoding)
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(height: 10.h),

        // ── CITY / PINCODE ────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'CITY',
                controller: _cityCtrl,
                hint: 'City',
                onChanged: _onAddressFieldChanged,
                onSubmitted: () => _onAddressFieldChanged(immediate: true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildLabeledField(
                label: 'PINCODE',
                controller: _pincodeCtrl,
                hint: 'Pincode',
                keyboardType: TextInputType.number,
                onChanged: _onAddressFieldChanged,
                onSubmitted: () => _onAddressFieldChanged(immediate: true),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Divider ───────────────────────────────────────────────────────────
        Divider(height: 1, color: Colors.grey.shade200),
        SizedBox(height: 10.h),

        // ── Cancel / Confirm buttons ──────────────────────────────────────────
        BlocBuilder<AddressBloc, AddressState>(
          builder: (context, state) {
            final isLoading = state is AddressLoading;
            return Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRoutePath.address);
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Confirm
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _onConfirm(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      backgroundColor: const Color(0xFF1DA462),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.existingAddress != null &&
                                    widget.existingAddress!.uuId != null
                                ? 'Update'
                                : 'Confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Reusable labeled text field ───────────────────────────────────────────────

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    bool showError = false,
    String? errorMsg,
    VoidCallback? onChanged,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 3.h),
        Container(
          height: 36.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.w),
            color: Colors.grey.shade100,
            border: showError
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
            onChanged: (val) {
              setState(() {});
              if (onChanged != null) onChanged();
            },
            onSubmitted: (_) {
              if (onSubmitted != null) onSubmitted();
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12.sp,
              ),
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 8.h,
              ),
            ),
          ),
        ),
        if (showError && errorMsg != null)
          Padding(
            padding: EdgeInsets.only(top: 2.h, left: 2.w),
            child: Text(
              errorMsg,
              style: TextStyle(
                color: Colors.red,
                fontSize: 9.5.sp,
              ),
            ),
          ),
      ],
    );
  }

  /// White card that wraps the suggestions list.
  Widget _suggestionShell({required Widget child}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }

  // ── Skeleton shimmer — shown while the map initialises ───────────────────────

  // ── Skeleton shimmer body overlay — shown while the map initialises ──────────

  Widget _buildSkeletonBody() {
    final h = MediaQuery.of(context).size.height;
    final shimmerBase = Colors.grey.shade300;
    final shimmerHigh = Colors.grey.shade100;

    Widget shimBox({
      double width = double.infinity,
      required double height,
      double radius = 10,
    }) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: shimmerBase,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHigh,
      period: const Duration(milliseconds: 1200),
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // map area
            Positioned(
              top: 0, left: 0, right: 0,
              bottom: h * 0.47,
              child: Container(color: Colors.grey.shade200),
            ),
            // search bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: shimBox(height: 48, radius: 24),
              ),
            ),
            // pin
            Positioned(
              top: 0, left: 0, right: 0,
              bottom: h * 0.47 + 28,
              child: Center(child: shimBox(width: 36, height: 52, radius: 18)),
            ),
            // "Drag map" pill
            Positioned(
              bottom: h * 0.46, left: 0, right: 0,
              child: Center(child: shimBox(width: 180, height: 32, radius: 20)),
            ),
            // bottom sheet
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: h * 0.48,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 14),
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            shimBox(width: 130, height: 11, radius: 4),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(child: shimBox(height: 38, radius: 24)),
                              const SizedBox(width: 8),
                              Expanded(child: shimBox(height: 38, radius: 24)),
                              const SizedBox(width: 8),
                              Expanded(child: shimBox(height: 38, radius: 24)),
                            ]),
                            const SizedBox(height: 18),
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                shimBox(width: 100, height: 11, radius: 4),
                                const SizedBox(height: 6),
                                shimBox(height: 42, radius: 10),
                              ])),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                shimBox(width: 110, height: 11, radius: 4),
                                const SizedBox(height: 6),
                                shimBox(height: 42, radius: 10),
                              ])),
                            ]),
                            const SizedBox(height: 18),
                            shimBox(width: 140, height: 11, radius: 4),
                            const SizedBox(height: 8),
                            shimBox(height: 78, radius: 12),
                            const SizedBox(height: 18),
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                shimBox(width: 40, height: 11, radius: 4),
                                const SizedBox(height: 6),
                                shimBox(height: 42, radius: 10),
                              ])),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                shimBox(width: 70, height: 11, radius: 4),
                                const SizedBox(height: 6),
                                shimBox(height: 42, radius: 10),
                              ])),
                            ]),
                            const SizedBox(height: 18),
                            Row(children: [
                              shimBox(width: 22, height: 22, radius: 4),
                              const SizedBox(width: 10),
                              shimBox(width: 110, height: 14, radius: 4),
                            ]),
                            const SizedBox(height: 20),
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(child: shimBox(height: 48, radius: 12)),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: shimBox(height: 48, radius: 12)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

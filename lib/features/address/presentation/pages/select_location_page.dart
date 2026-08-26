import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import '../../bloc/address_bloc.dart';
import '../../bloc/address_event.dart';
import '../../bloc/address_state.dart';
import '../../bloc/places_bloc.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../widgets/shimmer_placeholder.dart';

class RecentLocation {
  final String title;
  final String addressLine;
  final double lat;
  final double lng;
  final String city;
  final String pincode;

  RecentLocation({
    required this.title,
    required this.addressLine,
    required this.lat,
    required this.lng,
    this.city = '',
    this.pincode = '',
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'addressLine': addressLine,
    'lat': lat,
    'lng': lng,
    'city': city,
    'pincode': pincode,
  };

  factory RecentLocation.fromJson(Map<String, dynamic> json) {
    return RecentLocation(
      title: json['title'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );
  }
}

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showSuggestions = false;
  bool _isFetchingCurrent = false;

  Position? _currentGPSPosition;
  List<RecentLocation> _recentLocations = [];

  @override
  void initState() {
    super.initState();
    logger.i("📍 SelectLocationPage: Initializing");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressBloc>().add(FetchAddressList());
      _loadRecentLocations();
      _getCurrentGPSLocation();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecentLocations() async {
    try {
      final jsonStr = await SecureStorage.getRecentlySearched();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List decoded = jsonDecode(jsonStr);
        setState(() {
          _recentLocations = decoded
              .map(
                (item) => RecentLocation.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        });
      }
    } catch (e) {
      logger.e("Error loading recent locations: $e");
    }
  }

  Future<void> _saveRecentLocation(RecentLocation location) async {
    try {
      // Remove duplicate if exists
      _recentLocations.removeWhere(
        (item) =>
            (item.lat - location.lat).abs() < 0.0001 &&
            (item.lng - location.lng).abs() < 0.0001,
      );

      // Insert at top
      _recentLocations.insert(0, location);

      // Limit to 5 items
      if (_recentLocations.length > 5) {
        _recentLocations = _recentLocations.sublist(0, 5);
      }

      final jsonStr = jsonEncode(
        _recentLocations.map((e) => e.toJson()).toList(),
      );
      await SecureStorage.saveRecentlySearched(jsonStr);
      setState(() {});
    } catch (e) {
      logger.e("Error saving recent location: $e");
    }
  }

  Future<void> _getCurrentGPSLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
      if (mounted) {
        setState(() {
          _currentGPSPosition = position;
        });
      }
    } catch (e) {
      logger.w(
        "Failed to get current GPS location for distance calculation: $e",
      );
    }
  }

  String _getFormattedDistance(double? lat, double? lng) {
    final anchorLat =
        _currentGPSPosition?.latitude ??
        locationService.locationNotifier.value?.lat;
    final anchorLng =
        _currentGPSPosition?.longitude ??
        locationService.locationNotifier.value?.lng;

    if (lat == null || lng == null || anchorLat == null || anchorLng == null) {
      return '';
    }

    final meters = Geolocator.distanceBetween(anchorLat, anchorLng, lat, lng);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  void _useCurrentLocation() {
    logger.i(
      "📍 SelectLocationPage: Opening map screen to fetch current location...",
    );
    context
        .push(
          AppRoutePath.mapLocation,
          extra: {'fromHome': true, 'fetchCurrentLocation': true},
        )
        .then((_) {
          if (mounted) {
            context.read<AddressBloc>().add(FetchAddressList());
          }
        });
  }

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
    blocCtx.read<PlacesBloc>().add(SelectPlaceEvent(placeId));
  }

  void _editAddress(AddressModel address) {
    context.push(AppRoutePath.mapLocation, extra: {
      'existingAddress': address,
      'fromHome': false,
      'fetchCurrentLocation': false,
    }).then((_) {
      if (mounted) {
        context.read<AddressBloc>().add(FetchAddressList());
      }
    });
  }

  void _shareAddress(AddressModel address) {
    final text =
        'Address: ${address.addressLine}, Landmark: ${address.landmark ?? ""}, Contact: ${address.deliveryName} (${address.deliveryPhone})';
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (mounted) {
        SnackbarUtils.showSuccessSnackbar(
          context,
          "Address details copied to clipboard!",
        );
      }
    });
  }

  void _deleteAddress(AddressModel address) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Delete Address',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text('Are you sure you want to delete this address?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (address.uuId != null) {
                  context.read<AddressBloc>().add(
                    DeleteAddressEvent(address.uuId!),
                  );
                }
              },
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _requestAddress() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Address',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Ask a friend or contact to share their address with you.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp),
              ),
              const SizedBox(height: 24),
              // ListTile(
              //   leading: CircleAvatar(
              //     backgroundColor: Colors.green.shade50,
              //     child: const Icon(Icons.whatsapp, color: Colors.green),
              //   ),
              //   title: const Text('Request via WhatsApp'),
              //   subtitle: const Text('Send a request message in WhatsApp'),
              //   trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              //   onTap: () {
              //     Navigator.pop(context);
              //     final text = "Hey! Please share your address with me so I can set it up in the MyViggies app.";
              //     Clipboard.setData(ClipboardData(text: text)).then((_) {
              //       if (mounted) {
              //         SnackbarUtils.showSuccessSnackbar(
              //           context,
              //           "WhatsApp request copied to clipboard! (Opening WhatsApp mockup)",
              //         );
              //       }
              //     });
              //   },
              // ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.copy, color: Colors.blue),
                ),
                title: const Text('Copy request link'),
                subtitle: const Text('Copy request text to clipboard'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.pop(context);
                  final text =
                      "Hey! Please share your address with me so I can set it up in the MyViggies app.";
                  Clipboard.setData(ClipboardData(text: text)).then((_) {
                    if (mounted) {
                      SnackbarUtils.showSuccessSnackbar(
                        context,
                        "Request copied to clipboard!",
                      );
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlacesBloc>(
      create: (_) => getIt<PlacesBloc>(),
      child: Builder(
        builder: (blocCtx) {
          return BlocListener<PlacesBloc, PlacesState>(
            listener: (context, state) {
              if (state is PlaceSelected) {
                final lat = state.details.lat;
                final lng = state.details.lng;
                final address = state.details.formattedAddress;

                logger.i(
                  "📍 SelectLocationPage: PlaceSelected callback - lat=$lat, lng=$lng",
                );

                final recent = RecentLocation(
                  title: state.details.name.isNotEmpty
                      ? state.details.name
                      : 'Searched Location',
                  addressLine: address,
                  lat: lat,
                  lng: lng,
                );
                _saveRecentLocation(recent);

                final newState = LocationState(
                  lat: lat,
                  lng: lng,
                  address: address,
                  label: state.details.name.isNotEmpty
                      ? state.details.name
                      : 'Searched Location',
                );
                locationService.setLocation(newState, isManual: true);

                _clearSearch(blocCtx);

                context
                    .push(AppRoutePath.mapLocation, extra: {'fromHome': true})
                    .then((_) {
                      if (mounted) {
                        context.read<AddressBloc>().add(FetchAddressList());
                      }
                    });
              } else if (state is PlacesError) {
                SnackbarUtils.showErrorSnackbar(context, state.message);
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F5F8),
              appBar: AppBar(
                backgroundColor: Colors.white,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  onPressed: () {
                    logger.i("📍 SelectLocationPage: Back pressed");
                    if (_showSuggestions) {
                      _clearSearch(blocCtx);
                    } else {
                      context.pop();
                    }
                  },
                ),
                title: Text(
                  'Select Your Location',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ),
              body: Column(
                children: [
                  // ── Search Input Field ──────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        onChanged: (v) => _onSearchChanged(v, blocCtx),
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Search an area or address',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13.5,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                  onPressed: () => _clearSearch(blocCtx),
                                )
                              : const Icon(Icons.search, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                  ),

                  // ── Suggestions List or Main View ───────────────────────────
                  Expanded(
                    child: _showSuggestions
                        ? _buildSuggestionsOverlay(blocCtx)
                        : _buildMainScrollableContent(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsOverlay(BuildContext blocCtx) {
    return BlocBuilder<PlacesBloc, PlacesState>(
      builder: (context, state) {
        if (state is PlacesLoading) {
          return const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (state is PlacesSuggested && state.suggestions.isNotEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.suggestions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, i) {
              final suggestion = state.suggestions[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  radius: 18,
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.deepOrange,
                    size: 20,
                  ),
                ),
                title: Text(
                  suggestion.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _selectSuggestion(blocCtx, suggestion.placeId),
              );
            },
          );
        }

        if (state is PlacesSuggested && state.suggestions.isEmpty) {
          return const Center(
            child: Text(
              'No results found',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMainScrollableContent() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AddressBloc>().add(FetchAddressList());
        await _loadRecentLocations();
        await _getCurrentGPSLocation();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Action Cards Row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildActionCard(
                    icon: Icons.my_location,
                    iconColor: const Color(0xFFFC8019),
                    title: 'Use Current Location',
                    onTap: _useCurrentLocation,
                  ),
                  const SizedBox(width: 10),
                  _buildActionCard(
                    icon: Icons.add_box_outlined,
                    iconColor: const Color(0xFFFC8019),
                    title: 'Add New Address',
                    onTap: () {
                      logger.i("📍 SelectLocationPage: Add New Address tapped");
                      context
                          .push(
                            AppRoutePath.mapLocation,
                            extra: {'fromHome': false},
                          )
                          .then((_) {
                            if (mounted) {
                              context.read<AddressBloc>().add(
                                FetchAddressList(),
                              );
                            }
                          });
                    },
                  ),
                ],
              ),
            ),

            // ── Saved Address Section ──────────────────────────────────────────
            _buildSectionHeader('SAVED ADDRESSES'),
            BlocBuilder<AddressBloc, AddressState>(
              builder: (context, state) {
                if (state is AddressLoading) {
                  return _buildAddressShimmer();
                }
                if (state is AddressLoaded) {
                  if (state.addresses.isEmpty) {
                    return _buildEmptyContainer(
                      "No saved addresses yet. Add a new address above!",
                    );
                  }
                  return _buildAddressCardList(state.addresses);
                }
                if (state is AddressError) {
                  return _buildEmptyContainer(
                    "Error loading addresses. Tap here to retry.",
                    onTap: () {
                      context.read<AddressBloc>().add(FetchAddressList());
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ── Recently Searched Section ──────────────────────────────────────
            if (_recentLocations.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildSectionHeader('RECENTLY SEARCHED'),
              _buildRecentSearchedCardList(),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: iconColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, bottom: 4.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildAddressShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 10,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder.circular(width: 32, height: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerPlaceholder.rounded(
                          height: 14,
                          width: 80,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 8),
                        ShimmerPlaceholder.rounded(
                          height: 12,
                          width: double.infinity,
                          borderRadius: 4,
                        ),
                        const SizedBox(height: 6),
                        ShimmerPlaceholder.rounded(
                          height: 12,
                          width: 140,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyContainer(String message, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCardList(List<AddressModel> addresses) {
    final activeVal = locationService.locationNotifier.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: addresses.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final address = addresses[index];
            final distanceStr = _getFormattedDistance(address.lat, address.lng);
            final bool isSelected =
                activeVal != null &&
                address.lat != null &&
                address.lng != null &&
                (activeVal.lat - address.lat!).abs() < 0.0001 &&
                (activeVal.lng - address.lng!).abs() < 0.0001;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                // onTap: () {
                //   logger.i(
                //     "📍 SelectLocationPage: Saved Address selected: ${address.label}",
                //   );
                //   if (address.lat != null && address.lng != null) {
                //     locationService.locationNotifier.value = LocationState(
                //       lat: address.lat!,
                //       lng: address.lng!,
                //       address: address.addressLine,
                //       label: address.label,
                //       city: address.city,
                //       pincode: address.pincode,
                //     );
                //     SecureStorage.saveSelectedAddressUuid(
                //       address.uuId ?? address.id.toString(),
                //     );
                //   }
                //   // context.push(
                //   //   AppRoutePath.mapLocation,
                //   //   extra: {'fromHome': true},
                //   // );

                //   if (mounted) {
                //     context.pop(true);
                //   }
                // },
                onTap: () async {
                  logger.i(
                    "📍 SelectLocationPage: Saved Address selected: ${address.label}",
                  );

                  if (address.lat != null && address.lng != null) {
                    final newState = LocationState(
                      lat: address.lat!,
                      lng: address.lng!,
                      address: address.addressLine,
                      label: address.label,
                      city: address.city,
                      pincode: address.pincode,
                    );
                    await locationService.setLocation(newState, isManual: true);

                    await SecureStorage.saveSelectedAddressUuid(
                      address.uuId ?? address.id.toString(),
                    );
                  }

                  if (mounted) {
                    context.pop(true);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon and Distance column
                      _buildDistanceBadge(
                        icon: address.label.toLowerCase() == 'home'
                            ? Icons.home_outlined
                            : Icons.near_me_outlined,
                        distanceStr: distanceStr,
                      ),
                      const SizedBox(width: 12),

                      // Title and Address details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  address.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SELECTED',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              address.addressLine,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Popup menu button
                      PopupMenuButton<String>(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.black54,
                        ),
                        elevation: 8,
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editAddress(address);
                          } else if (value == 'share') {
                            _shareAddress(address);
                          } else if (value == 'delete') {
                            _deleteAddress(address);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.share,
                                  color: Colors.black87,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentSearchedCardList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _recentLocations.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final loc = _recentLocations[index];
            final distanceStr = _getFormattedDistance(loc.lat, loc.lng);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  logger.i(
                    "📍 SelectLocationPage: Recent search selected: ${loc.title}",
                  );
                  final newState = LocationState(
                    lat: loc.lat,
                    lng: loc.lng,
                    address: loc.addressLine,
                    label: loc.title,
                    city: loc.city,
                    pincode: loc.pincode,
                  );
                  locationService.setLocation(newState, isManual: true);
                  context.push(
                    AppRoutePath.mapLocation,
                    extra: {'fromHome': true},
                  );
                },

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Distance badge with clock icon
                      _buildDistanceBadge(
                        icon: Icons.history,
                        distanceStr: distanceStr,
                      ),
                      const SizedBox(width: 12),

                      // Title and Address details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loc.addressLine,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDistanceBadge({
    required IconData icon,
    required String distanceStr,
  }) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black87, size: 18),
          if (distanceStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              distanceStr,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

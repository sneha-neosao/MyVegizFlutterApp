import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_bloc.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_event.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_state.dart';
import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import 'package:my_vegiz_flutter/widgets/shimmer_placeholder.dart';

class SwiggyLocationSheet extends StatefulWidget {
  const SwiggyLocationSheet({super.key});

  /// Static helper to display the sheet easily anywhere in the app
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SwiggyLocationSheet(),
    );
  }

  @override
  State<SwiggyLocationSheet> createState() => _SwiggyLocationSheetState();
}

class _SwiggyLocationSheetState extends State<SwiggyLocationSheet> {
  Position? _currentGPSPosition;
  bool _isFetchingGPS = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressBloc>().add(FetchAddressList());
      _getGPSLocation();
    });
  }

  Future<void> _getGPSLocation() async {
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
    } catch (_) {}
  }

  String _getFormattedDistance(double? lat, double? lng) {
    final anchorLat = _currentGPSPosition?.latitude ??
        locationService.locationNotifier.value?.lat;
    final anchorLng = _currentGPSPosition?.longitude ??
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

  Future<void> _useCurrentLocation() async {
    setState(() => _isFetchingGPS = true);
    try {
      logger.i('📍 SwiggyLocationSheet: User selected "Use Current Location"');
      await locationService.requestPermissionAndFetchLocation(force: true);
      final loc = locationService.locationNotifier.value;
      if (loc != null) {
        await locationService.setLocation(loc, isManual: true);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  Future<void> _selectAddress(AddressModel address) async {
    logger.i('📍 SwiggyLocationSheet: Saved Address selected: ${address.label}');
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final currentLoc = locationService.locationNotifier.value;
    return Container(
      height: mediaQuery.size.height * 0.48,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Drag Handle ─────────────────────────────────────────────
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // ── Header Title & Close Button ─────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select location',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade700, size: 20.w),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Scrollable Body ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Current / Active Location Highlight Card ────────
                    if (currentLoc != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F8A5F).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14.w),
                          border: Border.all(
                            color: const Color(0xFF0F8A5F).withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(7.w),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F8A5F),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16.w,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Location',
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F8A5F),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    currentLoc.label ?? 'Selected Location',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    currentLoc.address,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: Colors.grey.shade700,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF0F8A5F),
                              size: 20.w,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],

                    // ── Quick Actions (Current Location & Add Address) ───
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isFetchingGPS ? null : _useCurrentLocation,
                            borderRadius: BorderRadius.circular(12.w),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.w),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  if (_isFetchingGPS)
                                    SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFC8019),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.my_location,
                                      color: const Color(0xFFFC8019),
                                      size: 18.w,
                                    ),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Text(
                                      'Use Current\nLocation',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                AppRoutePath.mapLocation,
                                extra: {'fromHome': false},
                              );
                            },
                            borderRadius: BorderRadius.circular(12.w),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.w),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_location_alt_outlined,
                                    color: const Color(0xFFFC8019),
                                    size: 18.w,
                                  ),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Text(
                                      'Add New\nAddress',
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // ── Saved Addresses Section ──────────────────────────
                    Text(
                      'SAVED ADDRESSES',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    BlocBuilder<AddressBloc, AddressState>(
                      builder: (context, state) {
                        if (state is AddressLoading) {
                          return _buildAddressShimmer();
                        }

                        if (state is AddressLoaded) {
                          if (state.addresses.isEmpty) {
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              alignment: Alignment.center,
                              child: Text(
                                'No saved addresses found. Add one above!',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.addresses.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final address = state.addresses[index];
                              final distanceStr = _getFormattedDistance(
                                address.lat,
                                address.lng,
                              );
                              final bool isSelected = currentLoc != null &&
                                  address.lat != null &&
                                  address.lng != null &&
                                  (currentLoc.lat - address.lat!).abs() < 0.0001 &&
                                  (currentLoc.lng - address.lng!).abs() < 0.0001;

                              return InkWell(
                                onTap: () => _selectAddress(address),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 9.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(7.w),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF0F8A5F).withValues(alpha: 0.1)
                                              : Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          address.label.toLowerCase() == 'home'
                                              ? Icons.home_outlined
                                              : address.label.toLowerCase() == 'work' ||
                                                      address.label.toLowerCase() == 'office'
                                                  ? Icons.business_outlined
                                                  : Icons.location_on_outlined,
                                          color: isSelected
                                              ? const Color(0xFF0F8A5F)
                                              : Colors.black87,
                                          size: 20.w,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  address.label,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.sp,
                                                    color: isSelected
                                                        ? const Color(0xFF0F8A5F)
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                if (distanceStr.isNotEmpty) ...[
                                                  SizedBox(width: 8.w),
                                                  Text(
                                                    distanceStr,
                                                    style: TextStyle(
                                                      fontSize: 11.sp,
                                                      color: Colors.grey.shade500,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                                if (isSelected) ...[
                                                  SizedBox(width: 8.w),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 6.w,
                                                      vertical: 2.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF0F8A5F).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: const Color(0xFF0F8A5F).withValues(alpha: 0.4),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'SELECTED',
                                                      style: TextStyle(
                                                        color: const Color(0xFF0F8A5F),
                                                        fontSize: 9.sp,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: 3.h),
                                            Text(
                                              address.addressLine,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        SizedBox(width: 8.w),
                                        Icon(
                                          Icons.check_circle,
                                          color: const Color(0xFF0F8A5F),
                                          size: 20.w,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        return const SizedBox.shrink();
                      },
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

  Widget _buildAddressShimmer() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerPlaceholder.circular(width: 32.w, height: 32.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 14.h,
                      width: 80.w,
                      borderRadius: 4.w,
                    ),
                    SizedBox(height: 6.h),
                    ShimmerPlaceholder.rounded(
                      height: 12.h,
                      width: double.infinity,
                      borderRadius: 4.w,
                    ),
                    SizedBox(height: 4.h),
                    ShimmerPlaceholder.rounded(
                      height: 12.h,
                      width: 140.w,
                      borderRadius: 4.w,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

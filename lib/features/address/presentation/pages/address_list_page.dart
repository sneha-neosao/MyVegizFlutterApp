import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import '../../../../routes/app_route_path.dart';
import '../../data/models/address_model.dart';
import '../../bloc/address_bloc.dart';
import '../../bloc/address_event.dart';
import '../../bloc/address_state.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  @override
  void initState() {
    super.initState();
    logger.i("📍 AddressListPage: Initializing - Fetching addresses");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressBloc>().add(FetchAddressList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressBloc, AddressState>(
      listener: (context, state) {
        if (state is AddressError) {
          logger.e("📍 AddressListPage: State Error - ${state.message}");
          if (state.message.contains('Unauthorized') ||
              state.message.contains('401') ||
              state.message.contains('Token expired')) {
            SecureStorage.clearAll().then((_) {
              if (context.mounted) {
                context.go(AppRoutePath.login);
              }
            });
          } else {
            SnackbarUtils.showErrorSnackbar(context, state.message);
          }
        }
        if (state is AddressActionSuccess) {
          logger.i("📍 AddressListPage: Action Success - ${state.message}");
          SnackbarUtils.showSuccessSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'Addresses',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
              ),
              onPressed: () {
                logger.i("📍 AddressListPage: Back pressed");
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutePath.home);
                }
              },
            ),
          ),
          body: SafeArea(
            bottom: true,
            top: false,
            child: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(AddressState state) {
    if (state is AddressLoading) {
      return _buildAddressShimmer();
    }

    if (state is AddressLoaded) {
      if (state.addresses.isEmpty) {
        logger.d("📍 AddressListPage: No addresses found");
        return _buildEmptyState();
      }
      return _buildAddressList(state.addresses);
    }

    if (state is AddressError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: ${state.message}"),
            ElevatedButton(
              onPressed: () {
                logger.i("📍 AddressListPage: Retry Fetch pressed");
                context.read<AddressBloc>().add(FetchAddressList());
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 180,
            width: 150,
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: 50,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '12/1',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  right: 25,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Icon(
                      Icons.key,
                      color: Colors.black87,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "KNOCK, KNOCK! WHO'S THERE?",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "You don't have any addresses saved. Saving address helps\nyou checkout faster.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 250,
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                logger.i(
                  "📍 AddressListPage: Add Address clicked (from empty state)",
                );
                context
                    .push(
                      AppRoutePath.mapLocation,
                      extra: {
                        'fetchCurrentLocation': true,
                        'fromHome': false,
                      },
                    )
                    .then((_) {
                      if (mounted) {
                        context.read<AddressBloc>().add(FetchAddressList());
                      }
                    });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepOrange,
                side: BorderSide(color: Colors.deepOrange.shade400, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'ADD AN ADDRESS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(List<AddressModel> savedAddresses) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
      itemCount: savedAddresses.length + 1,
      itemBuilder: (context, index) {
        if (index == savedAddresses.length) {
          return _buildAddNewAddressButton();
        }

        final address = savedAddresses[index];
        return _buildAddressItem(address)
            .animate()
            .fadeIn(delay: (40 * index).ms)
            .slideY(begin: 0.08, end: 0);
      },
    );
  }

  Widget _buildAddressItem(AddressModel address) {
    final currentLoc = locationService.locationNotifier.value;
    final bool isSelected =
        currentLoc != null &&
        currentLoc.lat == address.lat &&
        currentLoc.lng == address.lng;

    return GestureDetector(
      onTap: () async {
        logger.i("📍 AddressListPage: Address selected: ${address.label}");
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
        if (context.canPop()) {
          context.pop(address);
        } else {
          logger.w("📍 AddressListPage: Cannot pop, navigating to home");
          context.go(AppRoutePath.home);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isSelected ? const Color(0xFFFC8019) : Colors.grey.shade200,
            width: isSelected ? 1.5.w : 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              address.label.toLowerCase() == 'home'
                  ? Icons.home_outlined
                  : address.label.toLowerCase() == 'work' ||
                        address.label.toLowerCase() == 'office'
                  ? Icons.business_outlined
                  : Icons.location_on_outlined,
              color: isSelected ? const Color(0xFFFC8019) : Colors.black87,
              size: 26.w,
            ),
            SizedBox(width: 16.w),
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
                          fontSize: 16.sp,
                          color: isSelected
                              ? const Color(0xFFFC8019)
                              : Colors.black87,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC8019).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.w),
                            border: Border.all(
                              color: const Color(0xFFFC8019).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'SELECTED',
                            style: TextStyle(
                              color: const Color(0xFFFC8019),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    address.deliveryName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    address.addressLine,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  if (address.landmark != null &&
                      address.landmark!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Landmark: ${address.landmark}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    'Phone number: ${address.deliveryPhone}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          logger.i(
                            "📍 AddressListPage: Edit clicked for ${address.uuId}",
                          );
                          context
                              .push(
                                AppRoutePath.mapLocation,
                                extra: {
                                  'existingAddress': address,
                                  'fromHome': false,
                                  'fetchCurrentLocation': false,
                                },
                              )
                              .then((_) {
                                if (mounted) {
                                  context.read<AddressBloc>().add(
                                    FetchAddressList(),
                                  );
                                }
                              });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            'EDIT',
                            style: TextStyle(
                              color: const Color(0xFFFC8019),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 25.w),
                      InkWell(
                        onTap: () {
                          logger.i(
                            "📍 AddressListPage: Delete initiated for ${address.uuId}",
                          );
                          _showDeleteDialog(address);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            'DELETE',
                            style: TextStyle(
                              color: const Color(0xFFFC8019),
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(AddressModel address) {
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
              onPressed: () {
                logger.d("📍 AddressListPage: Delete cancelled");
                Navigator.of(dialogContext).pop();
              },
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
                logger.i(
                  "📍 AddressListPage: Delete confirmed for ${address.uuId}",
                );
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

  Widget _buildAddNewAddressButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: SizedBox(
        width: double.infinity,
        height: 48.h,
        child: OutlinedButton(
          onPressed: () {
            logger.i("📍 AddressListPage: Add New Address button clicked");
            context
                .push(
                  AppRoutePath.mapLocation,
                  extra: {
                    'fetchCurrentLocation': true,
                    'fromHome': false,
                  },
                )
                .then((_) {
                  if (mounted) {
                    context.read<AddressBloc>().add(FetchAddressList());
                  }
                });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFC8019),
            side: const BorderSide(color: Color(0xFFFC8019), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.w),
            ),
          ),
          child: Text(
            'ADD NEW ADDRESS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressShimmer() {
    return ListView.builder(
      itemCount: 10,
      padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w),
            border: Border.all(color: Colors.grey.shade200, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerPlaceholder.circular(width: 26.w, height: 26.w),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder.rounded(height: 16.h, width: 80.w, borderRadius: 4.w),
                    SizedBox(height: 8.h),
                    ShimmerPlaceholder.rounded(height: 14.h, width: 120.w, borderRadius: 4.w),
                    SizedBox(height: 8.h),
                    ShimmerPlaceholder.rounded(height: 13.h, width: double.infinity, borderRadius: 4.w),
                    SizedBox(height: 6.h),
                    ShimmerPlaceholder.rounded(height: 13.h, width: 150.w, borderRadius: 4.w),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        ShimmerPlaceholder.rounded(height: 14.h, width: 40.w, borderRadius: 4.w),
                        SizedBox(width: 25.w),
                        ShimmerPlaceholder.rounded(height: 14.h, width: 50.w, borderRadius: 4.w),
                      ],
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

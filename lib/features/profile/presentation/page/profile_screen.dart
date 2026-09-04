import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/profile/bloc/profile_blocs/profile_bloc.dart';
import 'package:my_vegiz_flutter/features/wallet/bloc/wallet_bloc.dart';
import 'package:my_vegiz_flutter/features/wallet/bloc/wallet_event.dart';
import 'package:my_vegiz_flutter/features/wallet/bloc/wallet_state.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../widgets/custom_bottom_nav_bar.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/profile_image_notifier.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../bloc/profile_blocs/profile_event.dart';
import '../../bloc/profile_blocs/profile_state.dart';
import '../../domain/usecase/profile_usecases.dart';
import '../../../orders/data/repository/grocery_order_repo.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/data/repository/food_order_repo.dart';
import '../../../orders/data/models/food_order_model.dart';
import '../../../mainCetegories/bloc/mainCategories_bloc.dart';
import '../../../mainCetegories/bloc/mainCategories_event.dart';
import '../../../mainCetegories/bloc/mainCategories_state.dart';
import './edit_profile.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/shimmer_placeholder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "";
  String _email = "";
  String _contact = "";
  bool _isUserLoading = true;
  late final WalletBloc _walletBloc;
  late final MainCategoriesBloc _mainCategoriesBloc;

  @override
  void initState() {
    super.initState();
    _walletBloc = getIt<WalletBloc>()..add(FetchWalletSummary());
    _mainCategoriesBloc = getIt<MainCategoriesBloc>()..add(FetchMainCategories());
    logger.i("👤 ProfileScreen: Initializing");
    _loadUserData();
  }

  @override
  void dispose() {
    _mainCategoriesBloc.close();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name = await SecureStorage.getCustomerName();
    final email = await SecureStorage.getCustomerEmail();
    final contact = await SecureStorage.getCustomerContact();
    final image = await SecureStorage.getCustomerProfileImage();

    if (image != null && image.isNotEmpty) {
      profileImageNotifier.value = image;
    }

    _fetchUserProfile();

    if (mounted) {
      setState(() {
        _name = name ?? "User";
        _email = email ?? "";
        _contact = contact ?? "";
        _isUserLoading = false;
      });
      logger.d("👤 ProfileScreen: User data loaded for $_name, image=$image");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final res = await getIt<GetProfileUseCase>()();
      res.fold((_) {}, (response) async {
        final profile = response.data;
        if (profile != null) {
          if (profile.name.isNotEmpty) await SecureStorage.saveCustomerName(profile.name);
          if (profile.email.isNotEmpty) await SecureStorage.saveCustomerEmail(profile.email);
          if (profile.contact.isNotEmpty) await SecureStorage.saveCustomerContact(profile.contact);
          if (profile.profileImage != null && profile.profileImage!.isNotEmpty) {
            profileImageNotifier.value = profile.profileImage;
            await SecureStorage.saveCustomerProfileImage(profile.profileImage!);
          }
          if (mounted) {
            setState(() {
              _name = profile.name.isNotEmpty ? profile.name : _name;
              _email = profile.email.isNotEmpty ? profile.email : _email;
              _contact = profile.contact.isNotEmpty ? profile.contact : _contact;
            });
          }
        }
      });
    } catch (e) {
      logger.d('Profile fetch error in ProfileScreen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileDeleteSuccess) {
            logger.i('👤 ProfileScreen: Account deleted — navigating to login');
            context.go(AppRoutePath.login);
          } else if (state is ProfileError) {
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
        },
        child: Builder(
          builder: (innerContext) {
            return Scaffold(
              backgroundColor: const Color(0xFFF7F8FA),
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text(
                  'My Account',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                centerTitle: true,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  onPressed: () {
                    context.go(AppRoutePath.home);
                  },
                ),
              ),

              body: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  context.go(AppRoutePath.home);
                },
                child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= USER HEADER =================
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                           ValueListenableBuilder<String?>(
                             valueListenable: profileImageNotifier,
                             builder: (context, imagePath, _) {
                               final hasImage =
                                   imagePath != null && imagePath.isNotEmpty;
                               return Container(
                                 width: 64.w,
                                 height: 64.w,
                                 decoration: BoxDecoration(
                                   color: hasImage
                                       ? Colors.grey[200]
                                       : const Color(0xFFFC8019),
                                   shape: BoxShape.circle,
                                 ),
                                 child: hasImage
                                     ? ClipOval(
                                         child: imagePath.startsWith('http')
                                             ? Image.network(
                                                 imagePath,
                                                 width: 64.w,
                                                 height: 64.w,
                                                 fit: BoxFit.cover,
                                                 errorBuilder: (_, __, ___) =>
                                                     const Icon(
                                                       Icons.person,
                                                       size: 36,
                                                       color: Colors.white,
                                                     ),
                                               )
                                             : Image.file(
                                                 File(imagePath),
                                                 width: 64.w,
                                                 height: 64.w,
                                                 fit: BoxFit.cover,
                                                 errorBuilder: (_, __, ___) =>
                                                     const Icon(
                                                       Icons.person,
                                                       size: 36,
                                                       color: Colors.white,
                                                     ),
                                               ),
                                       )
                                     : const Center(
                                         child: Icon(
                                           Icons.person,
                                           color: Colors.white,
                                           size: 36,
                                         ),
                                       ),
                               );
                             },
                           ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _isUserLoading
                                    ? ShimmerPlaceholder.rounded(
                                        height: 18.h,
                                        width: 120.w,
                                        borderRadius: 4.w,
                                        baseColor: Colors.white.withValues(alpha: 0.3),
                                        highlightColor: Colors.white.withValues(alpha: 0.15),
                                      )
                                    : Text(
                                        _name,
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                SizedBox(height: 6.h),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 14.w, color: Colors.grey),
                                    SizedBox(width: 6.w),
                                    _isUserLoading
                                        ? ShimmerPlaceholder.rounded(
                                            height: 13.h,
                                            width: 100.w,
                                            borderRadius: 4.w,
                                            baseColor: Colors.white.withValues(alpha: 0.3),
                                            highlightColor: Colors.white.withValues(alpha: 0.15),
                                          )
                                        : Text(
                                            _contact,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                  ],
                                ),
                                if (_isUserLoading) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(Icons.mail_outline_rounded, size: 14.w, color: Colors.grey),
                                      SizedBox(width: 6.w),
                                      ShimmerPlaceholder.rounded(
                                        height: 13.h,
                                        width: 140.w,
                                        borderRadius: 4.w,
                                        baseColor: Colors.white.withValues(alpha: 0.3),
                                        highlightColor: Colors.white.withValues(alpha: 0.15),
                                      ),
                                    ],
                                  ),
                                ] else if (_email.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(Icons.mail_outline_rounded, size: 14.w, color: Colors.grey),
                                      SizedBox(width: 6.w),
                                      Expanded(
                                        child: Text(
                                          _email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13.sp,
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              logger.i("👤 ProfileScreen: Edit Profile clicked");
                              final updated = await showEditProfile(
                                innerContext,
                                name: _name,
                                email: _email,
                                contact: _contact,
                                imagePath: profileImageNotifier.value,
                              );
                              if (updated == true) {
                                await _loadUserData();
                              }
                            },
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFFFC8019),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ================= WALLET CARD =================
                    // GestureDetector(
                    //   onTap: () {
                    //     logger.i("👤 ProfileScreen: Wallet Card clicked");
                    //     context.push(AppRoutePath.wallet);
                    //   },
                    //   child: Container(
                    //     margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    //     padding: EdgeInsets.all(20.w),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(20),
                    //       gradient: const LinearGradient(
                    //         colors: [Color(0xFFFC8019), Color(0xFFFFAB40)],
                    //         begin: Alignment.topLeft,
                    //         end: Alignment.bottomRight,
                    //       ),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: const Color(0xFFFC8019).withValues(alpha: 0.3),
                    //           blurRadius: 10,
                    //           offset: const Offset(0, 4),
                    //         ),
                    //       ],
                    //     ),
                    //     child: Row(
                    //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //       children: [
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             Text(
                    //               "Wallet Balance",
                    //               style: TextStyle(
                    //                 color: Colors.white.withValues(alpha: 0.9),
                    //                 fontSize: 13.sp,
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),
                    //             SizedBox(height: 6.h),
                    //             BlocBuilder<WalletBloc, WalletState>(
                    //               bloc: _walletBloc,
                    //               builder: (context, state) {
                    //                 final isLoading = state is WalletInitial ||
                    //                     (state is WalletDataState &&
                    //                         state.isSummaryLoading &&
                    //                         state.summary == null);
                    //
                    //                 if (isLoading) {
                    //                   return ShimmerPlaceholder.rounded(
                    //                     height: 32.h,
                    //                     width: 100.w,
                    //                     borderRadius: 6.w,
                    //                     baseColor: Colors.white.withValues(alpha: 0.3),
                    //                     highlightColor: Colors.white.withValues(alpha: 0.15),
                    //                   );
                    //                 }
                    //
                    //                 if (state is WalletDataState) {
                    //                   final rupees =
                    //                       state.summary?.walletBalanceRupees ??
                    //                       0.0;
                    //                   return Text(
                    //                     "₹ ${rupees.toInt()}",
                    //                     style: TextStyle(
                    //                       color: Colors.white,
                    //                       fontSize: 28.sp,
                    //                       fontWeight: FontWeight.w800,
                    //                     ),
                    //                   );
                    //                 }
                    //
                    //                 return Text(
                    //                   "₹ 0",
                    //                   style: TextStyle(
                    //                     color: Colors.white,
                    //                     fontSize: 28.sp,
                    //                     fontWeight: FontWeight.w800,
                    //                   ),
                    //                 );
                    //               },
                    //             ),
                    //             SizedBox(height: 12.h),
                    //             Container(
                    //               padding: const EdgeInsets.symmetric(
                    //                 horizontal: 14,
                    //                 vertical: 8,
                    //               ),
                    //               decoration: BoxDecoration(
                    //                 color: Colors.white,
                    //                 borderRadius: BorderRadius.circular(10),
                    //               ),
                    //               child: Row(
                    //                 mainAxisSize: MainAxisSize.min,
                    //                 children: [
                    //                   Text(
                    //                     "View History",
                    //                     style: TextStyle(
                    //                       color: Colors.black87,
                    //                       fontSize: 12.sp,
                    //                       fontWeight: FontWeight.bold,
                    //                     ),
                    //                   ),
                    //                   const SizedBox(width: 4),
                    //                   const Icon(
                    //                     Icons.chevron_right_rounded,
                    //                     color: Colors.black87,
                    //                     size: 14,
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //         Container(
                    //           width: 70.w,
                    //           height: 70.w,
                    //           decoration: BoxDecoration(
                    //             color: Colors.white.withValues(alpha: 0.18),
                    //             shape: BoxShape.circle,
                    //           ),
                    //           child: const Icon(
                    //             Icons.account_balance_wallet_outlined,
                    //             color: Colors.white,
                    //             size: 36,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 10.h),

                    // ================= QUICK ACTIONS =================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: BlocBuilder<MainCategoriesBloc, MainCategoriesState>(
                        bloc: _mainCategoriesBloc,
                        builder: (context, state) {
                          bool showWishlist = true;
                          if (state is MainCategoriesLoaded) {
                            final activeCategories = (state.data.data ?? [])
                                .where((c) => c.isActive)
                                .toList();
                            final hasOnlyFood = activeCategories.isNotEmpty &&
                                activeCategories.every((c) => c.slug.trim().toLowerCase() == 'food');
                            showWishlist = !hasOnlyFood;
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildQuickAction(
                                Icons.shopping_bag_outlined,
                                "Orders",
                                Colors.purple,
                                Colors.purple.withValues(alpha: 0.08),
                                () {
                                  logger.i("👤 ProfileScreen: Orders clicked");
                                  context.push(AppRoutePath.ordersList);
                                },
                              ),
                              if (showWishlist) ...[
                                SizedBox(width: 16.w),
                                _buildQuickAction(
                                  Icons.favorite_border,
                                  "Wishlist",
                                  Colors.red,
                                  Colors.red.withValues(alpha: 0.08),
                                  () {
                                    logger.i("👤 ProfileScreen: Wishlist clicked");
                                    context.push(AppRoutePath.wishlist);
                                  },
                                ),
                              ],
                              SizedBox(width: 16.w),
                              _buildQuickAction(
                                Icons.location_on_outlined,
                                "Address",
                                Colors.blue,
                                Colors.blue.withValues(alpha: 0.08),
                                () {
                                  logger.i("👤 ProfileScreen: Navigating to Address List");
                                  context.push(AppRoutePath.address);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // ================= SUPPORT =================
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'Support',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.w),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // _buildSettingsTile(
                          //   icon: Icons.headset_mic_outlined,
                          //   title: 'Help Center',
                          //   subtitle: 'FAQs and support',
                          //   iconColor: Colors.purple,
                          //   bgColor: Colors.purple.withValues(alpha: 0.08),
                          //   onTap: () =>
                          //       logger.i("👤 ProfileScreen: Help Center clicked"),
                          // ),
                          // _divider(),
                          _buildSettingsTile(
                            icon: Icons.shield_outlined,
                            title: 'Privacy & Security',
                            subtitle: 'Manage your data',
                            iconColor: Colors.blue,
                            bgColor: Colors.blue.withValues(alpha: 0.08),
                            onTap: () {
                              logger.i("👤 ProfileScreen: Privacy & Security clicked");
                              context.push(AppRoutePath.privacyAndSecurity);
                            },
                          ),
                          _divider(),
                          _buildSettingsTile(
                            icon: Icons.description_outlined,
                            title: 'Refund Policy',
                            subtitle: 'Refund',
                            iconColor: Colors.green,
                            bgColor: Colors.green.withValues(alpha: 0.08),
                            onTap: () {
                              logger.i("👤 ProfileScreen: Refund Policy clicked");
                              context.push(AppRoutePath.refundPolicy);
                            },
                          ),
                          _divider(),
                          _buildSettingsTile(
                            icon: Icons.gavel_outlined,
                            title: 'Terms & Conditions',
                            subtitle: 'Terms of service',
                            iconColor: Colors.teal,
                            bgColor: Colors.teal.withValues(alpha: 0.08),
                            onTap: () {
                              logger.i("👤 ProfileScreen: Terms & Conditions clicked");
                              context.push(AppRoutePath.termsAndConditions);
                            },
                          ),
                          _divider(),
                          _buildSettingsTile(
                            icon: Icons.star_outline_rounded,
                            title: 'Rate Us',
                            subtitle: 'Share your feedback',
                            iconColor: Colors.amber,
                            bgColor: Colors.amber.withValues(alpha: 0.08),
                            onTap: () async {
                              logger.i("👤 ProfileScreen: Rate Us clicked");

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) =>
                                    const Center(child: CircularProgressIndicator()),
                              );

                              final groceryRepo = getIt<GroceryOrderRepository>();
                              final foodRepo = getIt<FoodOrderRepository>();

                              final results = await Future.wait([
                                groceryRepo.getOrdersList(),
                                foodRepo.getFoodOrdersList(),
                              ]);

                              final groceryRes = results[0];
                              final foodRes = results[1];

                              final List<_ProfileCandidateOrder> candidates = [];

                              groceryRes.fold(
                                (l) => logger.e(
                                  "ProfileScreen: Failed to fetch grocery orders: ${l.message}",
                                ),
                                (r) {
                                  final groceryListResponse = r as OrderListResponse;
                                  for (var order in groceryListResponse.orders) {
                                    if (order.orderStatus.toUpperCase() ==
                                        'DELIVERED') {
                                      candidates.add(
                                        _ProfileCandidateOrder(
                                          uuId: order.uuId,
                                          createdAt:
                                              DateTime.tryParse(order.createdAt) ??
                                              DateTime(1970),
                                          isFood: false,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );

                              foodRes.fold(
                                (l) => logger.e(
                                  "ProfileScreen: Failed to fetch food orders: ${l.message}",
                                ),
                                (r) {
                                  final foodListResponse = r as FoodOrderListResponse;
                                  for (var order in foodListResponse.orders) {
                                    if (order.orderStatus.toUpperCase() ==
                                        'DELIVERED') {
                                      candidates.add(
                                        _ProfileCandidateOrder(
                                          uuId: order.uuId,
                                          createdAt:
                                              DateTime.tryParse(order.createdAt) ??
                                              DateTime(1970),
                                          isFood: true,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );

                              // Sort latest delivered orders first
                              candidates.sort(
                                (a, b) => b.createdAt.compareTo(a.createdAt),
                              );

                              _ProfileCandidateOrder? unratedCandidate;

                              for (var candidate in candidates) {
                                bool isOrderRated = false;
                                if (candidate.isFood) {
                                  final ratingRes = await foodRepo
                                      .fetchFoodOrderRatings(candidate.uuId);
                                  ratingRes.fold(
                                    (l) => logger.e(
                                      "Failed to check rating for food order ${candidate.uuId}: ${l.message}",
                                    ),
                                    (ratingsResponse) {
                                      if ((ratingsResponse.deliveryRating != null &&
                                              ratingsResponse.deliveryRating!.rating >
                                                  0) ||
                                          (ratingsResponse.vendorRating != null &&
                                              ratingsResponse.vendorRating!.rating >
                                                  0) ||
                                          ratingsResponse.productRatings.any(
                                            (p) => p.rating > 0,
                                          )) {
                                        isOrderRated = true;
                                      }
                                    },
                                  );
                                } else {
                                  final ratingRes = await groceryRepo
                                      .fetchOrderRatings(candidate.uuId);
                                  ratingRes.fold(
                                    (l) => logger.e(
                                      "Failed to check rating for grocery order ${candidate.uuId}: ${l.message}",
                                    ),
                                    (ratingsResponse) {
                                      if ((ratingsResponse.deliveryRating != null &&
                                              ratingsResponse.deliveryRating!.rating >
                                                  0) ||
                                          ratingsResponse.productRatings.any(
                                            (p) => p.rating > 0,
                                          )) {
                                        isOrderRated = true;
                                      }
                                    },
                                  );
                                }

                                if (!isOrderRated) {
                                  unratedCandidate = candidate;
                                  break;
                                }
                              }

                              if (context.mounted) {
                                Navigator.pop(context); // hide loading
                              }

                              if (context.mounted) {
                                context.push(
                                  AppRoutePath.ratingScreen,
                                  extra: {
                                    'orderId': unratedCandidate?.uuId ?? '',
                                    'isFood': unratedCandidate?.isFood ?? true,
                                  },
                                );
                              }
                            },
                          ),
                          _divider(),
                          _buildSettingsTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            subtitle: 'Sign out from this device',
                            iconColor: Colors.red,
                            bgColor: Colors.red.withValues(alpha: 0.08),
                            onTap: () {
                              _showLogoutDialog(innerContext);
                            },
                          ),
                          _divider(),
                          _buildSettingsTile(
                            icon: Icons.delete_outline,
                            title: 'Delete Account',
                            subtitle: 'Permanently remove account',
                            iconColor: Colors.red,
                            bgColor: Colors.red.withValues(alpha: 0.08),
                            onTap: () {
                              logger.w("👤 ProfileScreen: Delete Account clicked");
                              _showDeleteAccountDialog(innerContext);
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),

              bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76.w,
        height: 84.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40.w,
              width: 40.w,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20.w),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20.w, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔴 Icon Circle
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 30),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  "Confirm Logout",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.h),

                // Subtitle
                const Text(
                  "Are you sure you want to logout?\nYou will need to login again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Logout
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog

                          logger.i("👤 Logout confirmed");

                          await SecureStorage.clearAll();

                          if (context.mounted) {
                            context.go(AppRoutePath.login);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
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
        );
      },
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 20,
      color: Colors.grey[200],
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                SizedBox(height: 20.h),
                const Text(
                  "Delete Account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10.h),
                const Text(
                  "This will permanently remove your\naccount and all your data.\nThis action cannot be undone.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          logger.i(
                            "\ud83d\udc64 Delete Account confirmed — dispatching event",
                          );
                          // Dispatch via the ProfileBloc provided above this dialog
                          context.read<ProfileBloc>().add(DeleteAccountEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileCandidateOrder {
  final String uuId;
  final DateTime createdAt;
  final bool isFood;

  _ProfileCandidateOrder({
    required this.uuId,
    required this.createdAt,
    required this.isFood,
  });
}

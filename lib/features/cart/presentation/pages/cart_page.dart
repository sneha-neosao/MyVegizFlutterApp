import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/core/storage/secure_storage.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import '../../../../widgets/custom_bottom_nav_bar.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../data/models/cart_model.dart' as model;
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import './coupon_page.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_bloc.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_event.dart';
import 'package:my_vegiz_flutter/features/address/bloc/address_state.dart';
import 'package:my_vegiz_flutter/features/checkout/bloc/checkout_bloc.dart';
import 'package:my_vegiz_flutter/features/checkout/bloc/checkout_event.dart';
import 'package:my_vegiz_flutter/features/checkout/bloc/checkout_state.dart';
import 'package:my_vegiz_flutter/features/address/data/models/address_model.dart';
import 'package:my_vegiz_flutter/features/checkout/data/models/checkout_model.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';
import 'package:my_vegiz_flutter/features/cart/data/cart_data.dart';
import 'package:my_vegiz_flutter/features/wallet/bloc/wallet_bloc.dart';
import 'package:my_vegiz_flutter/features/wallet/bloc/wallet_event.dart';
import 'package:my_vegiz_flutter/features/wallet/bloc/wallet_state.dart';
import 'package:my_vegiz_flutter/features/orders/bloc/food_order_bloc.dart';
import 'package:my_vegiz_flutter/features/orders/bloc/food_order_event.dart';
import 'package:my_vegiz_flutter/features/orders/bloc/food_order_state.dart';
import 'package:my_vegiz_flutter/core/storage/food_cart_db.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CartPage extends StatefulWidget {
  final bool isFood;
  const CartPage({super.key, this.isFood = false});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final GlobalKey _billDetailsKey = GlobalKey();
  model.CartData? _lastKnownCartData;
  int? _updatingCartItemId;

  String? selectedPaymentMethod;
  String? selectedSlotUuid;
  String? selectedSlotLabel;
  AddressModel? selectedAddress;
  OrderSettingsModel? _orderSettings;
  List<SlotModel>? _cachedSlots;
  bool _isOrderPlaced = false;

  late CheckoutBloc _checkoutBloc;
  late WalletBloc _walletBloc;
  FoodOrderBloc? _foodOrderBloc;
  final TextEditingController _customerNoteController = TextEditingController();

  bool _isInitialFetchInProgress = true;
  bool _hasStartedLoading = false;

  @override
  void initState() {
    super.initState();
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded) {
      _lastKnownCartData = cartState.cartData;
    } else if (cartState is CartActionSuccess && cartState.cartData != null) {
      _lastKnownCartData = cartState.cartData;
    } else if (cartState is CartLoading && cartState.cartData != null) {
      _lastKnownCartData = cartState.cartData;
    } else if (cartState is CartError && cartState.cartData != null) {
      _lastKnownCartData = cartState.cartData;
    }

    final loc = locationService.locationNotifier.value;
    selectedPaymentMethod = 'COD (Cash on Delivery)';
    context.read<CartBloc>().add(
      GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
    );
    _checkoutBloc = getIt<CheckoutBloc>()..add(LoadCheckoutDataEvent());
    _walletBloc = getIt<WalletBloc>()..add(FetchWalletSummary());
    if (widget.isFood) {
      _foodOrderBloc = context.read<FoodOrderBloc>();
    }
    context.read<AddressBloc>().add(FetchAddressList());
    logger.i('🛒 CartPage: Opened — fetching cart, checkout, and address data');
  }

  @override
  void dispose() {
    _checkoutBloc.close();
    _customerNoteController.dispose();
    super.dispose();
  }

  bool _isAutoAssign(OrderSettingsModel? settings) {
    if (settings?.autoAssignMode == null) return false;
    final mode = settings!.autoAssignMode!.trim().toLowerCase();
    return mode.contains('auto');
  }

  // ── Combined Offers & Wallet Card ────────────────────────────────────────

  Widget _buildOffersAndWalletCard(BuildContext context, model.CartData cartData) {
    final bool isCouponApplied =
        (cartData.couponCode != null && cartData.couponCode!.isNotEmpty) ||
        (cartData.discountAmount != null && cartData.discountAmount! > 0);
    final String displayCouponCode = (cartData.couponCode != null && cartData.couponCode!.isNotEmpty)
        ? cartData.couponCode!
        : "Coupon";

    final bool cartSaysWalletApplied =
        (cartData.walletPointsUsed != null && cartData.walletPointsUsed! > 0) ||
        (cartData.walletDiscountAmount != null && cartData.walletDiscountAmount! > 0);

    return BlocBuilder<WalletBloc, WalletState>(
      bloc: _walletBloc,
      builder: (context, walletState) {
        final walletData = walletState is WalletDataState ? walletState : const WalletDataState();
        final int availablePoints = walletData.summary?.walletBalancePoints ?? 0;

        final bool isWalletApplied;
        if (walletData.applyStatus == WalletApplyStatus.failed) {
          isWalletApplied = false;
        } else if (walletData.applyStatus == WalletApplyStatus.applied) {
          isWalletApplied = true;
        } else {
          isWalletApplied = cartSaysWalletApplied;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // 1. Coupon Row
              Material(
                color: isCouponApplied ? const Color(0xFFF0FDF4) : Colors.transparent,
                child: InkWell(
                  onTap: isCouponApplied
                      ? null
                      : () {
                          logger.i('🎟️ CartPage: User tapped "Apply Coupon"');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<CartBloc>(),
                                child: const CouponPage(),
                              ),
                            ),
                          );
                        },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(7.w),
                              decoration: BoxDecoration(
                                color: isCouponApplied ? const Color(0xFFDCFCE7) : const Color(0xFFEAF7EE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCouponApplied ? Icons.check_circle_rounded : Icons.local_offer_outlined,
                                color: const Color(0xFF2E7D32),
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCouponApplied ? "'$displayCouponCode' applied" : 'Apply Coupon',
                                  style: TextStyle(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isCouponApplied ? const Color(0xFF166534) : const Color(0xFF1E242B),
                                  ),
                                ),
                                if (isCouponApplied && (cartData.discountAmount ?? 0) > 0) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    "₹${cartData.discountAmount?.toStringAsFixed(2)} savings active",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ] else if (!isCouponApplied) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    "Save more with coupons & offers",
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        if (isCouponApplied)
                          TextButton(
                            onPressed: () {
                              logger.w('🗑️ CartPage: User tapped "Remove Coupon"');
                              context.read<CartBloc>().add(RemoveCouponEvent());
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade600,
                              ),
                            ),
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11.sp,
                                color: const Color(0xFF2E7D32),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Divider(color: Colors.grey.shade100, height: 1, thickness: 1),

              // // 2. Wallet Row — commented out (Use Wallet Points UI hidden)
              // Material(
              //   color: isWalletApplied ? const Color(0xFFF0FDF4) : Colors.transparent,
              //   child: InkWell(
              //     onTap: (isWalletApplied || availablePoints <= 0)
              //         ? null
              //         : () => _showApplyWalletDialog(context, availablePoints),
              //     child: Padding(
              //       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Row(
              //             children: [
              //               Container(
              //                 padding: EdgeInsets.all(7.w),
              //                 decoration: BoxDecoration(
              //                   color: isWalletApplied ? const Color(0xFFDCFCE7) : const Color(0xFFEAF7EE),
              //                   shape: BoxShape.circle,
              //                 ),
              //                 child: Icon(
              //                   isWalletApplied ? Icons.account_balance_wallet_rounded : Icons.account_balance_wallet_outlined,
              //                   color: const Color(0xFF2E7D32),
              //                   size: 18.sp,
              //                 ),
              //               ),
              //               SizedBox(width: 12.w),
              //               Column(
              //                 crossAxisAlignment: CrossAxisAlignment.start,
              //                 children: [
              //                   Text(
              //                     isWalletApplied ? "Wallet Points Applied" : 'Use Wallet Points',
              //                     style: TextStyle(
              //                       fontSize: 14.5.sp,
              //                       fontWeight: FontWeight.w700,
              //                       color: isWalletApplied ? const Color(0xFF166534) : const Color(0xFF1E242B),
              //                     ),
              //                   ),
              //                   SizedBox(height: 2.h),
              //                   if (isWalletApplied && (cartData.walletDiscountAmount ?? 0) > 0)
              //                     Text(
              //                       "₹${cartData.walletDiscountAmount?.toStringAsFixed(2)} discount active",
              //                       style: TextStyle(
              //                         fontSize: 12.sp,
              //                         fontWeight: FontWeight.w600,
              //                         color: const Color(0xFF2E7D32),
              //                       ),
              //                     )
              //                   else
              //                     Text(
              //                       'Available: $availablePoints pts',
              //                       style: TextStyle(
              //                         fontSize: 11.5.sp,
              //                         fontWeight: FontWeight.w500,
              //                         color: const Color(0xFF64748B),
              //                       ),
              //                     ),
              //                 ],
              //               ),
              //             ],
              //           ),
              //           if (isWalletApplied)
              //             TextButton(
              //               onPressed: walletData.isActionLoading
              //                   ? null
              //                   : () async {
              //                       logger.w('🗑️ CartPage: User tapped "Remove Wallet"');
              //                       if (widget.isFood) {
              //                         await SecureStorage.saveAppliedWalletPoints(0);
              //                         final loc = locationService.locationNotifier.value;
              //                         if (context.mounted) {
              //                           context.read<CartBloc>().add(
              //                             GetCartListEvent(
              //                               lat: loc?.lat ?? 0.0,
              //                               lng: loc?.lng ?? 0.0,
              //                             ),
              //                           );
              //                         }
              //                       } else {
              //                         _walletBloc.add(RemoveWalletPoints());
              //                       }
              //                     },
              //               style: TextButton.styleFrom(
              //                 padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              //                 minimumSize: Size.zero,
              //                 tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //               ),
              //               child: walletData.isActionLoading
              //                   ? SizedBox(
              //                       height: 12.sp,
              //                       width: 12.sp,
              //                       child: CircularProgressIndicator(
              //                         strokeWidth: 1.8,
              //                         color: Colors.red.shade600,
              //                       ),
              //                     )
              //                   : Text(
              //                       'Remove',
              //                       style: TextStyle(
              //                         fontSize: 13.5.sp,
              //                         fontWeight: FontWeight.w700,
              //                         color: Colors.red.shade600,
              //                       ),
              //                     ),
              //             )
              //           else
              //             Container(
              //               padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              //               decoration: BoxDecoration(
              //                 color: availablePoints > 0 ? const Color(0xFFEAF7EE) : Colors.grey.shade100,
              //                 borderRadius: BorderRadius.circular(20.w),
              //                 border: Border.all(
              //                   color: availablePoints > 0 ? const Color(0xFFC8E6C9) : Colors.grey.shade300,
              //                   width: 0.8,
              //                 ),
              //               ),
              //               child: walletData.isActionLoading
              //                   ? SizedBox(
              //                       height: 12.sp,
              //                       width: 12.sp,
              //                       child: const CircularProgressIndicator(
              //                         strokeWidth: 1.8,
              //                         color: Color(0xFF2E7D32),
              //                       ),
              //                     )
              //                   : Text(
              //                       'Apply',
              //                       style: TextStyle(
              //                         fontSize: 12.5.sp,
              //                         fontWeight: FontWeight.w800,
              //                         color: availablePoints > 0 ? const Color(0xFF2E7D32) : Colors.grey.shade400,
              //                       ),
              //                     ),
              //             ),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillDetailsItemRow({
    required IconData icon,
    required String title,
    required String value,
    String? oldPrice,
    String? savedBadge,
    bool isFree = false,
    Color? valueColor,
    bool hasDottedUnderline = false,
    bool isLoading = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 15.sp, color: const Color(0xFF475569)),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF334155),
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w500,
                  decoration: hasDottedUnderline ? TextDecoration.underline : TextDecoration.none,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: Colors.grey.shade400,
                ),
              ),
              if (savedBadge != null && savedBadge.isNotEmpty) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE), // faint green theming
                    borderRadius: BorderRadius.circular(4.w),
                  ),
                  child: Text(
                    savedBadge,
                    style: TextStyle(
                      color: const Color(0xFF2E7D32),
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (oldPrice != null && oldPrice.isNotEmpty) ...[
              isLoading
                  ? ShimmerPlaceholder.rounded(height: 13, width: 35)
                  : Text(
                      oldPrice,
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12.5.sp,
                        decoration: TextDecoration.lineThrough,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              SizedBox(width: 5.w),
            ],
            isLoading
                ? ShimmerPlaceholder.rounded(height: 13, width: 50)
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isFree
                          ? const Color(0xFF2E7D32)
                          : (valueColor ?? const Color(0xFF1E242B)),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  // ── Bill Details Card ─────────────────────────────────────────────────────

  Widget _buildBillDetailsCard(
    model.CartData cartData, {
    bool isLoading = false,
  }) {
    // 1. Selling price total
    final double sellingTotal =
        cartData.productsTotal ?? cartData.totalAmount ?? 0.0;

    // 2. MRP total
    double mrpTotal = 0.0;
    for (final it in (cartData.items ?? <model.CartItem>[])) {
      final itemActual = it.actualPrice > 0 ? it.actualPrice : it.sellingPrice;
      mrpTotal += itemActual * it.quantity;
    }
    if (mrpTotal <= sellingTotal && cartData.mrpTotal != null && cartData.mrpTotal! > sellingTotal) {
      mrpTotal = cartData.mrpTotal!;
    }

    // 3. Item Savings
    final double itemSavings = (mrpTotal > sellingTotal)
        ? (mrpTotal - sellingTotal)
        : (cartData.productDiscount ?? 0.0);

    // 4. Discounts
    final double couponDiscount = cartData.discountAmount ?? 0.0;
    final String couponCode = (cartData.couponCode != null && cartData.couponCode!.isNotEmpty)
        ? cartData.couponCode!
        : "Applied";
    final double walletDiscount = cartData.walletDiscountAmount ?? 0.0;

    // 5. Taxes & Other Charges
    final double tax = cartData.taxAmount ?? 0.0;
    final double packing = cartData.packingCharge ?? 0.0;

    // 6. Delivery Fee
    final double deliveryFee = cartData.deliveryInfo?.deliveryCharge ?? 0.0;
    final bool isFreeDelivery = (cartData.deliveryInfo?.isFree ?? false) || deliveryFee == 0;
    final double freeDeliverySavings = isFreeDelivery ? 30.0 : 0.0;

    // 7. Final Grand Total
    final double toPay = cartData.grandTotal ?? 0.0;

    // 8. Total Savings across all heads
    final double totalSavings = itemSavings + couponDiscount + walletDiscount + freeDeliverySavings;

    return Container(
      key: _billDetailsKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E242B),
                  ),
                ),
                SizedBox(height: 14.h),

                // 1. Items total row
                _buildBillDetailsItemRow(
                  icon: Icons.article_outlined,
                  title: 'Items total',
                  savedBadge: itemSavings > 0 ? 'Saved ₹${itemSavings.toInt()}' : null,
                  oldPrice: mrpTotal > sellingTotal ? '₹${mrpTotal.toInt()}' : null,
                  value: '₹${sellingTotal.toInt()}',
                  isLoading: isLoading,
                ),
                SizedBox(height: 12.h),

                // 2. Delivery charge row
                _buildBillDetailsItemRow(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Delivery charge',
                  hasDottedUnderline: true,
                  oldPrice: isFreeDelivery ? '₹${freeDeliverySavings.toInt()}' : null,
                  value: isFreeDelivery ? 'FREE' : '₹${deliveryFee.toInt()}',
                  isFree: isFreeDelivery,
                  isLoading: isLoading,
                ),

                // 3. Handling charge / Packing charge row
                if (packing > 0) ...[
                  SizedBox(height: 12.h),
                  _buildBillDetailsItemRow(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Handling charge',
                    hasDottedUnderline: true,
                    value: '₹${packing.toInt()}',
                    isLoading: isLoading,
                  ),
                ],

                // 4. Coupon Discount
                if (couponDiscount > 0) ...[
                  SizedBox(height: 12.h),
                  _buildBillDetailsItemRow(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupon ($couponCode)',
                    value: '-₹${couponDiscount.toInt()}',
                    valueColor: const Color(0xFF2E7D32),
                    isLoading: isLoading,
                  ),
                ],

                // 5. Wallet Discount — commented out
                // if (walletDiscount > 0) ...[
                //   SizedBox(height: 12.h),
                //   _buildBillDetailsItemRow(
                //     icon: Icons.account_balance_wallet_outlined,
                //     title: 'Wallet discount',
                //     value: '-₹${walletDiscount.toInt()}',
                //     valueColor: const Color(0xFF2E7D32),
                //     isLoading: isLoading,
                //   ),
                // ],

                // 6. Taxes & Charges
                if (tax > 0) ...[
                  SizedBox(height: 12.h),
                  _buildBillDetailsItemRow(
                    icon: Icons.receipt_outlined,
                    title: 'Taxes & Charges',
                    value: '₹${tax.toInt()}',
                    isLoading: isLoading,
                  ),
                ],

                SizedBox(height: 14.h),
                Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
                SizedBox(height: 12.h),

                // Grand total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand total',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E242B),
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                        decorationColor: Colors.grey.shade400,
                      ),
                    ),
                    isLoading
                        ? ShimmerPlaceholder.rounded(height: 18, width: 80)
                        : Text(
                            '₹${toPay.toInt()}',
                            style: TextStyle(
                              fontSize: 17.5.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E242B),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Wavy Faint Green Savings Banner
          if (totalSavings > 0)
            ClipPath(
              clipper: _BillScallopTopClipper(),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFEAF7EE), // faint green theming
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your total savings',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          '₹${totalSavings.toInt()}',
                          style: TextStyle(
                            fontSize: 15.5.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      (isFreeDelivery && freeDeliverySavings > 0)
                          ? 'Includes ₹${freeDeliverySavings.toInt()} savings through free delivery'
                          : 'Includes item & promotional savings',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Note Card ─────────────────────────────────────────────────────────────

  Widget _buildNoteCard() {
    final String serviceRange =
        _orderSettings?.serviceTime?.formattedRange ?? '8:00 AM to 9:00 PM';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14.w),
        border: Border.all(color: const Color(0xFFFDE68A), width: 0.9),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_filled_rounded,
            color: const Color(0xFFD97706),
            size: 18.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: const Color(0xFF92400E),
                      fontSize: 12.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Serviceable Time: ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: serviceRange,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: const Color(0xFF92400E),
                      fontSize: 12.sp,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Delivery Time: ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text:
                            'Your order will be delivered to you within 1 to 2 hours approximately.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerNoteSection() {
    const quickTags = [
      'Avoid ringing bell',
      'Leave at door / gate',
      'Call before delivery',
      'Leave with guard',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EE),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: const Color(0xFF2E7D32),
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Delivery Instructions',
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E242B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Quick Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickTags.map((tag) {
                final bool isContained = _customerNoteController.text.contains(tag);
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.w),
                    onTap: () {
                      setState(() {
                        if (isContained) {
                          _customerNoteController.text = _customerNoteController.text
                              .replaceAll(tag, '')
                              .replaceAll(RegExp(r',\s*,'), ',')
                              .replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$'), '')
                              .trim();
                        } else {
                          final current = _customerNoteController.text.trim();
                          _customerNoteController.text =
                              current.isEmpty ? tag : '$current, $tag';
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isContained ? const Color(0xFFEAF7EE) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20.w),
                        border: Border.all(
                          color: isContained ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isContained) ...[
                            Icon(Icons.check_rounded, size: 13.sp, color: const Color(0xFF2E7D32)),
                            SizedBox(width: 4.w),
                          ],
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: isContained ? FontWeight.w700 : FontWeight.w500,
                              color: isContained ? const Color(0xFF2E7D32) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 10.h),

          // Text Field
          TextField(
            controller: _customerNoteController,
            maxLines: 2,
            maxLength: 150,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E242B),
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Please ring doorbell twice, leave at gate...',
              hintStyle: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 12.sp,
              ),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 0.9),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 0.9),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodDisplayName(String? method) {
    if (method == null || method.isEmpty) return 'Select';
    if (method.contains('COD') || method.contains('Cash')) return 'COD';
    if (method.toUpperCase().contains('UPI')) return 'UPI';
    if (method.toUpperCase().contains('CARD')) return 'Card';
    return method;
  }

  IconData _getPaymentMethodIcon(String? method) {
    if (method == null || method.isEmpty) return Icons.payment_rounded;
    if (method.contains('COD') || method.contains('Cash')) return Icons.payments_outlined;
    if (method == 'UPI') return Icons.account_balance_wallet_outlined;
    if (method == 'Card') return Icons.credit_card_outlined;
    return Icons.payment_rounded;
  }

  void _showPaymentMethodBottomSheet(BuildContext context, OrderSettingsModel? settings) {
    final bool isOnlineEnabled = settings != null
        ? (settings.isOnlineEnabled ||
            settings.availableModes.any((m) => m.toUpperCase() == 'ONLINE'))
        : true;
    final bool isCodEnabled = settings != null
        ? (settings.isCodEnabled ||
            settings.availableModes.any((m) => m.toUpperCase() == 'COD'))
        : true;

    final List<Map<String, dynamic>> options = [
      if (isCodEnabled)
        {
          'id': 'COD',
          'title': 'Cash on Delivery (COD)',
          'subtitle': 'Pay with cash at your doorstep',
          'icon': Icons.payments_outlined,
        },
      if (isOnlineEnabled) ...[
        {
          'id': 'UPI',
          'title': 'UPI',
          'subtitle': 'Google Pay, PhonePe, Paytm & more',
          'icon': Icons.account_balance_wallet_outlined,
        },
        {
          'id': 'Card',
          'title': 'Credit / Debit Card',
          'subtitle': 'Visa, Mastercard, RuPay & more',
          'icon': Icons.credit_card_outlined,
        },
      ],
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 38.w,
                        height: 4.h,
                        margin: EdgeInsets.only(bottom: 14.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.w),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Payment Method',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E242B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.black87, size: 18.w),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    ...options.map((opt) {
                      final String id = opt['id'] as String;
                      final String title = opt['title'] as String;
                      final String subtitle = opt['subtitle'] as String;
                      final IconData icon = opt['icon'] as IconData;
                      final bool isSelected = selectedPaymentMethod == id ||
                          (id == 'COD' && (selectedPaymentMethod?.contains('COD') ?? false)) ||
                          (id == 'UPI' && (selectedPaymentMethod?.toUpperCase().contains('UPI') ?? false)) ||
                          (id == 'Card' && (selectedPaymentMethod?.toUpperCase().contains('CARD') ?? false));

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.w),
                            onTap: () {
                              setState(() {
                                selectedPaymentMethod = id;
                              });
                              setModalState(() {});
                              Navigator.pop(ctx);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 20.sp,
                                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF475569),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? const Color(0xFF166534) : const Color(0xFF1E242B),
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          subtitle,
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                                    color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                                    size: 22.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isServiceableTime() {
    if (_orderSettings?.serviceTime != null) {
      return _orderSettings!.serviceTime!.isCurrentlyServiceable();
    }
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = 8 * 60; // 8:00 AM
    final endMinutes = 21 * 60; // 9:00 PM
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  Future<void> _checkServiceableTimeAndProceed({
    required Future<void> Function() onProceed,
  }) async {
    if (_isServiceableTime()) {
      await onProceed();
    } else {
      final String timeRange =
          _orderSettings?.serviceTime?.formattedRange ?? '8:00 AM to 9:00 PM';
      final shouldPlace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.w),
          ),
          title: Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                color: Colors.orange.shade800,
                size: 24.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Serviceable Time Over',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Serviceable time is over ($timeRange). Your placed order will be delivered tomorrow. If you want, you can place your order now.',
            style: TextStyle(
              fontSize: 13.5.sp,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.w),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              ),
              child: Text(
                'Place',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldPlace == true && mounted) {
        await onProceed();
      }
    }
  }

  Widget _buildBottomCheckoutBar(
    model.CartData cartData, {
    bool isLoading = false,
  }) {
    final double toPay = cartData.grandTotal ?? 0.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Left: Payment Mode Selector
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: () => _showPaymentMethodBottomSheet(context, _orderSettings),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Icon(
                        _getPaymentMethodIcon(selectedPaymentMethod),
                        color: const Color(0xFF1E242B),
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PAY USING',
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _getPaymentMethodDisplayName(selectedPaymentMethod),
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E242B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 16.sp,
                                color: const Color(0xFF2E7D32),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            // Right: Place Order Button with Amount
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 48.h,
                child: widget.isFood
                    ? BlocBuilder<FoodOrderBloc, FoodOrderState>(
                        bloc: _foodOrderBloc,
                        builder: (context, foodState) {
                          final bool isPlacingOrder = foodState is FoodOrderPlacing;
                          final bool isMissingSelection =
                              selectedAddress == null ||
                              selectedPaymentMethod == null;

                          return ElevatedButton(
                            onPressed: (isLoading || isPlacingOrder || isMissingSelection)
                                ? null
                                : () {
                                    _checkServiceableTimeAndProceed(
                                      onProceed: () async {
                                        String finalPaymentMode = 'COD';
                                        if (selectedPaymentMethod == 'UPI' ||
                                            selectedPaymentMethod == 'Card') {
                                          finalPaymentMode = 'ONLINE';
                                          SnackbarUtils.showSuccessSnackbar(
                                            context,
                                            'Redirecting to Payment Gateway...',
                                          );
                                        }

                                        // Build items list from SQLite FoodCartDb
                                        final localItems = await FoodCartDb.instance.getCartItems();
                                        final List<Map<String, dynamic>> payloadItems = localItems.map((item) => {
                                          "vendor_item_id": item['vendor_item_id'] as int,
                                          "quantity": item['quantity'] as int,
                                        }).toList();

                                        final vendorId = await FoodCartDb.instance.getVendorId();
                                        final customerUuid = await SecureStorage.getCustomerUuid() ?? "16b33cd8-a38a-4462-a575-c8b1938ab438";
                                        final couponCode = await SecureStorage.getSelectedCouponCode();
                                        final walletPoints = await SecureStorage.getAppliedWalletPoints();

                                        _foodOrderBloc?.add(
                                          PlaceFoodOrderEvent(
                                            vendorId: vendorId,
                                            customerUuid: customerUuid,
                                            addressUuid: selectedAddress!.uuId ?? selectedAddress!.id.toString(),
                                            couponCode: (couponCode != null && couponCode.isNotEmpty) ? couponCode : null,
                                            applyWalletPoints: walletPoints > 0 ? walletPoints : null,
                                            paymentMode: finalPaymentMode,
                                            customerNote: _customerNoteController.text.trim().isNotEmpty
                                                ? _customerNoteController.text.trim()
                                                : null,
                                            items: payloadItems,
                                          ),
                                        );
                                      },
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                            ),
                            child: isPlacingOrder
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Place Order',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Container(
                                        width: 1,
                                        height: 13.h,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '₹${toPay.toInt()}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      )
                    : BlocBuilder<CheckoutBloc, CheckoutState>(
                        bloc: _checkoutBloc,
                        builder: (context, state) {
                          final bool isPlacingOrder = state is OrderPlacing;
                          final OrderSettingsModel? orderSettings =
                              state is CheckoutLoaded
                                  ? state.settings
                                  : _orderSettings;
                          final bool isAutoAssign = _isAutoAssign(orderSettings);
                          final bool isMissingSelection =
                              selectedAddress == null ||
                              (!isAutoAssign && selectedSlotUuid == null) ||
                              selectedPaymentMethod == null;

                          return ElevatedButton(
                            onPressed:
                                (isLoading || isPlacingOrder || isMissingSelection)
                                ? null
                                : () {
                                    _checkServiceableTimeAndProceed(
                                      onProceed: () async {
                                        String finalPaymentMode = 'COD';
                                        if (selectedPaymentMethod == 'UPI' ||
                                            selectedPaymentMethod == 'Card') {
                                          finalPaymentMode = 'ONLINE';
                                          SnackbarUtils.showSuccessSnackbar(
                                            context,
                                            'Redirecting to Payment Gateway...',
                                          );
                                        }

                                        _checkoutBloc.add(
                                          PlaceOrderEvent(
                                            paymentMode: finalPaymentMode,
                                            addressUuid:
                                                selectedAddress!.uuId ??
                                                selectedAddress!.id.toString(),
                                            slotUuid: isAutoAssign
                                                ? null
                                                : selectedSlotUuid,
                                            customerNote: _customerNoteController.text.trim().isNotEmpty
                                                ? _customerNoteController.text.trim()
                                                : null,
                                          ),
                                        );
                                      },
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                            ),
                            child: isPlacingOrder
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Place Order',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Container(
                                        width: 1,
                                        height: 13.h,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '₹${toPay.toInt()}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5.sp,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cart Item ─────────────────────────────────────────────────────────────

  Widget _buildCartItem(
    BuildContext context,
    model.CartItem item,
    int index, {
    required int totalCount,
    bool isLoading = false,
  }) {
    final title = item.product?.productName ?? '';
    final imageUrl = (item.product?.images.isNotEmpty ?? false)
        ? item.product!.images.first.productImage
        : (item.product?.productImage ?? '');
    final totalPrice = item.totalPrice;
    final quantity = item.quantity;
    final uom = item.variantLabel.isNotEmpty
        ? item.variantLabel
        : (item.subUomName.isNotEmpty ? item.subUomName : item.uomName);

    final actualPrice = item.actualPrice;
    final sellingPrice = item.sellingPrice;
    final isUpdating = _updatingCartItemId == item.id;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Thumbnail
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.w),
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                clipBehavior: Clip.antiAlias,
                child: (imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        width: 64.w,
                        height: 64.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.inventory_2_outlined, size: 24.w, color: Colors.grey.shade400),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.inventory_2_outlined, size: 24.w, color: Colors.grey.shade400),
                      ),
              ),
              SizedBox(width: 12.w),

              // Title & Weight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: const Color(0xFF1E242B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (uom.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        uom,
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),

              // Stepper Button & Prices on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glossy Green Stepper
                  Container(
                    width: 76.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(8.w),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.22),
                          blurRadius: 3,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: isUpdating
                        ? const Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() => _updatingCartItemId = item.id);
                                        final loc = locationService.locationNotifier.value;
                                        if (quantity > 1) {
                                          context.read<CartBloc>().add(
                                            UpdateCartEvent(
                                              cartItemId: item.id,
                                              quantity: quantity - 1,
                                              lat: loc?.lat ?? 0.0,
                                              lng: loc?.lng ?? 0.0,
                                            ),
                                          );
                                        } else {
                                          context.read<CartBloc>().add(
                                            RemoveCartItemEvent(item.id),
                                          );
                                        }
                                      },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                                  child: const Icon(Icons.remove, size: 15, color: Colors.white),
                                ),
                              ),
                              Text(
                                '$quantity',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 13.5.sp,
                                ),
                              ),
                              InkWell(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() => _updatingCartItemId = item.id);
                                        final loc = locationService.locationNotifier.value;
                                        context.read<CartBloc>().add(
                                          UpdateCartEvent(
                                            cartItemId: item.id,
                                            quantity: quantity + 1,
                                            lat: loc?.lat ?? 0.0,
                                            lng: loc?.lng ?? 0.0,
                                          ),
                                        );
                                      },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                                  child: const Icon(Icons.add, size: 15, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                  SizedBox(height: 5.h),

                  // Prices: MRP strikethrough + Selling Price
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (actualPrice > sellingPrice) ...[
                        Text(
                          '₹${(actualPrice * quantity).toInt()}',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        '₹${totalPrice.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5.sp,
                          color: const Color(0xFF1E242B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (index < totalCount - 1) ...[
            SizedBox(height: 10.h),
            Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
          ],
        ],
      ),
    );
  }

  // ── Loaded Cart Layout ────────────────────────────────────────────────────

  // ── Checkout Sections ──────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.4),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Future<void> _changeAddress(BuildContext context) async {
    final result = await context.push(AppRoutePath.address);
    if (result != null && result is AddressModel) {
      setState(() {
        selectedAddress = result;
      });
      await SecureStorage.saveSelectedAddressUuid(
        result.uuId ?? result.id.toString(),
      );
      if (result.lat != null && result.lng != null) {
        locationService.locationNotifier.value = LocationState(
          lat: result.lat!,
          lng: result.lng!,
          address: result.addressLine,
          label: result.label,
          city: result.city,
          pincode: result.pincode,
        );
        logger.i('🛒 CartPage: Updated locationNotifier to manually chosen address: ${result.label}');
      }
      if (context.mounted) {
        final loc = locationService.locationNotifier.value;
        context.read<CartBloc>().add(
          GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
        );
      }
    }
    if (context.mounted) {
      context.read<AddressBloc>().add(FetchAddressList());
    }
  }

  // ── Delivering To Header (Above Items) ────────────────────────────────────

  Widget _buildDeliveringToHeader(BuildContext context) {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, state) {
        final bool hasAddress = selectedAddress != null;
        final String label = hasAddress ? selectedAddress!.label : 'Select Location';
        final String fullAddress = hasAddress
            ? (selectedAddress!.addressLine.isNotEmpty
                ? selectedAddress!.addressLine
                : (selectedAddress!.city ?? ''))
            : 'Add delivery address';

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: const Color(0xFF2E7D32),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Delivering to ',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E242B),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2E7D32),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      fullAddress,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () => _changeAddress(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(20.w),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    hasAddress ? 'Change' : 'Add',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliverySlotsSection(List<SlotModel> slots) {
    if (slots.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Delivery Slots',
      child: Column(
        children: slots.map((slot) {
          bool isSelected = selectedSlotUuid == slot.uuId;
          return GestureDetector(
            onTap: () => setState(() {
              selectedSlotUuid = slot.uuId;
              selectedSlotLabel = slot.label;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: isSelected ? Colors.green : Colors.grey.shade600,
                    size: 22,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      slot.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.green, size: 20.w)
                  else
                    Icon(
                      Icons.radio_button_off,
                      color: Colors.grey.shade400,
                      size: 20.w,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadedCart(model.CartData cartData, {bool isLoading = false}) {
    final items = cartData.items ?? [];
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              logger.i('🔄 CartPage: Pull-to-refresh triggered');
              setState(() {
                _isInitialFetchInProgress = true;
                _hasStartedLoading = false;
              });
              final loc = locationService.locationNotifier.value;
              context.read<CartBloc>().add(
                GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
              );
              // Wait for a loading state to start so the indicator stays visible
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16.w),
              child: BlocBuilder<CheckoutBloc, CheckoutState>(
                bloc: _checkoutBloc,
                builder: (context, checkoutState) {
                  final settings = checkoutState is CheckoutLoaded
                      ? checkoutState.settings
                      : _orderSettings;
                  final slots = checkoutState is CheckoutLoaded
                      ? checkoutState.slots
                      : (_cachedSlots ?? <SlotModel>[]);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivering To Header
                      _buildDeliveringToHeader(context),

                      // Items card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cart items list
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: items.length,
                              itemBuilder: (context, index) => _buildCartItem(
                                context,
                                items[index],
                                index,
                                totalCount: items.length,
                                isLoading: isLoading,
                              )
                              .animate()
                              .fadeIn(delay: (40 * index).ms)
                              .slideY(begin: 0.08, end: 0),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                // Add more items button
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.w),
                                      onTap: () {
                                        logger.i(
                                          '🛍️ CartPage: User tapped "Add items" → navigating to home with fromCart=true',
                                        );
                                        context.go('/?fromCart=true&isFood=${widget.isFood}');
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF7EE),
                                          borderRadius: BorderRadius.circular(12.w),
                                          border: Border.all(
                                            color: const Color(0xFFC8E6C9),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 16.sp,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              'Add items',
                                              style: TextStyle(
                                                color: const Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12.5.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 10.w),

                                // Clear all items button
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.w),
                                      onTap: () {
                                        logger.w(
                                          '🗑️ CartPage: User tapped "Clear all items"',
                                        );
                                        context.read<CartBloc>().add(
                                          ClearCartEvent(),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius: BorderRadius.circular(12.w),
                                          border: Border.all(
                                            color: const Color(0xFFFFD2D7),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16.sp,
                                              color: const Color(0xFFE11D48),
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              'Clear all items',
                                              style: TextStyle(
                                                color: const Color(0xFFE11D48),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      // 1. Combined Offers & Wallet Section
                      _buildOffersAndWalletCard(context, cartData),
                      SizedBox(height: 14.h),

                      // 2. Bill Details
                      _buildBillDetailsCard(cartData, isLoading: isLoading),
                      SizedBox(height: 16.h),

                      // CHECKOUT SECTIONS

                      // Delivery Information Section
                      // _buildDeliveryInfoSection(
                      //   cartData.deliveryInfo?.deliveryCharge ?? 0.0,
                      // ),

                      if (settings != null) ...[
                        if (!widget.isFood && !_isAutoAssign(settings))
                          _buildDeliverySlotsSection(slots),
                      ] else if (checkoutState is CheckoutLoading) ...[
                        if (!widget.isFood && !_isAutoAssign(_orderSettings)) ...[
                          // Delivery Slots Shimmer
                          _buildSectionCard(
                            title: 'Delivery Slots',
                            child: Column(
                              children: [
                                ShimmerPlaceholder.rounded(
                                  height: 45,
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      SizedBox(height: 16.h),
                      _buildCustomerNoteSection(),
                      SizedBox(height: 16.h),
                      _buildNoteCard(),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        _buildBottomCheckoutBar(cartData, isLoading: isLoading),
      ],
    );
  }

  // ── Empty Cart UI ─────────────────────────────────────────────────────────

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_grocery_store_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 16.h),
          const Text(
            'Add items to start building your cart.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    logger.d('🏗️ CartPage: build() called');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            logger.i('⬅️ CartPage: Back button pressed');
            context.go(AppRoutePath.home);
          },
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go(AppRoutePath.home);
        },
        child: MultiBlocListener(
          listeners: [
          BlocListener<CheckoutBloc, CheckoutState>(
            bloc: _checkoutBloc,
            listener: (context, state) {
              if (state is CheckoutLoaded) {
                logger.i(
                  '⚙️ CartPage: Order settings loaded — auto_assign_mode="${state.settings.autoAssignMode}", isAutoAssign=${_isAutoAssign(state.settings)}',
                );
                setState(() {
                  _orderSettings = state.settings;
                  _cachedSlots = state.slots;
                  final bool isCod = state.settings.isCodEnabled ||
                      state.settings.availableModes.any((m) => m.toUpperCase() == 'COD');
                  final bool isOnline = state.settings.isOnlineEnabled ||
                      state.settings.availableModes.any((m) => m.toUpperCase() == 'ONLINE');
                  if (isCod && !isOnline) {
                    selectedPaymentMethod = 'COD (Cash on Delivery)';
                  } else if (isOnline && !isCod) {
                    selectedPaymentMethod = 'UPI';
                  } else {
                    selectedPaymentMethod ??= isCod ? 'COD (Cash on Delivery)' : 'UPI';
                  }
                });
              } else if (state is OrderPlacedSuccess) {
                setState(() => _isOrderPlaced = true);
                globalCart.clear();
                saveCartToStorage();
                context.read<CartBloc>().add(ClearCartEvent(isSilent: true));
                context.pushReplacement(
                  AppRoutePath.success,
                  extra: widget.isFood,
                );
              } else if (state is OrderPlacedFailure) {
                String cleanMessage = state.message;
                if (cleanMessage.startsWith('Invalid Request: ')) {
                  cleanMessage = cleanMessage.replaceFirst(
                    'Invalid Request: ',
                    '',
                  );
                }
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Cannot Place Order',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      cleanMessage,
                      style: const TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'OK',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          BlocListener<AddressBloc, AddressState>(
            listener: (context, state) {
              if (state is AddressLoaded && state.addresses.isNotEmpty) {
                setState(() {
                  selectedAddress ??= state.addresses.firstWhere(
                    (a) => a.isDefault,
                    orElse: () => state.addresses.first,
                  );
                });
                if (selectedAddress != null) {
                  SecureStorage.saveSelectedAddressUuid(
                    selectedAddress!.uuId ?? selectedAddress!.id.toString(),
                  );
                  if (selectedAddress!.lat != null && selectedAddress!.lng != null) {
                    final currentVal = locationService.locationNotifier.value;
                    if (currentVal == null ||
                        currentVal.lat != selectedAddress!.lat ||
                        currentVal.lng != selectedAddress!.lng ||
                        currentVal.label != selectedAddress!.label) {
                      locationService.locationNotifier.value = LocationState(
                        lat: selectedAddress!.lat!,
                        lng: selectedAddress!.lng!,
                        address: selectedAddress!.addressLine,
                        label: selectedAddress!.label,
                        city: selectedAddress!.city,
                        pincode: selectedAddress!.pincode,
                      );
                      logger.i('🛒 CartPage: Sync locationNotifier to default address: ${selectedAddress!.label}');
                    }
                  }
                }
              }
            },
          ),
          BlocListener<WalletBloc, WalletState>(
            bloc: _walletBloc,
            listener: (context, state) {
              if (state is WalletActionSuccess) {
                // If a dialog is open (Apply Wallet), close it
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                final loc = locationService.locationNotifier.value;
                context.read<CartBloc>().add(
                  GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
                );
              } else if (state is WalletActionError) {
                SnackbarUtils.showErrorSnackbar(context, state.message);
                // If it's already applied, refresh the cart to sync UI
                if (state.message.toLowerCase().contains('already applied')) {
                  final loc = locationService.locationNotifier.value;
                  context.read<CartBloc>().add(
                    GetCartListEvent(
                      lat: loc?.lat ?? 0.0,
                      lng: loc?.lng ?? 0.0,
                    ),
                  );
                }
              }
            },
          ),
          if (widget.isFood && _foodOrderBloc != null)
            BlocListener<FoodOrderBloc, FoodOrderState>(
              bloc: _foodOrderBloc,
              listener: (context, state) {
                if (state is FoodOrderPlacedSuccess) {
                  setState(() => _isOrderPlaced = true);
                  // Clear items
                  context.read<CartBloc>().add(ClearCartEvent(isSilent: true));
                  context.pushReplacement(
                    AppRoutePath.success,
                    extra: true,
                  );
                } else if (state is FoodOrderPlacedFailure) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Cannot Place Order',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        state.message,
                        style: const TextStyle(fontSize: 15),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            'OK',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          BlocListener<CartBloc, CartState>(
            listener: (context, state) {
              if (state is CartLoaded) {
                if (_updatingCartItemId != null) {
                  setState(() => _updatingCartItemId = null);
                }
              } else if (state is CartError) {
                setState(() => _updatingCartItemId = null);
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
              } else if (state is CartActionSuccess ||
                  state is CouponActionSuccess) {
                final loc = locationService.locationNotifier.value;
                context.read<CartBloc>().add(
                  GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
                );
                String msg = state is CartActionSuccess
                    ? state.message
                    : (state as CouponActionSuccess).message;
                SnackbarUtils.showSuccessSnackbar(context, msg);
              }
            },
          ),
        ],
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              _hasStartedLoading = true;
            }

            if (_isInitialFetchInProgress && _hasStartedLoading && (state is CartLoaded || state is CartError)) {
              _isInitialFetchInProgress = false;
            }

            if (state is CartLoaded) {
              _lastKnownCartData = state.cartData;
            } else if (state is CartActionSuccess && state.cartData != null) {
              _lastKnownCartData = state.cartData;
            } else if (state is CartLoading && state.cartData != null) {
              _lastKnownCartData = state.cartData;
            } else if (state is CartError && state.cartData != null) {
              _lastKnownCartData = state.cartData;
            }

            if (_isOrderPlaced && _lastKnownCartData != null) {
              return _buildLoadedCart(_lastKnownCartData!, isLoading: false);
            }

            if (_isInitialFetchInProgress) {
              return _buildCartShimmer();
            }

            if (state is CartLoading && _lastKnownCartData != null) {
              return _buildLoadedCart(_lastKnownCartData!, isLoading: true);
            } else if (state is CartLoading) {
              return _buildCartShimmer();
            } else if (state is CartLoaded) {
              final items = state.cartData.items ?? [];
              if (items.isEmpty) {
                return _buildEmptyCart();
              }
              return _buildLoadedCart(state.cartData, isLoading: false);
            } else if (state is CartError) {
              if (_lastKnownCartData != null &&
                  (_lastKnownCartData!.items?.isNotEmpty ?? false)) {
                return _buildLoadedCart(_lastKnownCartData!, isLoading: false);
              }
              return Center(child: Text(state.message));
            }

            // For all other states (CartActionSuccess, CouponActionSuccess, CouponsLoaded, etc.)
            // we show the last known cart data if available.
            if (_lastKnownCartData != null) {
              final isLoading = state is CartLoading;
              return _buildLoadedCart(
                _lastKnownCartData!,
                isLoading: isLoading,
              );
            }

            return _buildEmptyCart();
          },
        ),
      ),
    ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildCartShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Delivering To Header Shimmer
          ShimmerPlaceholder.rounded(height: 50, borderRadius: 16),
          SizedBox(height: 12.h),

          // 1. Items Card Shimmer
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerPlaceholder.rounded(height: 16, width: 100.w),
                    ShimmerPlaceholder.rounded(height: 14, width: 50.w),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
                SizedBox(height: 16.h),

                // 2 Items in List
                ...List.generate(
                  2,
                  (index) => Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerPlaceholder.rounded(
                            width: 60.w,
                            height: 60.w,
                            borderRadius: 12,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerPlaceholder.rounded(height: 15, width: 120.w),
                                SizedBox(height: 6.h),
                                ShimmerPlaceholder.rounded(height: 12, width: 80.w),
                                SizedBox(height: 8.h),
                                ShimmerPlaceholder.rounded(height: 20, width: 100.w, borderRadius: 6.w),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ShimmerPlaceholder.rounded(height: 32, width: 75.w, borderRadius: 8),
                              SizedBox(height: 10.h),
                              ShimmerPlaceholder.rounded(height: 15, width: 50.w),
                            ],
                          ),
                        ],
                      ),
                      if (index < 1) ...[
                        SizedBox(height: 14.h),
                        Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
                        SizedBox(height: 14.h),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Add / Clear buttons
                Row(
                  children: [
                    Expanded(
                      child: ShimmerPlaceholder.rounded(height: 40, borderRadius: 10),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: ShimmerPlaceholder.rounded(height: 40, borderRadius: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 2. Combined Offers & Wallet Card Shimmer
          ShimmerPlaceholder.rounded(height: 108, borderRadius: 16),
          SizedBox(height: 14.h),

          // 3. Bill Details Card Shimmer
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.rounded(height: 14, width: 100.w),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerPlaceholder.rounded(height: 12, width: 80.w),
                    ShimmerPlaceholder.rounded(height: 12, width: 40.w),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerPlaceholder.rounded(height: 12, width: 90.w),
                    ShimmerPlaceholder.rounded(height: 12, width: 40.w),
                  ],
                ),
                SizedBox(height: 12.h),
                Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerPlaceholder.rounded(height: 14, width: 60.w),
                    ShimmerPlaceholder.rounded(height: 14, width: 50.w),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyWalletDialog(BuildContext context, int availablePoints) {
    // Determine order total for percentage calculations
    final double orderTotal =
        _lastKnownCartData?.productsTotal ??
        _lastKnownCartData?.totalAmount ??
        0.0;

    final controller = TextEditingController(text: availablePoints.toString());

    showDialog(
      context: context,
      builder: (ctx) => BlocBuilder<WalletBloc, WalletState>(
        bloc: _walletBloc,
        builder: (context, state) {
          final walletData = state is WalletDataState
              ? state
              : const WalletDataState();
          final isLoading = walletData.isActionLoading;

          final double limitPercent =
              walletData.summary?.walletUsageLimitPercent ?? 0.0;
          final int minPointsRequired = orderTotal > 0
              ? (orderTotal * (limitPercent / 100)).ceil()
              : 0;

          // Logic: Can only use wallet if user has enough points to meet the minimum requirement
          final bool canUseWallet = availablePoints >= minPointsRequired;

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            title: Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                SizedBox(width: 12.w),
                const Text(
                  'Apply Wallet',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '$availablePoints pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                if (!canUseWallet)
                  Text(
                    'You do not have enough wallet points to meet the minimum requirement of $minPointsRequired pts.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else ...[
                  const Text(
                    'Enter points to apply:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. $minPointsRequired',
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canUseWallet)
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          final pts = int.tryParse(controller.text) ?? 0;

                          if (widget.isFood) {
                            SecureStorage.saveAppliedWalletPoints(pts).then((_) {
                              if (context.mounted) {
                                final loc = locationService.locationNotifier.value;
                                context.read<CartBloc>().add(
                                      GetCartListEvent(
                                        lat: loc?.lat ?? 0.0,
                                        lng: loc?.lng ?? 0.0,
                                      ),
                                    );
                                Navigator.pop(ctx);
                              }
                            });
                          } else {
                            _walletBloc.add(ApplyWalletPoints(pts));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Apply Points',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BillScallopTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const double waveWidth = 14.0;
    const double waveHeight = 4.0;
    final int count = (size.width / waveWidth).ceil();
    final double step = size.width / count;

    path.moveTo(0, waveHeight);
    for (int i = 0; i < count; i++) {
      final double startX = i * step;
      path.quadraticBezierTo(
        startX + step / 2,
        0,
        startX + step,
        waveHeight,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

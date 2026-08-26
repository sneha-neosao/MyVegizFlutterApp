import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/coupon_model.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import '../../../../core/utils/responsive_utils.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  final TextEditingController _couponController = TextEditingController();
  List<CouponModel> _coupons = [];

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(FetchAvailableCouponsEvent());
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon(String code) {
    context.read<CartBloc>().add(ApplyCouponEvent(code.trim()));
  }

  Widget _buildDottedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black26),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    bool isAvailable = coupon.isApplicable;
    IconData bankIcon = Icons.local_offer;
    Color iconColor = Colors.blue.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(bankIcon, color: iconColor, size: 20),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    coupon.couponCode,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  if (isAvailable) {
                    _applyCoupon(coupon.couponCode);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Text(
                    'APPLY',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isAvailable
                          ? Colors.blue.shade700
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (coupon.minOrderNeeded != null && coupon.minOrderNeeded! > 0)
            Text(
              'Add items worth ₹${coupon.minOrderNeeded} more to avail this offer.',
              style: TextStyle(
                fontSize: 13.sp,
                color: isAvailable
                    ? Colors.green.shade700
                    : Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (isAvailable)
            Text(
              'You save ₹${coupon.discountPreview ?? 0} with this code',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          _buildDottedDivider(),
          Text(
            coupon.couponDescription ?? 'Special Discount',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            coupon.termscondition ??
                'Use code ${coupon.couponCode} to get discount.',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerPlaceholder.rounded(width: 100, height: 24),
                  ShimmerPlaceholder.rounded(width: 50, height: 20),
                ],
              ),
              SizedBox(height: 16.h),
              ShimmerPlaceholder.rounded(width: double.infinity, height: 16),
              SizedBox(height: 8.h),
              ShimmerPlaceholder.rounded(width: 150, height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CouponsLoaded) {
          setState(() {
            _coupons = state.coupons;
          });
        } else if (state is CouponActionSuccess) {
          // If we successfully applied a coupon, close the page
          Navigator.pop(context);
        } else if (state is CartError) {
          SnackbarUtils.showErrorSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        bool isLoading = state is CartLoading;

        List<CouponModel> availableCoupons = _coupons
            .where((c) => c.isApplicable)
            .toList();
        List<CouponModel> unavailableCoupons = _coupons
            .where((c) => !c.isApplicable)
            .toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Apply Coupon',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter Coupon Code',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15.sp,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => _applyCoupon(_couponController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'APPLY',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isLoading && _coupons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildShimmerLoading(),
                      )
                    else if (_coupons.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No coupons available",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (availableCoupons.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Text(
                            'AVAILABLE COUPONS',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: availableCoupons
                                .map((c) => _buildCouponCard(c))
                                .toList()
                                .animate(interval: 50.ms)
                                .fade(duration: 400.ms)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                ),
                          ),
                        ),
                      ],
                      if (unavailableCoupons.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                          child: Text(
                            'UNAVAILABLE COUPONS',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: unavailableCoupons
                                .map((c) => _buildCouponCard(c))
                                .toList()
                                .animate(interval: 50.ms)
                                .fade(duration: 400.ms)
                                .slideY(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                ),
                          ),
                        ),
                      ],
                    ],

                    SizedBox(height: 40.h),
                    SizedBox(width: 8.w),
                  ],
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}

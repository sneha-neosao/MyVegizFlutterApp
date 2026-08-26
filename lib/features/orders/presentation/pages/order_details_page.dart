import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/injector_conf.dart';
import '../../../../routes/app_route_path.dart';
import '../../bloc/order_bloc.dart';
import '../../bloc/order_event.dart';
import '../../bloc/order_state.dart';
import '../../bloc/food_order_bloc.dart';
import '../../bloc/food_order_event.dart';
import '../../bloc/food_order_state.dart';
import '../../data/models/food_rating_model.dart';
import '../../data/repository/food_order_repo.dart';
import '../../data/repository/grocery_order_repo.dart';
import '../../../profile/data/models/rating_model.dart';
import '../../../../core/api/api/api_exception.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/shimmer_placeholder.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId; // This is actually uu_id
  final bool isFood;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    this.isFood = false,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late final GroceryOrderBloc _orderBloc;
  late final FoodOrderBloc _foodOrderBloc;
  final Map<int, double> _itemRatings = {};
  final Map<int, String> _itemReviews = {};
  double _vendorRating = 0.0;
  String _vendorReview = '';
  double _deliveryRating = 0.0;
  String _deliveryReview = '';

  @override
  void initState() {
    super.initState();
    if (widget.isFood) {
      _foodOrderBloc = getIt<FoodOrderBloc>()
        ..add(FetchFoodOrderDetailsEvent(widget.orderId));
    } else {
      _orderBloc = getIt<GroceryOrderBloc>()
        ..add(FetchOrderDetailsEvent(widget.orderId));
    }
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      if (widget.isFood) {
        final repo = getIt<FoodOrderRepository>();
        final res = await repo.fetchFoodOrderRatings(widget.orderId);
        res.fold(
          (l) => null,
          (r) {
            if (mounted) {
              setState(() {
                if (r.vendorRating != null && r.vendorRating!.rating > 0) {
                  _vendorRating = r.vendorRating!.rating;
                  _vendorReview = r.vendorRating!.review;
                }
                if (r.deliveryRating != null && r.deliveryRating!.rating > 0) {
                  _deliveryRating = r.deliveryRating!.rating;
                  _deliveryReview = r.deliveryRating!.review;
                }
                for (final item in r.productRatings) {
                  _itemRatings[item.orderItemId] = item.rating;
                  _itemReviews[item.orderItemId] = item.review;
                }
              });
            }
          },
        );
      } else {
        final repo = getIt<GroceryOrderRepository>();
        final res = await repo.fetchOrderRatings(widget.orderId);
        res.fold(
          (l) => null,
          (r) {
            if (mounted) {
              setState(() {
                if (r.deliveryRating != null && r.deliveryRating!.rating > 0) {
                  _deliveryRating = r.deliveryRating!.rating;
                  _deliveryReview = r.deliveryRating!.review;
                }
                for (final item in r.productRatings) {
                  _itemRatings[item.orderItemId] = item.rating;
                  _itemReviews[item.orderItemId] = item.review;
                }
              });
            }
          },
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (widget.isFood) {
      _foodOrderBloc.close();
    } else {
      _orderBloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isFood
        ? BlocProvider.value(
            value: _foodOrderBloc,
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              appBar: _buildAppBar(
                actions: [
                  BlocBuilder<FoodOrderBloc, FoodOrderState>(
                    bloc: _foodOrderBloc,
                    builder: (context, state) {
                      if (state is FoodOrderDetailsLoaded) {
                        final status =
                            state.orderDetails.orderStatus.toUpperCase();
                        if (status == 'PICKED_UP' || status == 'ON_THE_WAY') {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF3E0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.near_me_rounded,
                                color: Color(0xFFFC8019),
                                size: 20,
                              ),
                              onPressed: () {
                                final details = state.orderDetails;
                                if (details.vendor?.lat != null &&
                                    details.vendor?.lng != null &&
                                    details.deliveryDetails?.lat != null &&
                                    details.deliveryDetails?.lng != null) {
                                  context.push(
                                    AppRoutePath.orderTracking,
                                    extra: {
                                      'storeLat': details.vendor!.lat,
                                      'storeLng': details.vendor!.lng,
                                      'deliveryLat':
                                          details.deliveryDetails!.lat,
                                      'deliveryLng':
                                          details.deliveryDetails!.lng,
                                      'storeName': details.vendor!.entityName,
                                      'deliveryName':
                                          details.deliveryDetails!.name,
                                      'orderId': details.uuId,
                                      'isFood': widget.isFood,
                                    },
                                  ).then((_) {
                                    if (mounted) {
                                      _foodOrderBloc.add(
                                        FetchFoodOrderDetailsEvent(
                                          widget.orderId,
                                        ),
                                      );
                                    }
                                  });
                                } else {
                                  SnackbarUtils.showErrorSnackbar(
                                    context,
                                    'Tracking coordinates not available for this order',
                                  );
                                }
                              },
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              body: BlocConsumer<FoodOrderBloc, FoodOrderState>(
                bloc: _foodOrderBloc,
                listener: (context, state) {
                  logger.d(
                    '===== FOOD ORDER UI ===== FoodOrderState (Details): $state',
                  );
                  if (state is FoodOrderCancelled) {
                    SnackbarUtils.showSuccessSnackbar(context, state.message);
                    _foodOrderBloc.add(
                      FetchFoodOrderDetailsEvent(widget.orderId),
                    );
                  } else if (state is FoodOrderCancelError) {
                    SnackbarUtils.showErrorSnackbar(
                      context,
                      _cleanMessage(state.message),
                    );
                  }
                },
                buildWhen: (previous, current) =>
                    current is FoodOrderDetailsLoading ||
                    current is FoodOrderDetailsLoaded ||
                    current is FoodOrderDetailsError ||
                    current is FoodOrderInitial,
                builder: (context, state) {
                  if (state is FoodOrderDetailsLoading ||
                      state is FoodOrderInitial) {
                    return _buildShimmerDetails();
                  } else if (state is FoodOrderDetailsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _cleanMessage(state.message),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                logger.d(
                                  '===== FOOD ORDER UI ===== Retrying Fetch Food Order Details',
                                );
                                _foodOrderBloc.add(
                                  FetchFoodOrderDetailsEvent(widget.orderId),
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is FoodOrderDetailsLoaded) {
                    final details = state.orderDetails;
                    logger.d(
                      '===== FOOD ORDER UI ===== Rendered Food Order Details: id=${details.id}',
                    );
                    final isDelivered =
                        details.orderStatus.toUpperCase() == 'DELIVERED';
                    final canCancel =
                        details.orderStatus.toUpperCase() == 'PENDING' ||
                        details.orderStatus.toUpperCase() == 'PROCESSING';
                    final orderUuId = details.uuId.isNotEmpty
                        ? details.uuId
                        : widget.orderId;

                    String formattedDate = '';
                    try {
                      final date = DateTime.parse(details.createdAt).toLocal();
                      formattedDate = DateFormat(
                        'dd MMM yyyy • hh:mm a',
                      ).format(date);
                    } catch (e) {
                      formattedDate = details.createdAt;
                    }

                    return Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusFlipCard(
                                      orderStatus: details.orderStatus,
                                      isFood: true,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.receipt_long_outlined,
                                      title: 'Order Summary',
                                      child: Column(
                                        children: [
                                          _buildDetailRow(
                                            'Order ID',
                                            'ORD-${details.id}',
                                            isBold: true,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Vendor',
                                            details.vendor?.entityName ?? '',
                                            trailingWidget: isDelivered &&
                                                    details.vendor != null
                                                ? _buildRatingChip(
                                                    rating: _vendorRating,
                                                    label: 'Rate',
                                                    onTap: () {
                                                      _showVendorRatingBottomSheet(
                                                        orderUuId: orderUuId,
                                                        vendorName: details.vendor!.entityName,
                                                        vendorImage: details.vendor!.entityImage,
                                                      );
                                                    },
                                                  )
                                                : null,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Date',
                                            formattedDate,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Status',
                                            _getFormattedStatus(
                                              details.orderStatus,
                                            ),
                                            valueColor: _getStatusColor(
                                              details.orderStatus,
                                            ),
                                            isStatusBadge: true,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Payment Mode',
                                            details.paymentMode,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (details.customerNote != null &&
                                        details.customerNote!.trim().isNotEmpty) ...[
                                      _buildCustomerNoteCard(
                                        details.customerNote!,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    if (details.deliveryDetails != null) ...[
                                      _buildInfoCard(
                                        icon: Icons.location_on_outlined,
                                        title: 'Delivery Details',
                                        trailingWidget: isDelivered
                                            ? _buildRatingChip(
                                                rating: _deliveryRating,
                                                label: 'Rate Delivery',
                                                onTap: () {
                                                  _showDeliveryRatingBottomSheet(
                                                    orderUuId: orderUuId,
                                                    deliveryName: details.deliveryDetails!.name,
                                                    isFood: true,
                                                  );
                                                },
                                              )
                                            : null,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    details.deliveryDetails!.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 15,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone_outlined,
                                                  size: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  details.deliveryDetails!.phone,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.home_outlined,
                                                  size: 15,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '${details.deliveryDetails!.address}, ${details.deliveryDetails!.pincode}',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade700,
                                                      fontSize: 13,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _buildInfoCard(
                                      icon: Icons.shopping_bag_outlined,
                                      title: 'Items',
                                      child: Column(
                                        children: [
                                          for (
                                            int i = 0;
                                            i < details.items.length;
                                            i++
                                          ) ...[
                                            _buildItemRow(
                                              details.items[i].vendorItemName,
                                              '${details.items[i].quantity} ${details.items[i].variantName}',
                                              '₹${details.items[i].totalPrice.toInt()}',
                                              details.items[i].images.isNotEmpty
                                                  ? details.items[i].images.first
                                                  : '',
                                              itemId: details.items[i].itemId,
                                              orderUuId: orderUuId,
                                              isFood: true,
                                              isDelivered: isDelivered,
                                            ),
                                            if (i < details.items.length - 1)
                                              _buildDivider(),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      title: 'Bill Details',
                                      child: Column(
                                        children: [
                                          _buildDetailRow(
                                            'Subtotal',
                                            '₹${details.totalAmount.toInt()}',
                                          ),
                                          if (details.couponDiscount > 0) ...[
                                            _buildDivider(),
                                            _buildDetailRow(
                                              'Discount',
                                              '-₹${details.couponDiscount.toInt()}',
                                              valueColor: const Color(
                                                0xFF16A34A,
                                              ),
                                            ),
                                          ],
                                          if (details.walletDiscountAmount > 0) ...[
                                            _buildDivider(),
                                            _buildDetailRow(
                                              'Wallet Discount',
                                              '-₹${details.walletDiscountAmount.toInt()}',
                                              valueColor: const Color(
                                                0xFF16A34A,
                                              ),
                                            ),
                                          ],
                                          if (details.packingCharge > 0) ...[
                                            _buildDivider(),
                                            _buildDetailRow(
                                              'Packing Charges',
                                              '₹${details.packingCharge.toInt()}',
                                            ),
                                          ],
                                          if (details.platformCharges > 0) ...[
                                            _buildDivider(),
                                            _buildDetailRow(
                                              'Platform Charges',
                                              '₹${details.platformCharges.toInt()}',
                                            ),
                                          ],
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Delivery Fee',
                                            '₹${details.deliveryCharge.toInt()}',
                                          ),
                                          _buildDivider(
                                            thickness: 1.5,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          _buildDetailRow(
                                            'Total Amount',
                                            '₹${details.grandTotal.toInt()}',
                                            isBold: true,
                                            isTotalRow: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (canCancel)
                              _buildCancelButton(
                                onPressed: () {
                                  _showFoodCancelDialog(
                                    context,
                                    details.uuId,
                                  );
                                },
                              ),
                          ],
                        ),
                        BlocBuilder<FoodOrderBloc, FoodOrderState>(
                          bloc: _foodOrderBloc,
                          builder: (context, buttonState) {
                            if (buttonState is FoodOrderCancelling) {
                              return Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          )
        : BlocProvider.value(
            value: _orderBloc,
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              appBar: _buildAppBar(),
              body: BlocConsumer<GroceryOrderBloc, OrderState>(
                listener: (context, state) {
                  if (state is OrderCancelled) {
                    SnackbarUtils.showSuccessSnackbar(context, state.message);
                    _orderBloc.add(FetchOrderDetailsEvent(widget.orderId));
                  } else if (state is OrderCancelError) {
                    SnackbarUtils.showErrorSnackbar(
                      context,
                      _cleanMessage(state.message),
                    );
                  }
                },
                buildWhen: (previous, current) =>
                    current is OrderDetailsLoading ||
                    current is OrderDetailsLoaded ||
                    current is OrderDetailsError ||
                    current is OrderInitial,
                builder: (context, state) {
                  if (state is OrderDetailsLoading || state is OrderInitial) {
                    return _buildShimmerDetails();
                  } else if (state is OrderDetailsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _cleanMessage(state.message),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _orderBloc.add(
                                FetchOrderDetailsEvent(widget.orderId),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E293B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is OrderDetailsLoaded) {
                    final details = state.orderDetails;
                    final isDelivered =
                        details.orderStatus.toUpperCase() == 'DELIVERED';
                    final canCancel =
                        details.orderStatus.toUpperCase() == 'PENDING' ||
                        details.orderStatus.toUpperCase() == 'PROCESSING';
                    final orderUuId = details.uuId.isNotEmpty
                        ? details.uuId
                        : widget.orderId;

                    String formattedDate = '';
                    try {
                      final date = DateTime.parse(details.createdAt).toLocal();
                      formattedDate = DateFormat(
                        'dd MMM yyyy • hh:mm a',
                      ).format(date);
                    } catch (e) {
                      formattedDate = details.createdAt;
                    }

                    return Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusFlipCard(
                                      orderStatus: details.orderStatus,
                                      isFood: false,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.receipt_long_outlined,
                                      title: 'Order Summary',
                                      child: Column(
                                        children: [
                                          _buildDetailRow(
                                            'Order ID',
                                            'ORD-${details.id}',
                                            isBold: true,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Date',
                                            formattedDate,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Status',
                                            _getFormattedStatus(
                                              details.orderStatus,
                                            ),
                                            valueColor: _getStatusColor(
                                              details.orderStatus,
                                            ),
                                            isStatusBadge: true,
                                          ),
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Payment Mode',
                                            details.paymentMode,
                                          ),
                                          if (details.slotStartTime != null &&
                                              details.slotEndTime != null) ...[
                                            _buildDivider(),
                                            _buildDetailRow(
                                              'Slot',
                                              '${details.slotStartTime} - ${details.slotEndTime}',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (details.customerNote != null &&
                                        details.customerNote!.trim().isNotEmpty) ...[
                                      _buildCustomerNoteCard(
                                        details.customerNote!,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _buildInfoCard(
                                      icon: Icons.location_on_outlined,
                                      title: 'Delivery Details',
                                      trailingWidget: isDelivered
                                          ? _buildRatingChip(
                                              rating: _deliveryRating,
                                              label: 'Rate Delivery',
                                              onTap: () {
                                                _showDeliveryRatingBottomSheet(
                                                  orderUuId: orderUuId,
                                                  deliveryName: details.deliveryDetails.name,
                                                  isFood: false,
                                                );
                                              },
                                            )
                                          : null,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  details.deliveryDetails.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone_outlined,
                                                size: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                details.deliveryDetails.phone,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.home_outlined,
                                                size: 15,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${details.deliveryDetails.address}, ${details.deliveryDetails.pincode}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.shopping_bag_outlined,
                                      title: 'Items',
                                      child: Column(
                                        children: [
                                          for (
                                            int i = 0;
                                            i < details.items.length;
                                            i++
                                          ) ...[
                                            _buildItemRow(
                                              details.items[i].productName,
                                              '${details.items[i].quantity} ${details.items[i].uomName}',
                                              '₹${details.items[i].totalPrice.toInt()}',
                                              details.items[i].images.isNotEmpty
                                                  ? details.items[i].images.first
                                                  : '',
                                              itemId: details.items[i].id,
                                              orderUuId: orderUuId,
                                              isFood: false,
                                              isDelivered: isDelivered,
                                            ),
                                            if (i < details.items.length - 1)
                                              _buildDivider(),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon:
                                          Icons.account_balance_wallet_outlined,
                                      title: 'Bill Details',
                                      child: Column(
                                        children: [
                                          _buildDetailRow(
                                            'Subtotal',
                                            '₹${details.totalAmount.toInt()}',
                                          ),
                                          if (details.couponDiscount > 0) ...[
                                            _buildDivider(),
                                            _buildDetailRow(
                                              'Discount',
                                              '-₹${details.couponDiscount.toInt()}',
                                              valueColor: const Color(
                                                0xFF16A34A,
                                              ),
                                            ),
                                          ],
                                          _buildDivider(),
                                          _buildDetailRow(
                                            'Delivery Fee',
                                            '₹${details.deliveryCharge.toInt()}',
                                          ),
                                          _buildDivider(
                                            thickness: 1.5,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          _buildDetailRow(
                                            'Total Amount',
                                            '₹${details.grandTotal.toInt()}',
                                            isBold: true,
                                            isTotalRow: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            if (canCancel)
                              _buildCancelButton(
                                onPressed: () {
                                  _showCancelDialog(context, details.uuId);
                                },
                              ),
                          ],
                        ),
                        BlocBuilder<GroceryOrderBloc, OrderState>(
                          builder: (context, buttonState) {
                            if (buttonState is OrderCancelling) {
                              return Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          );
  }

  PreferredSizeWidget _buildAppBar({List<Widget>? actions}) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Order Details',
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          fontSize: 17.sp,
          letterSpacing: -0.2,
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 16,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFF1F5F9),
          height: 1,
        ),
      ),
      actions: actions,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailingWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (trailingWidget != null) trailingWidget,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRatingChip({
    required double rating,
    required String label,
    required VoidCallback onTap,
  }) {
    final isRated = rating > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isRated ? const Color(0xFFFFFBEB) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isRated ? const Color(0xFFFDE68A) : const Color(0xFFFCD34D),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 13,
              color: isRated ? const Color(0xFFD97706) : const Color(0xFFB45309),
            ),
            const SizedBox(width: 3),
            Text(
              isRated ? rating.toStringAsFixed(1) : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isRated ? const Color(0xFFB45309) : const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow({
    required String label,
    required double rating,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          _buildRatingChip(
            rating: rating,
            label: 'Rate Order',
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerNoteCard(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'CUSTOMER NOTE',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFFB45309),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF78350F),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider({double thickness = 1, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: thickness,
        thickness: thickness,
        color: color ?? const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    bool isTotalRow = false,
    bool isStatusBadge = false,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotalRow ? 4 : 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotalRow ? 15 : 13.5,
              color: isTotalRow
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
              fontWeight: isTotalRow
                  ? FontWeight.w700
                  : (isBold ? FontWeight.w600 : FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          if (isStatusBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (valueColor ?? Colors.grey).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (valueColor ?? Colors.grey).withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: valueColor ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? Colors.grey,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: isTotalRow ? 16 : 13.5,
                        color: valueColor ??
                            (isTotalRow
                                ? const Color(0xFF0F172A)
                                : (isBold
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF334155))),
                        fontWeight: isTotalRow
                            ? FontWeight.w800
                            : (isBold ? FontWeight.w700 : FontWeight.w600),
                      ),
                    ),
                  ),
                  if (trailingWidget != null) ...[
                    const SizedBox(width: 8),
                    trailingWidget,
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    String name,
    String qty,
    String price,
    String imageUrl, {
    required int itemId,
    required String orderUuId,
    required bool isFood,
    required bool isDelivered,
  }) {
    final userRating = _itemRatings[itemId];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.fastfood_outlined,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_outlined,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    qty,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (isDelivered) ...[
                const SizedBox(height: 6),
                _buildRatingChip(
                  rating: userRating ?? 0.0,
                  label: 'Rate',
                  onTap: () {
                    _showItemRatingBottomSheet(
                      itemId: itemId,
                      itemName: name,
                      itemImage: imageUrl,
                      itemSubtitle: qty,
                      orderUuId: orderUuId,
                      isFood: isFood,
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showItemRatingBottomSheet({
    required int itemId,
    required String itemName,
    required String itemImage,
    required String itemSubtitle,
    required String orderUuId,
    required bool isFood,
  }) {
    double currentRating = _itemRatings[itemId] ?? 0.0;
    final reviewController = TextEditingController(
      text: _itemReviews[itemId] ?? '',
    );
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rate Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Item Info Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: itemImage.isNotEmpty
                                  ? Image.network(
                                      itemImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.fastfood_outlined,
                                        color: Color(0xFF94A3B8),
                                        size: 18,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fastfood_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 18,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  itemSubtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stars
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starValue = index + 1.0;
                          final isFilled = currentRating >= starValue;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                currentRating = starValue;
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 40,
                                color: isFilled
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _getRatingLabel(currentRating),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: currentRating > 0
                              ? const Color(0xFFD97706)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Review TextField
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Write a review (optional)...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (currentRating > 0 && !isSubmitting)
                            ? () async {
                                setSheetState(() {
                                  isSubmitting = true;
                                });
                                try {
                                  if (isFood) {
                                    final repo = getIt<FoodOrderRepository>();
                                    final res = await repo.submitFoodItemRatings(
                                      orderUuId,
                                      [
                                        FoodProductRatingModel(
                                          orderItemId: itemId,
                                          rating: currentRating,
                                          review:
                                              reviewController.text.trim(),
                                        ),
                                      ],
                                    );
                                    res.fold(
                                      (failure) {
                                        if (mounted) {
                                          SnackbarUtils.showErrorSnackbar(
                                            context,
                                            failure.message,
                                          );
                                        }
                                      },
                                      (_) {
                                        if (mounted) {
                                          setState(() {
                                            _itemRatings[itemId] = currentRating;
                                            _itemReviews[itemId] =
                                                reviewController.text.trim();
                                          });
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                          SnackbarUtils.showSuccessSnackbar(
                                            context,
                                            'Rating submitted successfully!',
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    final repo =
                                        getIt<GroceryOrderRepository>();
                                    final res = await repo.submitProductRatings(
                                      orderUuId,
                                      [
                                        ProductRatingModel(
                                          orderItemId: itemId,
                                          rating: currentRating,
                                          review:
                                              reviewController.text.trim(),
                                        ),
                                      ],
                                    );
                                    res.fold(
                                      (failure) {
                                        if (mounted) {
                                          SnackbarUtils.showErrorSnackbar(
                                            context,
                                            failure.message,
                                          );
                                        }
                                      },
                                      (_) {
                                        if (mounted) {
                                          setState(() {
                                            _itemRatings[itemId] = currentRating;
                                            _itemReviews[itemId] =
                                                reviewController.text.trim();
                                          });
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                          SnackbarUtils.showSuccessSnackbar(
                                            context,
                                            'Rating submitted successfully!',
                                          );
                                        }
                                      },
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final errorMsg = e is ApiException
                                        ? e.message
                                        : e.toString();
                                    SnackbarUtils.showErrorSnackbar(
                                      context,
                                      errorMsg,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setSheetState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFood
                              ? const Color(0xFFFC8019)
                              : const Color(0xFF2E7D32),
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Rating',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOrderRatingBottomSheet({
    required String orderUuId,
    required bool isFood,
    String? vendorName,
    String? deliveryName,
  }) {
    double vendorRatingVal = _vendorRating;
    final vendorReviewCtrl = TextEditingController(text: _vendorReview);
    double deliveryRatingVal = _deliveryRating;
    final deliveryReviewCtrl = TextEditingController(text: _deliveryReview);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            final hasVendor = isFood && (vendorName != null && vendorName.isNotEmpty);
            final hasDelivery = deliveryName != null && deliveryName.isNotEmpty;
            final canSubmit = (isFood
                    ? (vendorRatingVal > 0 || deliveryRatingVal > 0)
                    : deliveryRatingVal > 0) &&
                !isSubmitting;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rate Order Experience',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(sheetContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Vendor Rating Section (Food)
                      if (hasVendor) ...[
                        _buildSectionRatingBox(
                          icon: Icons.restaurant_rounded,
                          iconColor: const Color(0xFFFC8019),
                          title: vendorName,
                          subtitle: 'How was the food & restaurant experience?',
                          rating: vendorRatingVal,
                          onRatingChanged: (r) => setSheetState(() => vendorRatingVal = r),
                          controller: vendorReviewCtrl,
                          hintText: 'Share feedback about the food (optional)...',
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Delivery Rating Section
                      if (hasDelivery) ...[
                        _buildSectionRatingBox(
                          icon: Icons.delivery_dining_rounded,
                          iconColor: const Color(0xFF2563EB),
                          title: deliveryName,
                          subtitle: 'How was your delivery partner experience?',
                          rating: deliveryRatingVal,
                          onRatingChanged: (r) => setSheetState(() => deliveryRatingVal = r),
                          controller: deliveryReviewCtrl,
                          hintText: 'Share feedback about the delivery (optional)...',
                        ),
                        const SizedBox(height: 16),
                      ] else if (!hasVendor) ...[
                        // Generic Order / Delivery rating for Grocery without named partner
                        _buildSectionRatingBox(
                          icon: Icons.local_shipping_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          title: 'Order & Delivery',
                          subtitle: 'How was your order and delivery experience?',
                          rating: deliveryRatingVal,
                          onRatingChanged: (r) => setSheetState(() => deliveryRatingVal = r),
                          controller: deliveryReviewCtrl,
                          hintText: 'Share feedback about your order (optional)...',
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 8),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: canSubmit
                              ? () async {
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    if (isFood) {
                                      final repo = getIt<FoodOrderRepository>();
                                      if (vendorRatingVal > 0) {
                                        await repo.submitFoodVendorRating(
                                          orderUuId,
                                          vendorRatingVal,
                                          vendorReviewCtrl.text.trim(),
                                        );
                                      }
                                      if (deliveryRatingVal > 0) {
                                        await repo.submitFoodDeliveryRating(
                                          orderUuId,
                                          deliveryRatingVal,
                                          deliveryReviewCtrl.text.trim(),
                                        );
                                      }
                                    } else {
                                      final repo = getIt<GroceryOrderRepository>();
                                      if (deliveryRatingVal > 0) {
                                        await repo.submitDeliveryRating(
                                          orderUuId,
                                          deliveryRatingVal,
                                          deliveryReviewCtrl.text.trim(),
                                        );
                                      }
                                    }

                                    if (mounted) {
                                      setState(() {
                                        if (vendorRatingVal > 0) {
                                          _vendorRating = vendorRatingVal;
                                          _vendorReview =
                                              vendorReviewCtrl.text.trim();
                                        }
                                        if (deliveryRatingVal > 0) {
                                          _deliveryRating = deliveryRatingVal;
                                          _deliveryReview =
                                              deliveryReviewCtrl.text.trim();
                                        }
                                      });
                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                      SnackbarUtils.showSuccessSnackbar(
                                        context,
                                        'Order rating submitted successfully!',
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      final errorMsg = e is ApiException
                                          ? e.message
                                          : e.toString();
                                      SnackbarUtils.showErrorSnackbar(
                                        context,
                                        errorMsg,
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setSheetState(() => isSubmitting = false);
                                    }
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFood
                                ? const Color(0xFFFC8019)
                                : const Color(0xFF2E7D32),
                            disabledBackgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Submit Rating',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVendorRatingBottomSheet({
    required String orderUuId,
    required String vendorName,
    String? vendorImage,
  }) {
    double currentRating = _vendorRating;
    final reviewController = TextEditingController(text: _vendorReview);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rate Restaurant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionRatingBox(
                      icon: Icons.restaurant_rounded,
                      iconColor: const Color(0xFFFC8019),
                      title: vendorName,
                      subtitle: 'How was the food & restaurant experience?',
                      rating: currentRating,
                      onRatingChanged: (r) => setSheetState(() => currentRating = r),
                      controller: reviewController,
                      hintText: 'Share feedback about the food (optional)...',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (currentRating > 0 && !isSubmitting)
                            ? () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  final repo = getIt<FoodOrderRepository>();
                                  final res = await repo.submitFoodVendorRating(
                                    orderUuId,
                                    currentRating,
                                    reviewController.text.trim(),
                                  );
                                  res.fold(
                                    (failure) {
                                      if (mounted) {
                                        SnackbarUtils.showErrorSnackbar(
                                          context,
                                          failure.message,
                                        );
                                      }
                                    },
                                    (_) {
                                      if (mounted) {
                                        setState(() {
                                          _vendorRating = currentRating;
                                          _vendorReview = reviewController.text.trim();
                                        });
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                        SnackbarUtils.showSuccessSnackbar(
                                          context,
                                          'Vendor rating submitted successfully!',
                                        );
                                      }
                                    },
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    final errorMsg = e is ApiException
                                        ? e.message
                                        : e.toString();
                                    SnackbarUtils.showErrorSnackbar(
                                      context,
                                      errorMsg,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC8019),
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Rating',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeliveryRatingBottomSheet({
    required String orderUuId,
    required String deliveryName,
    required bool isFood,
  }) {
    double currentRating = _deliveryRating;
    final reviewController = TextEditingController(text: _deliveryReview);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rate Delivery Partner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionRatingBox(
                      icon: Icons.delivery_dining_rounded,
                      iconColor: const Color(0xFF2563EB),
                      title: deliveryName,
                      subtitle: 'How was your delivery partner experience?',
                      rating: currentRating,
                      onRatingChanged: (r) => setSheetState(() => currentRating = r),
                      controller: reviewController,
                      hintText: 'Share feedback about the delivery (optional)...',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (currentRating > 0 && !isSubmitting)
                            ? () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  if (isFood) {
                                    final repo = getIt<FoodOrderRepository>();
                                    final res = await repo.submitFoodDeliveryRating(
                                      orderUuId,
                                      currentRating,
                                      reviewController.text.trim(),
                                    );
                                    res.fold(
                                      (failure) {
                                        if (mounted) {
                                          SnackbarUtils.showErrorSnackbar(
                                            context,
                                            failure.message,
                                          );
                                        }
                                      },
                                      (_) {
                                        if (mounted) {
                                          setState(() {
                                            _deliveryRating = currentRating;
                                            _deliveryReview = reviewController.text.trim();
                                          });
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                          SnackbarUtils.showSuccessSnackbar(
                                            context,
                                            'Delivery rating submitted successfully!',
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    final repo = getIt<GroceryOrderRepository>();
                                    final res = await repo.submitDeliveryRating(
                                      orderUuId,
                                      currentRating,
                                      reviewController.text.trim(),
                                    );
                                    res.fold(
                                      (failure) {
                                        if (mounted) {
                                          SnackbarUtils.showErrorSnackbar(
                                            context,
                                            failure.message,
                                          );
                                        }
                                      },
                                      (_) {
                                        if (mounted) {
                                          setState(() {
                                            _deliveryRating = currentRating;
                                            _deliveryReview = reviewController.text.trim();
                                          });
                                          if (sheetContext.mounted) {
                                            Navigator.pop(sheetContext);
                                          }
                                          SnackbarUtils.showSuccessSnackbar(
                                            context,
                                            'Delivery rating submitted successfully!',
                                          );
                                        }
                                      },
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    final errorMsg = e is ApiException
                                        ? e.message
                                        : e.toString();
                                    SnackbarUtils.showErrorSnackbar(
                                      context,
                                      errorMsg,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFood
                              ? const Color(0xFFFC8019)
                              : const Color(0xFF2E7D32),
                          disabledBackgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Rating',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionRatingBox({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double rating,
    required ValueChanged<double> onRatingChanged,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                final isFilled = rating >= starValue;
                return GestureDetector(
                  onTap: () => onRatingChanged(starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 34,
                      color: isFilled
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _getRatingLabel(rating),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rating > 0
                    ? const Color(0xFFD97706)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5.0) return 'Excellent!';
    if (rating >= 4.0) return 'Very Good!';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    if (rating >= 1.0) return 'Poor';
    return 'Tap a star to rate';
  }

  Widget _buildCancelButton({required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
              backgroundColor: const Color(0xFFFEF2F2),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String uuId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _orderBloc.add(
                CancelOrderEvent(uuId: uuId, note: 'Cancelled by user'),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFoodCancelDialog(BuildContext context, String uuId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logger.d(
                '===== FOOD ORDER UI ===== Cancelling Food Order: uuid=$uuId',
              );
              _foodOrderBloc.add(
                CancelFoodOrderEvent(uuId: uuId, note: 'Cancelled by user'),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PICKED_UP':
        return 'PICKED UP';
      case 'ON_THE_WAY':
        return 'ON THE WAY';
      case 'DEL_ACCEPTED':
        return 'DEL ACCEPTED';
      case 'READY_FOR_PICK_UP':
        return 'READY FOR PICKUP';
      default:
        return status.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    final cleaned = status.toUpperCase().replaceAll(' ', '_');
    switch (cleaned) {
      case 'DELIVERED':
        return const Color(0xFF16A34A);
      case 'PREPARING':
      case 'PROCESSING':
      case 'PICKED_UP':
      case 'ON_THE_WAY':
      case 'DEL_ACCEPTED':
      case 'READY_FOR_PICK_UP':
        return const Color(0xFFEA580C);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      case 'PENDING':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _cleanMessage(String message) {
    String clean = message;
    final prefixes = [
      'Invalid Request: ',
      'Error During Communication: ',
      'Unauthorized: ',
      'Forbidden: ',
      'Not Found: ',
      'Internal Server: ',
      'Unprocessable Content: ',
      'Token Expired: ',
      'Invalid Input: ',
    ];
    for (final prefix in prefixes) {
      if (clean.startsWith(prefix)) {
        clean = clean.replaceFirst(prefix, '');
        break;
      }
    }
    return clean;
  }

  Widget _buildShimmerDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary Shimmer Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.rounded(
                  height: 14,
                  width: 120,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                ...List.generate(5, (index) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerPlaceholder.rounded(
                            height: 12,
                            width: 80,
                            borderRadius: 3,
                          ),
                          ShimmerPlaceholder.rounded(
                            height: 12,
                            width: index == 1 ? 150 : 100,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                      if (index < 4) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Delivery Details Shimmer Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.rounded(
                  height: 14,
                  width: 140,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                ShimmerPlaceholder.rounded(
                  height: 14,
                  width: 100,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                ShimmerPlaceholder.rounded(
                  height: 12,
                  width: 80,
                  borderRadius: 3,
                ),
                const SizedBox(height: 8),
                ShimmerPlaceholder.rounded(
                  height: 12,
                  width: 220,
                  borderRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Items Shimmer Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.rounded(
                  height: 14,
                  width: 80,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 48,
                      width: 48,
                      borderRadius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerPlaceholder.rounded(
                            height: 14,
                            width: 120,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 6),
                          ShimmerPlaceholder.rounded(
                            height: 12,
                            width: 60,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    ShimmerPlaceholder.rounded(
                      height: 14,
                      width: 40,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Bill Details Shimmer Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.rounded(
                  height: 14,
                  width: 100,
                  borderRadius: 4,
                ),
                const SizedBox(height: 16),
                ...List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerPlaceholder.rounded(
                          height: 12,
                          width: 80,
                          borderRadius: 3,
                        ),
                        ShimmerPlaceholder.rounded(
                          height: 12,
                          width: 50,
                          borderRadius: 3,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusFlipCard extends StatefulWidget {
  final String orderStatus;
  final bool isFood;

  const StatusFlipCard({
    super.key,
    required this.orderStatus,
    required this.isFood,
  });

  @override
  State<StatusFlipCard> createState() => _StatusFlipCardState();
}

class _StatusFlipCardState extends State<StatusFlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  int _getStageIndex(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'DEL_ACCEPTED':
      case 'ACCEPTED':
        return 1;
      case 'PROCESSING':
      case 'PREPARING':
        return 2;
      case 'READY_FOR_PICK_UP':
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return 0;
    }
  }

  String _getFormattedStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PICKED_UP':
        return 'PICKED UP';
      case 'ON_THE_WAY':
        return 'ON THE WAY';
      case 'DEL_ACCEPTED':
        return 'DEL ACCEPTED';
      case 'READY_FOR_PICK_UP':
        return 'READY FOR PICKUP';
      default:
        return status.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final transformValue = _animation.value * 3.141592653589793;
          final isFrontSide = transformValue < (3.141592653589793 / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(transformValue),
            alignment: Alignment.center,
            child: isFrontSide
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.141592653589793),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    final activeColor = widget.isFood ? const Color(0xFFFC8019) : Colors.green;
    final stage = _getStageIndex(widget.orderStatus);

    double progress = 0.0;
    IconData statusIcon = Icons.receipt_long_rounded;

    switch (widget.orderStatus.toUpperCase()) {
      case 'PENDING':
        progress = 0.15;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case 'DEL_ACCEPTED':
      case 'ACCEPTED':
        progress = 0.35;
        statusIcon = Icons.thumb_up_alt_rounded;
        break;
      case 'PROCESSING':
      case 'PREPARING':
        progress = 0.55;
        statusIcon = Icons.restaurant_rounded;
        break;
      case 'READY_FOR_PICK_UP':
        progress = 0.75;
        statusIcon = Icons.shopping_bag_rounded;
        break;
      case 'PICKED_UP':
      case 'ON_THE_WAY':
        progress = 0.85;
        statusIcon = Icons.local_shipping_rounded;
        break;
      case 'DELIVERED':
        progress = 1.0;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'CANCELLED':
        progress = 0.0;
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      height: 120.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: widget.orderStatus.toUpperCase() == 'CANCELLED'
                  ? Colors.red.shade50
                  : activeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: widget.orderStatus.toUpperCase() == 'CANCELLED'
                  ? Colors.red
                  : activeColor,
              size: 28.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Order Status',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getFormattedStatus(widget.orderStatus),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: widget.orderStatus.toUpperCase() == 'CANCELLED'
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: Colors.grey,
                size: 20.w,
              ),
              SizedBox(height: 4.h),
              Text(
                'See All\nupdates',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final activeColor = widget.isFood ? const Color(0xFFFC8019) : Colors.green;
    final stage = _getStageIndex(widget.orderStatus);

    return Container(
      height: 120.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14.w,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(5, (index) {
              final isPassed = index <= stage;
              final isCurrent = index == stage;
              final isLast = index == 4;

              String label = '';
              switch (index) {
                case 0:
                  label = 'Placed';
                  break;
                case 1:
                  label = 'Accepted';
                  break;
                case 2:
                  label = 'Preparing';
                  break;
                case 3:
                  label = 'Dispatched';
                  break;
                case 4:
                  label = 'Delivered';
                  break;
              }

              return Expanded(
                flex: isLast ? 0 : 1,
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPassed
                                ? activeColor
                                : Colors.grey.shade200,
                            border: isCurrent
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: isPassed && !isCurrent
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10.w,
                                )
                              : null,
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? activeColor
                                : isPassed
                                    ? Colors.black87
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Container(
                            height: 2.h,
                            color: index < stage
                                ? activeColor
                                : Colors.grey.shade200,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

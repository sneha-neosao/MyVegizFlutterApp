import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../routes/app_route_path.dart';
import '../../../../config/injector_conf.dart';
import '../../bloc/order_bloc.dart';
import '../../bloc/order_event.dart';
import '../../bloc/order_state.dart';
import '../../data/models/order_model.dart';
import '../../../profile/data/models/rating_model.dart';
import '../../data/repository/grocery_order_repo.dart';
import '../../../../core/utils/logger.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late final GroceryOrderBloc _orderBloc;
  final Map<String, double> _orderRatings = {};
  final Set<String> _fetchedOrderIds = {};
  final Set<String> _loadingOrderIds = {};

  Future<void> _fetchRatingForOrder(String orderUuId) async {
    if (_fetchedOrderIds.contains(orderUuId) ||
        _loadingOrderIds.contains(orderUuId))
      return;
    _loadingOrderIds.add(orderUuId);

    final repo = getIt<GroceryOrderRepository>();
    final res = await repo.fetchOrderRatings(orderUuId);

    res.fold(
      (l) {
        _loadingOrderIds.remove(orderUuId);
        logger.e("Error fetching rating for $orderUuId: ${l.message}");
      },
      (r) {
        _loadingOrderIds.remove(orderUuId);
        _fetchedOrderIds.add(orderUuId);
        double rating = 0.0;
        if (r.deliveryRating != null && r.deliveryRating!.rating > 0) {
          rating = r.deliveryRating!.rating;
        } else if (r.productRatings.isNotEmpty) {
          final ratedProducts = r.productRatings
              .where((p) => p.rating > 0)
              .toList();
          if (ratedProducts.isNotEmpty) {
            rating =
                ratedProducts.map((p) => p.rating).reduce((a, b) => a + b) /
                ratedProducts.length;
          }
        }
        if (rating > 0 && mounted) {
          setState(() {
            _orderRatings[orderUuId] = rating;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _orderBloc = getIt<GroceryOrderBloc>()..add(FetchOrdersListEvent());
  }

  @override
  void dispose() {
    _orderBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _orderBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Order History',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          bottom: true,
          top: false,
          child: Column(
            children: [
              // --- Search Bar ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search your grocery orders',
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // --- Orders List ---
              Expanded(
                child: BlocBuilder<GroceryOrderBloc, OrderState>(
                  builder: (context, state) {
                    if (state is OrderListLoading || state is OrderInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                        ),
                      );
                    } else if (state is OrderListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.message,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  _orderBloc.add(FetchOrdersListEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is OrderListLoaded) {
                      final orders = state.orders;
                      if (orders.isEmpty) {
                        return const Center(child: Text("No orders found."));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildOrderCard(context, orders[index]),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderListItemModel order) {
    String formattedDate = '';
    try {
      final date = DateTime.parse(order.createdAt);
      formattedDate = DateFormat('dd MMM, hh:mm a').format(date);
    } catch (e) {
      formattedDate = order.createdAt;
    }

    final bool isDelivered = order.orderStatus.toUpperCase() == 'DELIVERED';

    if (isDelivered &&
        order.rating == 0 &&
        !_fetchedOrderIds.contains(order.uuId)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fetchRatingForOrder(order.uuId),
      );
    }

    final displayRating = _orderRatings[order.uuId] ?? order.rating;

    return InkWell(
      onTap: () => context.push(AppRoutePath.orderDetails, extra: order.uuId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? const Color(0xFFE8F5E9)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDelivered ? Icons.check : Icons.local_shipping_outlined,
                    color: isDelivered ? const Color(0xFF4CAF50) : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFormattedStatus(order.orderStatus),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${order.grandTotal.toInt()} • $formattedDate',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 20),

            // Item List (Together inside one card)
            if (order.items.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 16),
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildItemThumb(
                        item.images.isNotEmpty ? item.images.first : '',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x ${item.quantity}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],

            // Rating Submitted Card (Show only for delivered orders with rating)
            if (isDelivered && displayRating > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    RatingBarIndicator(
                      rating: displayRating.toDouble(),
                      itemCount: 5,
                      itemSize: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${displayRating.toInt()}/5',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildItemThumb(String url) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image, color: Colors.grey),
              )
            : const Icon(Icons.image, color: Colors.grey),
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
}

class RatingBarIndicator extends StatelessWidget {
  final double rating;
  final int itemCount;
  final double itemSize;

  const RatingBarIndicator({
    super.key,
    required this.rating,
    this.itemCount = 5,
    this.itemSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        IconData icon;
        Color color;
        if (index < rating.floor()) {
          icon = Icons.star_rounded;
          color = const Color(0xFFFFC107);
        } else if (index < rating && rating - index >= 0.5) {
          icon = Icons.star_half_rounded;
          color = const Color(0xFFFFC107);
        } else {
          icon = Icons.star_outline_rounded;
          color = Colors.grey[300]!;
        }
        return Icon(icon, color: color, size: itemSize);
      }),
    );
  }
}

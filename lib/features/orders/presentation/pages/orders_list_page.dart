import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../config/injector_conf.dart';
import '../../bloc/order_bloc.dart';
import '../../bloc/order_event.dart';
import '../../bloc/order_state.dart';
import '../../bloc/food_order_bloc.dart';
import '../../bloc/food_order_event.dart';
import '../../bloc/food_order_state.dart';
import '../../data/models/order_model.dart';
import '../../data/models/food_order_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/logger.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../mainCetegories/bloc/mainCategories_bloc.dart';
import '../../../mainCetegories/bloc/mainCategories_event.dart';
import '../../../mainCetegories/bloc/mainCategories_state.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  late final GroceryOrderBloc _orderBloc;
  late final FoodOrderBloc _foodOrderBloc;
  late final MainCategoriesBloc _mainCategoriesBloc;
  String _selectedCategory = 'food'; // Default to Food

  @override
  void initState() {
    super.initState();
    _mainCategoriesBloc = getIt<MainCategoriesBloc>()..add(FetchMainCategories());
    _orderBloc = getIt<GroceryOrderBloc>()..add(FetchOrdersListEvent());
    _foodOrderBloc = getIt<FoodOrderBloc>()..add(FetchFoodOrdersListEvent());
  }

  @override
  void dispose() {
    _mainCategoriesBloc.close();
    _orderBloc.close();
    _foodOrderBloc.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    logger.i(
      '🔄 OrdersListPage: Pull-to-refresh triggered — fetching latest order data',
    );
    _mainCategoriesBloc.add(FetchMainCategories());
    _orderBloc.add(FetchOrdersListEvent());
    _foodOrderBloc.add(FetchFoodOrdersListEvent());

    final orderFuture = _orderBloc.stream.firstWhere(
      (state) => state is OrderListLoaded || state is OrderListError,
    );
    final foodFuture = _foodOrderBloc.stream.firstWhere(
      (state) => state is FoodOrderListLoaded || state is FoodOrderListError,
    );
    await Future.wait([
      orderFuture,
      foodFuture,
    ]).timeout(const Duration(seconds: 10), onTimeout: () => []);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _orderBloc),
        BlocProvider.value(value: _foodOrderBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<GroceryOrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderListError) {
                if (state.message.contains('Unauthorized') ||
                    state.message.contains('401') ||
                    state.message.contains('Token expired')) {
                  SecureStorage.clearAll().then((_) {
                    if (context.mounted) {
                      context.go(AppRoutePath.login);
                    }
                  });
                }
              }
            },
          ),
          BlocListener<FoodOrderBloc, FoodOrderState>(
            listener: (context, state) {
              if (state is FoodOrderListError) {
                if (state.message.contains('Unauthorized') ||
                    state.message.contains('401') ||
                    state.message.contains('Token expired')) {
                  SecureStorage.clearAll().then((_) {
                    if (context.mounted) {
                      context.go(AppRoutePath.login);
                    }
                  });
                }
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'My Orders',
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
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            bottom: true,
            top: false,
            child: BlocBuilder<MainCategoriesBloc, MainCategoriesState>(
              bloc: _mainCategoriesBloc,
              builder: (context, catState) {
                if (catState is MainCategoriesLoading ||
                    catState is MainCategoriesInitial) {
                  return Column(
                    children: [
                      _buildCategorySwitchShimmer(),
                      Expanded(
                        child: _buildOrderShimmerList(isFood: true),
                      ),
                    ],
                  );
                }

                bool hasFood = true;
                bool hasVegetables = true;

                if (catState is MainCategoriesLoaded) {
                  final activeCategories = (catState.data.data ?? [])
                      .where((c) => c.isActive)
                      .toList();
                  hasFood = activeCategories
                      .any((c) => c.slug.trim().toLowerCase() == 'food');
                  hasVegetables = activeCategories
                      .any((c) => c.slug.trim().toLowerCase() != 'food');
                }

                final bool showTabs = hasFood && hasVegetables;
                final String effectiveCategory = (!hasFood && hasVegetables)
                    ? 'grocery-vegetables'
                    : (hasFood && !hasVegetables)
                        ? 'food'
                        : _selectedCategory;

                final bool isFood = effectiveCategory == 'food';

                return Column(
                  children: [
                    if (showTabs) _buildCategorySwitch(),
                    Expanded(
                      child: RefreshIndicator(
                        color: isFood
                            ? const Color(0xFFFC8019)
                            : Colors.green,
                        onRefresh: _onRefresh,
                        child: isFood
                            ? BlocBuilder<FoodOrderBloc, FoodOrderState>(
                                builder: (context, state) {
                                  logger.d(
                                    '===== FOOD ORDER UI ===== FoodOrderState: $state',
                                  );
                                  if (state is FoodOrderListLoading ||
                                      state is FoodOrderInitial) {
                                    return _buildOrderShimmerList(isFood: true);
                                  } else if (state is FoodOrderListError) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.6,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              state.message,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                            ElevatedButton(
                                              onPressed: () {
                                                logger.d(
                                                  '===== FOOD ORDER UI ===== Retrying Fetch Food Orders',
                                                );
                                                _foodOrderBloc.add(
                                                  FetchFoodOrdersListEvent(),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                  vertical: 12.h,
                                                ),
                                              ),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else if (state is FoodOrderListLoaded) {
                                    final orders = state.orders;
                                    logger.d(
                                      '===== FOOD ORDER UI ===== Rendered Food Orders: count=${orders.length}',
                                    );
                                    if (orders.isEmpty) {
                                      return SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: Container(
                                          height:
                                              MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.6,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 64.w,
                                                color: Colors.grey.shade300,
                                              ),
                                              SizedBox(height: 16.h),
                                              Text(
                                                "No Food orders found.",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.all(16.w),
                                      itemCount: orders.length,
                                      itemBuilder: (context, index) {
                                        final order = orders[index];
                                        return _buildFoodOrderCard(
                                              context,
                                              order,
                                            )
                                            .animate()
                                            .fadeIn(delay: (40 * index).ms)
                                            .slideY(begin: 0.08, end: 0);
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              )
                            : BlocBuilder<GroceryOrderBloc, OrderState>(
                                builder: (context, state) {
                                  if (state is OrderListLoading ||
                                      state is OrderInitial) {
                                    return _buildOrderShimmerList(
                                      isFood: false,
                                    );
                                  } else if (state is OrderListError) {
                                    return SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.6,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              state.message,
                                              style: const TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            SizedBox(height: 16.h),
                                            ElevatedButton(
                                              onPressed:
                                                  () => _orderBloc.add(
                                                    FetchOrdersListEvent(),
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                  vertical: 12.h,
                                                ),
                                              ),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else if (state is OrderListLoaded) {
                                    final filteredOrders = state.orders
                                        .where(
                                          (o) =>
                                              o.mainCategorySlug ==
                                                  effectiveCategory ||
                                              effectiveCategory ==
                                                  'grocery-vegetables' ||
                                              o.mainCategorySlug.isEmpty,
                                        )
                                        .toList();

                                    if (filteredOrders.isEmpty) {
                                      return SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: Container(
                                          height:
                                              MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.6,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 64.w,
                                                color: Colors.grey.shade300,
                                              ),
                                              SizedBox(height: 16.h),
                                              Text(
                                                "No $effectiveCategory orders found.",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.all(16.w),
                                      itemCount: filteredOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = filteredOrders[index];
                                        return _buildOrderCard(context, order)
                                            .animate()
                                            .fadeIn(delay: (40 * index).ms)
                                            .slideY(begin: 0.08, end: 0);
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySwitchShimmer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShimmerPlaceholder.rounded(
              height: 38.h,
              borderRadius: 10.w,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ShimmerPlaceholder.rounded(
              height: 38.h,
              borderRadius: 10.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySwitch() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSwitchOption(
              label: 'Food',
              slug: 'food',
              isSelected: _selectedCategory == 'food',
            ),
          ),
          Expanded(
            child: _buildSwitchOption(
              label: 'Grocery & Vegetables',
              slug: 'grocery-vegetables',
              isSelected: _selectedCategory == 'grocery-vegetables',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchOption({
    required String label,
    required String slug,
    required bool isSelected,
  }) {
    final selectedColor = slug == 'food' ? const Color(0xFFFC8019) : Colors.green;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10.w),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderListItemModel order) {
    String formattedDate = '';
    try {
      final date = DateTime.parse(order.createdAt).toLocal();
      formattedDate = DateFormat('dd MMM yyyy • hh:mm a').format(date);
    } catch (e) {
      formattedDate = order.createdAt;
    }

    return Card(
      color: const Color(0xFFF1F8E9),
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
      child: InkWell(
        onTap: () async {
          await context.push(AppRoutePath.orderDetails, extra: order.uuId);
          // Refresh list when returning, in case order was cancelled
          _orderBloc.add(FetchOrdersListEvent());
        },
        borderRadius: BorderRadius.circular(12.w),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ORD-${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        order.orderStatus,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getFormattedStatus(order.orderStatus),
                      style: TextStyle(
                        color: _getStatusColor(order.orderStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.w,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalItems} Items',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₹${order.grandTotal.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              if (order.isRated && order.rating > 0) ...[
                SizedBox(height: 8.h),
                const Divider(height: 1),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: order.rating,
                      itemCount: 5,
                      itemSize: 16.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${order.rating.toStringAsFixed(1)}/5',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodOrderCard(
    BuildContext context,
    FoodOrderListItemModel order,
  ) {
    String formattedDate = '';
    try {
      final date = DateTime.parse(order.createdAt).toLocal();
      formattedDate = DateFormat('dd MMM yyyy • hh:mm a').format(date);
    } catch (e) {
      formattedDate = order.createdAt;
    }

    return Card(
      color: const Color(0xFFFFF5EE),
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
      child: InkWell(
        onTap: () async {
          logger.d(
            '===== FOOD ORDER UI ===== Tapped Food Order Detail: id=${order.id}, uuid=${order.uuId}',
          );
          await context.push(
            AppRoutePath.orderDetails,
            extra: {'orderId': order.uuId, 'isFood': true},
          );
          // Refresh list when returning, in case order was cancelled
          logger.d(
            '===== FOOD ORDER UI ===== Returning from Food Details Page, refreshing list',
          );
          _foodOrderBloc.add(FetchFoodOrdersListEvent());
        },
        borderRadius: BorderRadius.circular(12.w),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.vendor?.entityName ?? 'Food Order #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        order.orderStatus,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getFormattedStatus(order.orderStatus),
                      style: TextStyle(
                        color: _getStatusColor(order.orderStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.w,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalItems} Items',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₹${order.grandTotal.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              if (order.isRated && order.rating > 0) ...[
                SizedBox(height: 8.h),
                const Divider(height: 1),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: order.rating,
                      itemCount: 5,
                      itemSize: 16.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${order.rating.toStringAsFixed(1)}/5',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
        return Colors.green;
      case 'PREPARING':
      case 'PROCESSING':
      case 'PICKED_UP':
      case 'ON_THE_WAY':
      case 'DEL_ACCEPTED':
      case 'READY_FOR_PICK_UP':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'PENDING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderShimmerList({required bool isFood}) {
    final cardColor = isFood ? const Color(0xFFFFF5EE) : const Color(0xFFF1F8E9);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          color: cardColor,
          margin: EdgeInsets.only(bottom: 16.h),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 18.h,
                      width: 140.w,
                      borderRadius: 4.w,
                    ),
                    ShimmerPlaceholder.rounded(
                      height: 22.h,
                      width: 80.w,
                      borderRadius: 8.w,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    ShimmerPlaceholder.circular(
                      width: 14.w,
                      height: 14.w,
                    ),
                    SizedBox(width: 6.w),
                    ShimmerPlaceholder.rounded(
                      height: 14.h,
                      width: 160.w,
                      borderRadius: 4.w,
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerPlaceholder.rounded(
                      height: 16.h,
                      width: 60.w,
                      borderRadius: 4.w,
                    ),
                    ShimmerPlaceholder.rounded(
                      height: 18.h,
                      width: 50.w,
                      borderRadius: 4.w,
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

import 'package:my_vegiz_flutter/features/orders/data/models/food_order_model.dart';
import 'package:my_vegiz_flutter/features/orders/data/models/food_rating_model.dart';
import 'package:my_vegiz_flutter/features/orders/data/models/order_model.dart';
import 'package:my_vegiz_flutter/features/orders/data/repository/food_order_repo.dart';
import 'package:my_vegiz_flutter/features/orders/data/repository/grocery_order_repo.dart';
import 'package:my_vegiz_flutter/features/profile/data/models/rating_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/injector_conf.dart';
import '../../../../core/utils/logger.dart';
import '../../widgets/animated_delivery_boy_with_rating.dart';
import '../../../../routes/app_route_path.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/api/api/api_exception.dart';

class RatingScreen extends StatefulWidget {
  final String orderId;
  final bool isFood;
  const RatingScreen({super.key, required this.orderId, this.isFood = false});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _deliveryRating = 0;
  final String _deliveryFeedback = "";
  final TextEditingController _deliveryFeedbackController =
      TextEditingController();
  double _vendorRating = 0;
  final TextEditingController _vendorFeedbackController =
      TextEditingController();
  String? _vendorName;
  String? _vendorImage;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _deliveryBoyName;
  bool _isDelivered = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.isFood) {
      final repo = getIt<FoodOrderRepository>();

      // Fetch Order Details and Existing Ratings in parallel
      final results = await Future.wait([
        repo.getFoodOrderDetails(widget.orderId),
        repo.fetchFoodOrderRatings(widget.orderId),
      ]);

      final orderResult = results[0];
      final ratingsResult = results[1];

      FoodOrderDetailsModel? orderDetails;
      FoodOrderRatingsResponseModel? existingRatings;

      orderResult.fold(
        (l) => logger.e(
          "RatingScreen: Failed to fetch food order details: ${l.message}",
        ),
        (r) => orderDetails = r as FoodOrderDetailsModel,
      );

      ratingsResult.fold(
        (l) => logger.e(
          "RatingScreen: Failed to fetch existing food ratings: ${l.message}",
        ),
        (r) => existingRatings = r as FoodOrderRatingsResponseModel,
      );

      if (mounted) {
        bool hasExistingRating = false;
        if (existingRatings != null) {
          if ((existingRatings!.deliveryRating != null &&
                  existingRatings!.deliveryRating!.rating > 0) ||
              (existingRatings!.vendorRating != null &&
                  existingRatings!.vendorRating!.rating > 0) ||
              existingRatings!.productRatings.any((p) => p.rating > 0)) {
            hasExistingRating = true;
          }
        }

        if (hasExistingRating) {
          setState(() {
            _isDelivered = false;
            _errorMessage = "You have already rated this order.";
            _isLoading = false;
          });
          return;
        }

        if (orderDetails != null) {
          final bool isOrderDelivered =
              orderDetails!.orderStatus.toUpperCase() == 'DELIVERED';

          if (isOrderDelivered) {
            setState(() {
              _isDelivered = true;
              _errorMessage = null;
              _deliveryBoyName =
                  (orderDetails!.deliveryDetails?.name.isNotEmpty ?? false)
                  ? orderDetails!.deliveryDetails!.name
                  : null;
              _vendorName = orderDetails!.vendor?.entityName;
              _vendorImage = orderDetails!.vendor?.entityImage;
              _vendorRating = 0.0;
              _vendorFeedbackController.clear();
              _items = orderDetails!.items.map((item) {
                return {
                  'id': item.itemId,
                  'order_uu_id': orderDetails!.uuId,
                  'name': item.vendorItemName,
                  'image': item.images.isNotEmpty ? item.images.first : '',
                  'rating': 0.0,
                  'feedback': '',
                  'controller': TextEditingController(),
                };
              }).toList();
              _isLoading = false;
            });
          } else {
            await _loadPreviousDeliveredFoodProducts();
          }
        } else {
          await _loadPreviousDeliveredFoodProducts();
        }
      }
    } else {
      final repo = getIt<GroceryOrderRepository>();

      // Fetch Order Details and Existing Ratings in parallel
      final results = await Future.wait([
        repo.getOrderDetails(widget.orderId),
        repo.fetchOrderRatings(widget.orderId),
      ]);

      final orderResult = results[0];
      final ratingsResult = results[1];

      OrderDetailsModel? orderDetails;
      // ignore: unused_local_variable
      OrderRatingsResponseModel? existingRatings;

      orderResult.fold(
        (l) => logger.e(
          "RatingScreen: Failed to fetch order details: ${l.message}",
        ),
        (r) => orderDetails = r as OrderDetailsModel,
      );

      ratingsResult.fold(
        (l) => logger.e(
          "RatingScreen: Failed to fetch existing ratings: ${l.message}",
        ),
        (r) => existingRatings = r as OrderRatingsResponseModel,
      );

      if (mounted) {
        bool hasExistingRating = false;
        if (existingRatings != null) {
          if (existingRatings!.deliveryRating != null &&
              existingRatings!.deliveryRating!.rating > 0) {
            hasExistingRating = true;
          } else if (existingRatings!.productRatings.any((p) => p.rating > 0)) {
            hasExistingRating = true;
          }
        }

        if (hasExistingRating) {
          setState(() {
            _isDelivered = false;
            _errorMessage = "You have already rated this order.";
            _isLoading = false;
          });
          return;
        }

        if (orderDetails != null) {
          final bool isOrderDelivered =
              orderDetails!.orderStatus.toUpperCase() == 'DELIVERED';

          if (isOrderDelivered) {
            setState(() {
              _isDelivered = true;
              _errorMessage = null;
              _deliveryBoyName = orderDetails!.deliveryDetails.name.isNotEmpty
                  ? orderDetails!.deliveryDetails.name
                  : null;
              _items = orderDetails!.items.map((item) {
                return {
                  'id': item.id,
                  'order_uu_id':
                      orderDetails!.uuId, // Track order ID for each item
                  'name': item.productName,
                  'image': item.images.isNotEmpty ? item.images.first : '',
                  'rating': 0.0,
                  'feedback': '',
                  'controller': TextEditingController(),
                };
              }).toList();
              _isLoading = false;
            });
          } else {
            // If current order not delivered, load all previously delivered products
            await _loadPreviousDeliveredProducts();
          }
        } else {
          await _loadPreviousDeliveredProducts();
        }
      }
    }
  }

  Future<void> _loadPreviousDeliveredProducts() async {
    final repo = getIt<GroceryOrderRepository>();
    final res = await repo.getOrdersList();

    await res.fold(
      (l) async {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Failed to fetch previous orders: ${l.message}";
          });
        }
      },
      (r) async {
        final candidateOrders = r.orders
            .where((o) => o.orderStatus.toUpperCase() == 'DELIVERED')
            .toList();

        final List<Map<String, dynamic>> allItems = [];

        // Check ratings for all candidate orders in parallel
        final checkFutures = candidateOrders.map((order) async {
          final ratingRes = await repo.fetchOrderRatings(order.uuId);
          bool isOrderRated = false;
          ratingRes.fold(
            (l) => logger.e(
              "Failed to check rating for order ${order.uuId}: ${l.message}",
            ),
            (ratingsResponse) {
              if (ratingsResponse.deliveryRating != null &&
                  ratingsResponse.deliveryRating!.rating > 0) {
                isOrderRated = true;
              } else if (ratingsResponse.productRatings.any(
                (p) => p.rating > 0,
              )) {
                isOrderRated = true;
              }
            },
          );
          return MapEntry(order, isOrderRated);
        });

        final results = await Future.wait(checkFutures);
        final unratedOrders = results
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

        for (var order in unratedOrders) {
          for (var item in order.items) {
            allItems.add({
              'id': item.id,
              'order_uu_id': order.uuId,
              'name': item.productName,
              'image': item.images.isNotEmpty ? item.images.first : '',
              'rating': 0.0,
              'feedback': '',
              'controller': TextEditingController(),
            });
          }
        }

        if (mounted) {
          setState(() {
            _items = allItems;
            if (allItems.isNotEmpty) {
              _isDelivered = true;
              _errorMessage = null;
              // Hide delivery boy section if rating generic items
              _deliveryBoyName = null;
            } else {
              _isDelivered = false;
              _errorMessage = "No delivered products found to rate.";
            }
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _loadPreviousDeliveredFoodProducts() async {
    final repo = getIt<FoodOrderRepository>();
    final res = await repo.getFoodOrdersList();

    await res.fold(
      (l) async {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                "Failed to fetch previous food orders: ${l.message}";
          });
        }
      },
      (r) async {
        final candidateOrders = r.orders
            .where((o) => o.orderStatus.toUpperCase() == 'DELIVERED')
            .toList();

        // Check ratings for all candidate orders in parallel
        final checkFutures = candidateOrders.map((order) async {
          final ratingRes = await repo.fetchFoodOrderRatings(order.uuId);
          bool isOrderRated = false;
          ratingRes.fold(
            (l) => logger.e(
              "Failed to check rating for food order ${order.uuId}: ${l.message}",
            ),
            (ratingsResponse) {
              if ((ratingsResponse.deliveryRating != null &&
                      ratingsResponse.deliveryRating!.rating > 0) ||
                  (ratingsResponse.vendorRating != null &&
                      ratingsResponse.vendorRating!.rating > 0) ||
                  ratingsResponse.productRatings.any((p) => p.rating > 0)) {
                isOrderRated = true;
              }
            },
          );
          return MapEntry(order, isOrderRated);
        });

        final results = await Future.wait(checkFutures);
        final unratedOrders = results
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

        // Sort unrated orders by date descending to find the latest
        unratedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (unratedOrders.isNotEmpty) {
          final latestUnratedOrder = unratedOrders.first;
          final detailsRes = await repo.getFoodOrderDetails(
            latestUnratedOrder.uuId,
          );
          detailsRes.fold(
            (l) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      "Failed to fetch details for unrated food order: ${l.message}";
                });
              }
            },
            (details) {
              if (mounted) {
                setState(() {
                  _deliveryBoyName =
                      (details.deliveryDetails?.name.isNotEmpty ?? false)
                      ? details.deliveryDetails!.name
                      : null;
                  _vendorName = details.vendor?.entityName;
                  _vendorImage = details.vendor?.entityImage;
                  _vendorRating = 0.0;
                  _vendorFeedbackController.clear();
                  _items = details.items.map((item) {
                    return {
                      'id': item.itemId,
                      'order_uu_id': details.uuId,
                      'name': item.vendorItemName,
                      'image': item.images.isNotEmpty ? item.images.first : '',
                      'rating': 0.0,
                      'feedback': '',
                      'controller': TextEditingController(),
                    };
                  }).toList();
                  _isDelivered = true;
                  _errorMessage = null;
                  _isLoading = false;
                });
              }
            },
          );
        } else {
          if (mounted) {
            setState(() {
              _isDelivered = false;
              _errorMessage = "No delivered food products found to rate.";
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _deliveryFeedbackController.dispose();
    _vendorFeedbackController.dispose();
    for (var item in _items) {
      (item['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  bool get _isSubmitEnabled {
    if (_isSubmitting) return false;
    if (_deliveryRating > 0) return true;
    if (widget.isFood && _vendorRating > 0) return true;
    return _items.any((item) => item['rating'] > 0);
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    if (widget.isFood) {
      final repo = getIt<FoodOrderRepository>();

      // Group product ratings
      final List<FoodProductRatingModel> itemRatings = [];
      for (var item in _items) {
        if (item['rating'] > 0) {
          itemRatings.add(
            FoodProductRatingModel(
              orderItemId: item['id'],
              rating: item['rating'],
              review: item['feedback'],
            ),
          );
        }
      }

      try {
        // Submit food items rating
        if (itemRatings.isNotEmpty) {
          await repo.submitFoodItemRatings(widget.orderId, itemRatings);
        }

        // Submit delivery rating (if given)
        if (_deliveryBoyName != null &&
            _deliveryBoyName!.isNotEmpty &&
            _deliveryRating > 0) {
          await repo.submitFoodDeliveryRating(
            widget.orderId,
            _deliveryRating,
            _deliveryFeedbackController.text,
          );
        }

        // Submit vendor rating (if given)
        if (_vendorName != null &&
            _vendorName!.isNotEmpty &&
            _vendorRating > 0) {
          await repo.submitFoodVendorRating(
            widget.orderId,
            _vendorRating,
            _vendorFeedbackController.text,
          );
        }

        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessPopup();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          final errorMsg = e is ApiException ? e.message : e.toString();
          SnackbarUtils.showErrorSnackbar(context, errorMsg);
        }
      }
    } else {
      final repo = getIt<GroceryOrderRepository>();

      // Group product ratings by their respective order UUIDs
      final Map<String, List<ProductRatingModel>> ratingsByOrder = {};

      for (var item in _items) {
        if (item['rating'] > 0) {
          final String orderId = item['order_uu_id'];
          ratingsByOrder.putIfAbsent(orderId, () => []);
          ratingsByOrder[orderId]!.add(
            ProductRatingModel(
              orderItemId: item['id'],
              rating: item['rating'],
              review: item['feedback'],
            ),
          );
        }
      }

      try {
        // Submit product ratings for each order
        for (var entry in ratingsByOrder.entries) {
          await repo.submitProductRatings(entry.key, entry.value);
        }

        // Submit Delivery Rating ONLY if we are rating a specific delivery boy
        // (This happens when we are rating the latest delivered order)
        if (_deliveryBoyName != null &&
            _deliveryBoyName!.isNotEmpty &&
            _deliveryRating > 0) {
          await repo.submitDeliveryRating(
            widget.orderId,
            _deliveryRating,
            _deliveryFeedbackController.text.isNotEmpty
                ? _deliveryFeedbackController.text
                : _deliveryFeedback,
          );
        }

        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessPopup();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          final errorMsg = e is ApiException ? e.message : e.toString();
          SnackbarUtils.showErrorSnackbar(context, errorMsg);
        }
      }
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessPopup(),
    ).then((_) {
      if (mounted) {
        // Navigate to Order History instead of popping back to profile
        context.pushReplacement(AppRoutePath.orderHistory);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(title: const Text('Rate your experience')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (!_isDelivered) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: const Text('Invalid Request'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? "This order cannot be rated yet.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Rate your experience',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Delivery Experience Section ---
                  if (_deliveryBoyName != null &&
                      _deliveryBoyName!.isNotEmpty) ...[
                    _buildDeliveryCard(),
                    const SizedBox(height: 24),
                  ],

                  // --- Vendor (Restaurant) Section ---
                  if (widget.isFood &&
                      _vendorName != null &&
                      _vendorName!.isNotEmpty) ...[
                    _buildVendorCard(),
                    const SizedBox(height: 24),
                  ],

                  if (_items.isNotEmpty) ...[
                    Text(
                      _deliveryBoyName != null
                          ? 'Please tell us about items in your order'
                          : 'Rate your previous purchases',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    // --- Items List ---
                    ..._items.map((item) => _buildItemCard(item)),
                  ],
                ],
              ),
            ),
          ),

          // --- Submit Button ---
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - Rating Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How was your delivery experience?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _deliveryBoyName != null
                          ? 'with $_deliveryBoyName'
                          : 'with Delivery Partner',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    _StarRating(
                      rating: _deliveryRating,
                      size: 32,
                      onRatingChanged: (rating) {
                        setState(() => _deliveryRating = rating);
                      },
                    ),
                  ],
                ),
              ),

              // Right side - Animated Delivery Boy (Blinkit Style)
              SizedBox(
                width: 100,
                height: 100,
                child: BlinkitStyleDeliveryBoy(rating: _deliveryRating),
              ),
            ],
          ),
          // if (_deliveryRating > 0)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 16),
          //     child: TextField(
          //       onChanged: (val) => _deliveryFeedback = val,
          //       maxLines: 3,
          //       decoration: InputDecoration(
          //         hintText: 'Tell us about the delivery',
          //         hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          //         filled: true,
          //         fillColor: const Color(0xFFFDFDFD),
          //         border: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(12),
          //           borderSide: BorderSide(color: Colors.grey.shade200),
          //         ),
          //         enabledBorder: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(12),
          //           borderSide: BorderSide(color: Colors.grey.shade200),
          //         ),
          //       ),
          //       controller: _deliveryFeedbackController,
          //     ).animate().fadeIn().slideY(begin: 0.1, end: 0),
          //   ),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0).fadeIn();
  }

  Widget _buildVendorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - Rating Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How was the restaurant experience?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'with $_vendorName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    _StarRating(
                      rating: _vendorRating,
                      size: 32,
                      onRatingChanged: (rating) {
                        setState(() => _vendorRating = rating);
                      },
                    ),
                  ],
                ),
              ),

              // Right side - Vendor Logo
              if (_vendorImage != null && _vendorImage!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _vendorImage!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
          if (_vendorRating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _vendorFeedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Tell us about the food quality and restaurant service',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFFDFDFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            ),
        ],
      ),
    ).animate().slideY(begin: 0.1, end: 0).fadeIn();
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final bool hasRating = item['rating'] > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['image'],
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 60,
                    width: 60,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _StarRating(
                      rating: item['rating'],
                      size: 28,
                      onRatingChanged: (rating) {
                        setState(() => item['rating'] = rating);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasRating)
            Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  controller: item['controller'] as TextEditingController,
                  onChanged: (val) => item['feedback'] = val,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tell us about your experience',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFFDFDFD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                // const SizedBox(height: 12),
                // Align(
                //   alignment: Alignment.centerLeft,
                //   child: TextButton.icon(
                //     onPressed: () {},
                //     icon: const Icon(Icons.camera_alt_outlined, size: 20),
                //     label: const Text('Add photos'),
                //     style: TextButton.styleFrom(
                //       foregroundColor: Colors.grey[600],
                //       backgroundColor: Colors.grey[100],
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 16,
                //         vertical: 8,
                //       ),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha: 0.05),
      //       blurRadius: 10,
      //       offset: const Offset(0, -4),
      //     ),
      //   ],
      // ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitEnabled ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Function(double) onRatingChanged;

  const _StarRating({
    required this.rating,
    this.size = 32,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: index < rating
                  ? const Color(0xFFFFC107)
                  : Colors.grey[300],
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

class _SuccessPopup extends StatefulWidget {
  @override
  State<_SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<_SuccessPopup> {
  @override
  void initState() {
    super.initState();
    // Auto-close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 80,
              color: Color(0xFFFFC107),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'RATING SUBMITTED',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thank you for your feedback',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See you again soon!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/bloc/restaurant_details_bloc.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/bloc/restaurant_details_event.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/bloc/restaurant_details_state.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/data/models/vendor_item_details_model.dart';
import 'package:my_vegiz_flutter/routes/app_route_path.dart';

import '../../cart/data/cart_data.dart';
import '../../../core/storage/food_cart_db.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/food_cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import '../../../widgets/shimmer_placeholder.dart';
import '../../food_category/widget/veg_nonveg_filter.dart';

import 'package:my_vegiz_flutter/features/cart/presentation/widgets/cart_conflict_dialog.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/widget/customization_bottom_sheet.dart';
import '../../../core/utils/network_images.dart';

class VenderItemDetailsCard extends StatefulWidget {
  final VendorItemDetailsData item;
  final bool isDeliverable;
  final ScrollController? scrollController;

  const VenderItemDetailsCard({
    super.key,
    required this.item,
    this.isDeliverable = true,
    this.scrollController,
  });

  static void show(BuildContext context, int itemId, bool isDeliverable) {
    final loc = locationService.locationNotifier.value;
    showDialog(
      context: context,
      useSafeArea: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (modalContext) {
        return Dialog(
          alignment: Alignment.center,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider(
            create: (context) => getIt<RestaurantDetailsBloc>()
              ..add(FetchVendorItemDetailsEvent(
                vendorItemId: itemId,
                lat: loc?.lat,
                lng: loc?.lng,
              )),
            child: BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
              builder: (context, state) {
                if (state.isItemDetailsLoading) {
                  return Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 450),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerPlaceholder.rounded(
                          height: 220,
                          width: double.infinity,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerPlaceholder.rounded(height: 24, width: 150),
                              const SizedBox(height: 12),
                              ShimmerPlaceholder.rounded(height: 16, width: 250),
                              const SizedBox(height: 8),
                              ShimmerPlaceholder.rounded(height: 16, width: 200),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state.itemDetailsError != null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.itemDetailsError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } else if (state.itemDetailsResponse?.data != null) {
                  final item = state.itemDetailsResponse!.data!;
                  return VenderItemDetailsCard(
                    item: item,
                    isDeliverable: isDeliverable,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  State<VenderItemDetailsCard> createState() => _VenderItemDetailsCardState();
}

class _VenderItemDetailsCardState extends State<VenderItemDetailsCard> {
  int _qty = 0;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.cartQuantity ?? 0;
    _initQuantity();
  }

  @override
  void didUpdateWidget(covariant VenderItemDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.cartQuantity != oldWidget.item.cartQuantity) {
      setState(() {
        _qty = widget.item.cartQuantity ?? 0;
      });
    }
  }

  Future<void> _initQuantity() async {
    final localItems = await FoodCartDb.instance.getCartItems();
    for (final item in localItems) {
      if (item['vendor_item_id'] == widget.item.id) {
        if (mounted) {
          setState(() {
            _qty = item['quantity'] as int;
          });
        }
        break;
      }
    }
  }

  Widget _buildQuantitySelector(double price, String image, String name) {
    if (!widget.isDeliverable || _qty == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 90,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF24963F), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () async {
              if (_qty > 1) {
                final newQty = _qty - 1;
                setState(() {
                  _qty = newQty;
                });
                await FoodCartDb.instance.updateItemQuantity(
                  widget.item.id!,
                  newQty,
                );
              } else {
                setState(() {
                  _qty = 0;
                });
                await FoodCartDb.instance.removeItem(widget.item.id!);
              }
              _refreshCartBloc();
            },
            child: const Icon(Icons.remove, color: Color(0xFF24963F), size: 16),
          ),
          Text(
            _qty.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final newQty = _qty + 1;
              setState(() {
                _qty = newQty;
              });
              final vendorId = widget.item.vendor?.id ?? 30;
              await FoodCartDb.instance.insertOrUpdateItem(
                vendorId: vendorId,
                vendorItemId: widget.item.id!,
                quantity: 1,
                name: widget.item.itemName ?? 'Dish',
                price: widget.item.salePrice ?? 0.0,
                image: widget.item.images?.isNotEmpty == true
                    ? widget.item.images!.first.itemImage
                    : null,
                description: widget.item.description,
                cuisineType: widget.item.cuisineType,
              );
              _refreshCartBloc();
            },
            child: const Icon(Icons.add, color: Color(0xFF24963F), size: 16),
          ),
        ],
      ),
    );
  }

  void _refreshCartBloc() {
    try {
      if (mounted) {
        final loc = locationService.locationNotifier.value;
        context.read<FoodCartBloc>().add(
          GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
        );
      }
    } catch (e) {
      logger.w(
        '⚠️ VendorItemDetailsCard: FoodCartBloc not found in context — $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final images = item.images ?? [];
    final hasImages = images.isNotEmpty;
    final price = item.salePrice ?? 0.0;
    final String imageUrl = hasImages ? (images.first.itemImage ?? '') : '';

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Image Section
          Stack(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey.shade50,
                child: imageUrl.startsWith('http')
                    ? Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 250,
                          color: Colors.grey.shade100,
                          child:
                              const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                        ),
                      )
                    : (imageUrl.isNotEmpty
                        ? Image.network(
                            NetworkImages.mapAssetToNetwork(imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.fastfood,
                                    size: 80, color: Colors.grey),
                          )
                        : const Icon(Icons.fastfood,
                            size: 80, color: Colors.grey)),
              ),
              // Close Button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
              // Bestseller tag (Placeholder based on image)
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    FoodTypeIcon(foodType: item.cuisineType),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BESTSELLER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content Section
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1D1E),
                          ),
                        ),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1D1E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.avgRating != null && item.avgRating! > 0) ...[
                        Text(
                          item.avgRating!.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('|',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(width: 8),
                      ],
                      FoodTypeIcon(foodType: item.cuisineType),
                      const SizedBox(width: 4),
                      Text(
                        item.cuisineType ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFF3F3F3)),
                  const SizedBox(height: 24),
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PRICE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₹${(_qty > 0 ? price * _qty : price).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF24963F),
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    item.itemStatus == false
                        ? _buildNotDeliverableLargeButton()
                        : _qty > 0
                            ? _buildQuantitySelector(price, imageUrl, item.itemName ?? '')
                            : _buildLargeAddButton(price, imageUrl, item.itemName ?? ''),
                    if (item.isCustomize == true && item.itemStatus != false) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Customisable',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotDeliverableLargeButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD2D7)),
      ),
      child: const Text(
        'Not Deliverable',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildLargeAddButton(double price, String image, String name) {
    final isDeliverable = widget.isDeliverable;
    final isCustomize = widget.item.isCustomize == true;

    return GestureDetector(
      onTap: isDeliverable
          ? () async {
              final vendorId = widget.item.vendor?.id;

              if (isCustomize) {
                await CartValidationHelper.checkAndShowConflictDialog(
                  context,
                  isAddingFood: true,
                  newVendorId: vendorId,
                  onClearAndAdd: () async {
                    CustomizationBottomSheet.show(
                      context,
                      item: widget.item,
                      onAdd: (qty, addonIds, addonData) async {
                        setState(() {
                          _qty = qty;
                        });

                        final loc = locationService.locationNotifier.value;
                        context.read<FoodCartBloc>().add(
                              AddToCartEvent(
                                productVariantId: widget.item.id!,
                                quantity: qty,
                                lat: loc?.lat ?? 0.0,
                                lng: loc?.lng ?? 0.0,
                                addonIds: addonIds,
                                addonData: addonData,
                              ),
                            );
                      },
                    );
                  },
                );
              } else {
                await CartValidationHelper.checkAndShowConflictDialog(
                  context,
                  isAddingFood: true,
                  newVendorId: vendorId,
                  onClearAndAdd: () async {
                    setState(() {
                      _qty = 1;
                    });
                    final effectiveVendorId = vendorId ?? 30;
                    await FoodCartDb.instance.insertOrUpdateItem(
                      vendorId: effectiveVendorId,
                      vendorItemId: widget.item.id!,
                      quantity: 1,
                      name: widget.item.itemName ?? 'Dish',
                      price: price,
                      image: widget.item.images?.isNotEmpty == true
                          ? widget.item.images!.first.itemImage
                          : null,
                      description: widget.item.description,
                      cuisineType: widget.item.cuisineType,
                    );
                    _refreshCartBloc();
                  },
                );
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isDeliverable ? const Color(0xFF24963F) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Add',
          style: TextStyle(
            color: isDeliverable ? Colors.white : Colors.grey.shade500,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  double _calculateCustomizedPrice(double basePrice, List<dynamic> options) {
    double total = basePrice;
    for (var option in options) {
      total += (option.price ?? 0.0);
    }
    return total;
  }
}

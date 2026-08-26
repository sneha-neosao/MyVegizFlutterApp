import 'package:my_vegiz_flutter/features/cart/presentation/widgets/cart_conflict_dialog.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/widget/customization_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cart/data/cart_data.dart';
import '../../../routes/app_route_path.dart';
import '../../food_category/widget/veg_nonveg_filter.dart';
import '../../../core/storage/food_cart_db.dart';
import '../../cart/bloc/food_cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../../core/utils/location_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/network_images.dart';

class Store99Accordion extends StatefulWidget {
  final List<dynamic> items;
  final Function(int)? onItemTap;
  final bool isDeliverable;

  const Store99Accordion({
    super.key,
    required this.items,
    this.onItemTap,
    this.isDeliverable = true,
  });

  @override
  State<Store99Accordion> createState() => _Store99AccordionState();
}

class _Store99AccordionState extends State<Store99Accordion> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Text(
                            '99 store',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.black,
                            ),
                          ),
                          const Text(
                            '99 store',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFC000),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              color: Colors.blue.shade400,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Free delivery above ₹99',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && widget.items.isNotEmpty)
          _buildCategoryGrid(widget.items),
        Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildCategoryGrid(List<dynamic> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossCount = constraints.maxWidth > 500 ? 3 : 2;
        final double ratio = constraints.maxWidth > 500 ? 0.68 : 0.62;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: ratio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return CategoryItemCard(
              item: item,
              onItemTap: widget.onItemTap,
              isDeliverable: widget.isDeliverable,
            );
          },
        );
      },
    );
  }
}

class CategoryAccordion extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool hasNewBadge;
  final bool isExpanded;
  final List<dynamic> items;
  final VoidCallback onTap;
  final Function(int)? onItemTap;
  final bool isDeliverable;

  const CategoryAccordion({
    super.key,
    required this.title,
    this.subtitle,
    required this.hasNewBadge,
    required this.isExpanded,
    required this.items,
    required this.onTap,
    this.onItemTap,
    this.isDeliverable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (hasNewBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFC8019,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Color(0xFFFC8019),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && items.isNotEmpty) _buildCategoryGrid(items),
        Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildCategoryGrid(List<dynamic> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossCount = constraints.maxWidth > 500 ? 3 : 2;
        final double ratio = constraints.maxWidth > 500 ? 0.68 : 0.62;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: ratio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return CategoryItemCard(
              item: item,
              onItemTap: onItemTap,
              isDeliverable: isDeliverable,
            );
          },
        );
      },
    );
  }
}

class CategoryItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(int)? onItemTap;
  final bool isDeliverable;

  const CategoryItemCard({
    super.key,
    required this.item,
    this.onItemTap,
    this.isDeliverable = true,
  });

  @override
  State<CategoryItemCard> createState() => _CategoryItemCardState();
}

class _CategoryItemCardState extends State<CategoryItemCard> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.item['cart_quantity'] ?? 0;
  }

  @override
  void didUpdateWidget(covariant CategoryItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item['cart_quantity'] != oldWidget.item['cart_quantity']) {
      setState(() {
        _qty = widget.item['cart_quantity'] ?? 0;
      });
    }
  }

  double _calculateCustomizedPrice(double basePrice, List<dynamic> options) {
    double total = basePrice;
    for (var option in options) {
      total += (option.price ?? 0.0);
    }
    return total;
  }

  void _refreshCartBloc() {
    try {
      final loc = locationService.locationNotifier.value;
      if (mounted) {
        context.read<FoodCartBloc>().add(
          GetCartListEvent(lat: loc?.lat ?? 0.0, lng: loc?.lng ?? 0.0),
        );
      }
    } catch (e) {
      logger.w('⚠️ CategoryItemCard: FoodCartBloc not found in context — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.item['name'] ?? '';
    final String image = widget.item['image'] ?? NetworkImages.topPicksFallback;
    final String slug = widget.item['slug'] ?? '';
    final String cuisineType = widget.item['cuisineType'] ?? '';
    final String price = widget.item['price'] ?? '';
    final String? description = widget.item['description'];
    final int? totalDeliveryTime = widget.item['totalDeliveryTime'];

    double parsedPrice = 0.0;
    if (price.isNotEmpty) {
      final priceStr = price.toString().replaceAll(RegExp(r'[^\d.]'), '');
      parsedPrice = double.tryParse(priceStr) ?? 0.0;
    }

    return GestureDetector(
      onTap: () {
        final itemId = int.tryParse(slug);
        if (itemId != null && widget.onItemTap != null) {
          widget.onItemTap!(itemId);
        } else {
          context.push(AppRoutePath.productDetails, extra: slug);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: image.startsWith('http')
                    ? Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.fastfood,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Image.network(
                        NetworkImages.mapAssetToNetwork(image),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.fastfood,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg and Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Veg/NonVeg Icon
                            FoodTypeIcon(foodType: cuisineType),
                            if (totalDeliveryTime != null) ...[
                              const SizedBox(width: 4),
                              // Time
                              Text(
                                '⏱ $totalDeliveryTime mins',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (widget.item['avgRating'] != null && (widget.item['avgRating'] as num) > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber.shade700,
                                size: 12,
                              ),
                              const SizedBox(width: 1),
                              Text(
                                (widget.item['avgRating'] as num).toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (widget.item['totalReviews'] != null && (widget.item['totalReviews'] as int) > 0)
                                Text(
                                  ' (${widget.item['totalReviews']})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Name
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      // Description
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Price and Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC000),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '₹$price',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            widget.item['itemStatus'] == false
                                ? _buildNotDeliverableButton()
                                : _qty > 0
                                    ? _buildQuantitySelector(parsedPrice, image, name)
                                    : _buildAddButton(parsedPrice, image, name),
                            if (widget.item['isCustomize'] == true && widget.item['itemStatus'] != false) ...[
                              const SizedBox(height: 2),
                              const Text(
                                'Customisable',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildAddButton(double parsedPrice, String image, String name) {
    final isDeliverable = widget.isDeliverable;
    final isCustomize = widget.item['isCustomize'] == true;

    return GestureDetector(
      onTap: isDeliverable
          ? () async {
              final int? vendorId = widget.item['vendorId'] as int?;

              if (isCustomize) {
                // For customizable items, we show customization sheet
                // But first check for vendor conflict
                await CartValidationHelper.checkAndShowConflictDialog(
                  context,
                  isAddingFood: true,
                  newVendorId: vendorId,
                  onClearAndAdd: () async {
                    CustomizationBottomSheet.show(
                      context,
                      item: widget.item['rawItem'],
                      onAdd: (qty, addonIds, addonData) async {
                        final int? itemId = widget.item['id'] as int?;
                        if (itemId != null && vendorId != null) {
                          setState(() {
                            _qty = qty;
                          });

                          final loc = locationService.locationNotifier.value;
                          context.read<FoodCartBloc>().add(
                                AddToCartEvent(
                                  productVariantId: itemId,
                                  quantity: qty,
                                  lat: loc?.lat ?? 0.0,
                                  lng: loc?.lng ?? 0.0,
                                  addonIds: addonIds,
                                  addonData: addonData,
                                ),
                              );
                        }
                      },
                    );
                  },
                );
              } else {
                // Standard add logic
                await CartValidationHelper.checkAndShowConflictDialog(
                  context,
                  isAddingFood: true,
                  newVendorId: vendorId,
                  onClearAndAdd: () async {
                    final int? itemId = widget.item['id'] as int?;
                    if (itemId != null && vendorId != null) {
                      setState(() {
                        _qty = 1;
                      });
                      await FoodCartDb.instance.insertOrUpdateItem(
                        vendorId: vendorId,
                        vendorItemId: itemId,
                        quantity: 1,
                        name: name,
                        price: parsedPrice,
                        image: image.startsWith('http') ? image : null,
                        description: widget.item['description'],
                        cuisineType: widget.item['cuisineType'],
                      );
                      _refreshCartBloc();
                    }
                  },
                );
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDeliverable ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDeliverable ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
          boxShadow: isDeliverable
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            color: isDeliverable ? Colors.green : Colors.grey.shade400,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNotDeliverableButton() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD2D7)),
      ),
      child: const Text(
        'Not Deliverable',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(double parsedPrice, String image, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              final int? itemId = widget.item['id'] as int?;
              if (itemId != null) {
                if (_qty > 1) {
                  final newQty = _qty - 1;
                  setState(() {
                    _qty = newQty;
                  });
                  await FoodCartDb.instance.updateItemQuantity(itemId, newQty);
                } else {
                  setState(() {
                    _qty = 0;
                  });
                  await FoodCartDb.instance.removeItem(itemId);
                }
                _refreshCartBloc();
              }
            },
            child: const Icon(Icons.remove, color: Colors.green, size: 18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _qty.toString(),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final int? itemId = widget.item['id'] as int?;
              final int? vendorId = widget.item['vendorId'] as int?;
              if (itemId != null && vendorId != null) {
                final newQty = _qty + 1;
                setState(() {
                  _qty = newQty;
                });
                await FoodCartDb.instance.insertOrUpdateItem(
                  vendorId: vendorId,
                  vendorItemId: itemId,
                  quantity: 1,
                  name: name,
                  price: parsedPrice,
                  image: image.startsWith('http') ? image : null,
                  description: widget.item['description'],
                  cuisineType: widget.item['cuisineType'],
                );
                _refreshCartBloc();
              }
            },
            child: const Icon(Icons.add, color: Colors.green, size: 18),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../data/models/vendor_list_model.dart' as list_model;
import '../data/models/vendor_item_details_model.dart' as detail_model;
import '../../food_category/widget/veg_nonveg_filter.dart';
import '../../../core/utils/network_images.dart';

class CustomizationBottomSheet extends StatefulWidget {
  final dynamic item; // Can be VendorItemModel or VendorItemDetailsData
  final Function(int quantity, List<int> addonIds, List<Map<String, dynamic>> addonData) onAdd;

  const CustomizationBottomSheet({
    super.key,
    required this.item,
    required this.onAdd,
  });

  static void show(
    BuildContext context, {
    required dynamic item,
    required Function(int quantity, List<int> addonIds, List<Map<String, dynamic>> addonData) onAdd,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomizationBottomSheet(
        item: item,
        onAdd: onAdd,
      ),
    );
  }

  @override
  State<CustomizationBottomSheet> createState() => _CustomizationBottomSheetState();
}

class _CustomizationBottomSheetState extends State<CustomizationBottomSheet> {
  int _quantity = 1;
  final Map<String, List<dynamic>> _selectedOptions = {}; // categoryUuId/Title -> list of selected line entries

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    final categories = _getCategories();
    for (var cat in categories) {
      final key = cat.uuId ?? cat.categoryTitle ?? cat.id?.toString() ?? '';
      if (cat.categoryType?.toLowerCase() == 'choice') {
        if (cat.lineEntries != null && cat.lineEntries!.isNotEmpty) {
          _selectedOptions[key] = [cat.lineEntries!.first];
        }
      } else {
        _selectedOptions[key] = [];
      }
    }
  }

  List<dynamic> _getCategories() {
    if (widget.item is list_model.VendorItemModel) {
      return (widget.item as list_model.VendorItemModel).customizedCategories ?? [];
    } else if (widget.item is detail_model.VendorItemDetailsData) {
      return (widget.item as detail_model.VendorItemDetailsData).customizedCategories ?? [];
    }
    return [];
  }

  String _getItemName() {
    if (widget.item is list_model.VendorItemModel) {
      return (widget.item as list_model.VendorItemModel).itemName ?? '';
    } else if (widget.item is detail_model.VendorItemDetailsData) {
      return (widget.item as detail_model.VendorItemDetailsData).itemName ?? '';
    }
    return '';
  }

  String _getItemImage() {
    if (widget.item is list_model.VendorItemModel) {
      return (widget.item as list_model.VendorItemModel).primaryImage ?? '';
    } else if (widget.item is detail_model.VendorItemDetailsData) {
      final images = (widget.item as detail_model.VendorItemDetailsData).images;
      return (images != null && images.isNotEmpty) ? images.first.itemImage ?? '' : '';
    }
    return '';
  }

  double _getBasePrice() {
    if (widget.item is list_model.VendorItemModel) {
      return (widget.item as list_model.VendorItemModel).salePrice ?? 0.0;
    } else if (widget.item is detail_model.VendorItemDetailsData) {
      return (widget.item as detail_model.VendorItemDetailsData).salePrice ?? 0.0;
    }
    return 0.0;
  }

  double _calculateTotalPrice() {
    double total = _getBasePrice();
    _selectedOptions.forEach((catId, entries) {
      for (var entry in entries) {
        total += (entry.price ?? 0.0);
      }
    });
    return total * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories();
    final itemName = _getItemName();
    final itemImage = _getItemImage();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: itemImage.isNotEmpty
                      ? Image.network(
                          itemImage.startsWith('http') ? itemImage : NetworkImages.mapAssetToNetwork(itemImage),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Customization Options
          Flexible(
            child: Container(
              color: const Color(0xFFF1F4F6),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.map((cat) => _buildCategorySection(cat)).toList(),
                ),
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quantity Selector
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove, size: 18, color: Color(0xFF24963F)),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF24963F),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 18, color: Color(0xFF24963F)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Add Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final List<Map<String, dynamic>> addonData = [];
                      final List<int> addonIds = [];

                      _selectedOptions.forEach((catKey, entries) {
                        // Find the category title for these entries
                        dynamic cat;
                        try {
                          cat = categories.firstWhere(
                            (c) => (c.uuId ?? c.categoryTitle ?? c.id?.toString() ?? '') == catKey,
                          );
                        } catch (_) {
                          cat = null;
                        }

                        final String categoryTitle = cat?.categoryTitle ?? '';

                        for (var entry in entries) {
                          if (entry.id != null) {
                            addonIds.add(entry.id!);
                            addonData.add({
                              "id": entry.id,
                              "uu_id": entry.uuId,
                              "category_title": categoryTitle,
                              "sub_category_title": entry.subCategoryTitle,
                              "price": entry.price,
                            });
                          }
                        }
                      });

                      widget.onAdd(_quantity, addonIds, addonData);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF24963F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Item | ₹${_calculateTotalPrice().toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 44,
      height: 44,
      color: Colors.grey.shade100,
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 24),
    );
  }

  Widget _buildCategorySection(dynamic cat) {
    final String title = cat.categoryTitle ?? '';
    final String key = cat.uuId ?? cat.categoryTitle ?? cat.id?.toString() ?? '';
    final String type = cat.categoryType?.toLowerCase() ?? 'addon';
    final List<dynamic> entries = cat.lineEntries ?? [];
    final bool isChoice = type == 'choice';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isChoice ? 'Select any 1' : 'Select options',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final lineEntry = entry.value;
              final isLast = index == entries.length - 1;

              return Column(
                children: [
                  _buildLineEntryItem(key, lineEntry, isChoice),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLineEntryItem(String catKey, dynamic entry, bool isChoice) {
    final bool isSelected = _selectedOptions[catKey]?.contains(entry) ?? false;

    return InkWell(
      onTap: () {
        setState(() {
          if (isChoice) {
            _selectedOptions[catKey] = [entry];
          } else {
            final list = List<dynamic>.from(_selectedOptions[catKey] ?? []);
            if (isSelected) {
              list.remove(entry);
            } else {
              list.add(entry);
            }
            _selectedOptions[catKey] = list;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const FoodTypeIcon(foodType: 'veg'),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.subCategoryTitle ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ),
            if (entry.price != null && entry.price > 0)
              Text(
                '₹${entry.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            const SizedBox(width: 12),
            if (isChoice)
              _buildRadioButton(isSelected)
            else
              _buildCheckbox(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioButton(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? const Color(0xFFFC8019) : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFC8019),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? const Color(0xFF999999) : Colors.grey.shade400,
          width: 1.5,
        ),
        color: Colors.transparent,
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: Color(0xFF999999),
            )
          : null,
    );
  }
}

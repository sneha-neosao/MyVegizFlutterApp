import 'package:flutter/material.dart';

import '../data/models/vendor_list_model.dart';

class FiltersList extends StatelessWidget {
  final String
  activeFilter; // 'all', 'veg', 'nonveg' (local UI filter for menu items)
  final ValueChanged<String> onFilterChanged;
  final bool showVegNonVegFilter;

  // API-driven sort and food type filters
  final String? activeSortBy;
  final String? activeFoodType;
  final ValueChanged<String?>? onSortChanged;
  final ValueChanged<String?>? onFoodTypeChanged;
  final List<VendorFilterOption> sortOptions;
  final List<VendorFilterOption> foodTypes;

  const FiltersList({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    this.showVegNonVegFilter = true,
    this.activeSortBy,
    this.activeFoodType,
    this.onSortChanged,
    this.onFoodTypeChanged,
    this.sortOptions = const [],
    this.foodTypes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bool isVegSelected = activeFilter == 'veg';
    final bool isNonVegSelected = activeFilter == 'nonveg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              // 1. Veg Filter Chip (local filter for displayed items)
              if (showVegNonVegFilter) ...[
                GestureDetector(
                  onTap: () {
                    onFilterChanged(isVegSelected ? 'all' : 'veg');
                  },
                  child: _buildFilterChip(
                    isSelected: isVegSelected,
                    selectedBorderColor: const Color(0xFF24963F),
                    selectedBgColor: const Color(0xFF24963F).withOpacity(0.05),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF24963F),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: CircleAvatar(
                              backgroundColor: Color(0xFF24963F),
                              radius: 3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isVegSelected ? Icons.toggle_on : Icons.toggle_off,
                          color: isVegSelected
                              ? const Color(0xFF24963F)
                              : Colors.grey.shade400,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 2. Non-Veg Filter Chip (local filter for displayed items)
              if (showVegNonVegFilter) ...[
                GestureDetector(
                  onTap: () {
                    onFilterChanged(isNonVegSelected ? 'all' : 'nonveg');
                  },
                  child: _buildFilterChip(
                    isSelected: isNonVegSelected,
                    selectedBorderColor: const Color(0xFFE43B3F),
                    selectedBgColor: const Color(0xFFE43B3F).withOpacity(0.05),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE43B3F),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.circle,
                              color: Color(0xFFE43B3F),
                              size: 9,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isNonVegSelected ? Icons.toggle_on : Icons.toggle_off,
                          color: isNonVegSelected
                              ? const Color(0xFFE43B3F)
                              : Colors.grey.shade400,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              /*// 3. Sort Chip (API-driven)
              if (onSortChanged != null) ...[
                GestureDetector(
                  onTap: () {
                    _showSortBottomSheet(context);
                  },
                  child: _buildFilterChip(
                    isSelected: activeSortBy != null,
                    selectedBorderColor: const Color(0xFFFC8019),
                    selectedBgColor: const Color(0xFFFC8019).withOpacity(0.06),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort,
                          size: 15,
                          color: activeSortBy != null
                              ? const Color(0xFFFC8019)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activeSortBy != null
                              ? _sortLabel(activeSortBy!)
                              : 'Sort',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: activeSortBy != null
                                ? const Color(0xFFFC8019)
                                : Colors.black87,
                          ),
                        ),
                        if (activeSortBy != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onSortChanged!(null),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Color(0xFFFC8019),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],*/

              /*// 4. Food Type Chip (API-driven)
              if (showVegNonVegFilter && onFoodTypeChanged != null) ...[
                GestureDetector(
                  onTap: () {
                    _showFoodTypeBottomSheet(context);
                  },
                  child: _buildFilterChip(
                    isSelected: activeFoodType != null,
                    selectedBorderColor: activeFoodType == 'veg'
                        ? const Color(0xFF24963F)
                        : activeFoodType == 'non-veg'
                        ? const Color(0xFFE43B3F)
                        : const Color(0xFFFC8019),
                    selectedBgColor: activeFoodType == 'veg'
                        ? const Color(0xFF24963F).withOpacity(0.06)
                        : activeFoodType == 'non-veg'
                        ? const Color(0xFFE43B3F).withOpacity(0.06)
                        : const Color(0xFFFC8019).withOpacity(0.06),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 14,
                          color: activeFoodType == 'veg'
                              ? const Color(0xFF24963F)
                              : activeFoodType == 'non-veg'
                              ? const Color(0xFFE43B3F)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activeFoodType != null
                              ? _foodTypeLabel(activeFoodType!)
                              : 'Food Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: activeFoodType != null
                                ? (activeFoodType == 'veg'
                                      ? const Color(0xFF24963F)
                                      : const Color(0xFFE43B3F))
                                : Colors.black87,
                          ),
                        ),
                        if (activeFoodType != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onFoodTypeChanged!(null),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: activeFoodType == 'veg'
                                  ? const Color(0xFF24963F)
                                  : const Color(0xFFE43B3F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],*/
            ],
          ),
        ),
      ],
    );
  }

  String _sortLabel(String key) {
    final match = sortOptions.firstWhere(
      (opt) => opt.key == key,
      orElse: () => VendorFilterOption(key: key, label: null),
    );
    if (match.label != null) return match.label!;
    switch (key) {
      case 'rating_asc':
        return 'Rating: Low-High';
      case 'rating_desc':
        return 'Rating: High-Low';
      case 'price_asc':
        return 'Price: Low-High';
      case 'price_desc':
        return 'Price: High-Low';
      default:
        return key;
    }
  }

  String _foodTypeLabel(String key) {
    final match = foodTypes.firstWhere(
      (opt) => opt.key == key,
      orElse: () => VendorFilterOption(key: key, label: null),
    );
    if (match.label != null) return match.label!;
    switch (key) {
      case 'veg':
        return 'Vegetarian';
      case 'non-veg':
      case 'nonveg':
        return 'Non-Vegetarian';
      default:
        return key;
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    final options = sortOptions.isNotEmpty
        ? sortOptions
        : [
            VendorFilterOption(key: 'rating_asc', label: 'Rating: Low to High'),
            VendorFilterOption(
              key: 'rating_desc',
              label: 'Rating: High to Low',
            ),
            VendorFilterOption(key: 'price_asc', label: 'Price: Low to High'),
            VendorFilterOption(key: 'price_desc', label: 'Price: High to Low'),
          ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Sort By',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...options.map((opt) {
              final isSelected = activeSortBy == opt.key;
              return ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  onSortChanged!(isSelected ? null : opt.key);
                },
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFFFC8019) : Colors.grey,
                ),
                title: Text(
                  opt.label ?? '',
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFFFC8019)
                        : Colors.black87,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFoodTypeBottomSheet(BuildContext context) {
    final options = foodTypes.isNotEmpty
        ? foodTypes
        : [
            VendorFilterOption(key: 'veg', label: 'Vegetarian'),
            VendorFilterOption(key: 'non-veg', label: 'Non-Vegetarian'),
          ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Food Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...options.map((opt) {
              final isSelected = activeFoodType == opt.key;
              final isVeg = opt.key == 'veg';
              return ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  onFoodTypeChanged!(isSelected ? null : opt.key);
                },
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? (isVeg
                            ? const Color(0xFF24963F)
                            : const Color(0xFFE43B3F))
                      : Colors.grey,
                ),
                title: Text(
                  opt.label ?? '',
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? (isVeg
                              ? const Color(0xFF24963F)
                              : const Color(0xFFE43B3F))
                        : Colors.black87,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required Widget child,
    bool isSelected = false,
    Color? selectedBorderColor,
    Color? selectedBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected && selectedBgColor != null
            ? selectedBgColor
            : Colors.white,
        border: Border.all(
          color: isSelected && selectedBorderColor != null
              ? selectedBorderColor
              : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

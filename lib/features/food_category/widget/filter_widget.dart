import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../data/models/vendor_entity_category_model.dart';
import 'veg_nonveg_filter.dart';

// ----------------------------------------------------
// Filter State Model
// ----------------------------------------------------
class SwiggyFilterState {
  String
  sortBy; // 'relevance', 'delivery_time', 'rating', 'cost_low_high', 'cost_high_low'
  String store99; // 'all', 'meals_99', 'meals_under_99'
  bool isFastDelivery; // 15 mins
  String offers; // 'all', 'flat_discount', 'free_delivery'
  String ratingFilter; // 'all', '4.5_plus', '4.0_plus'
  String costForTwo; // 'all', 'under_250', '250_500', 'over_500'
  String vegNonVeg; // 'all', 'veg', 'non_veg'

  SwiggyFilterState({
    this.sortBy = 'relevance',
    this.store99 = 'all',
    this.isFastDelivery = false,
    this.offers = 'all',
    this.ratingFilter = 'all',
    this.costForTwo = 'all',
    this.vegNonVeg = 'all',
  });

  SwiggyFilterState copy() {
    return SwiggyFilterState(
      sortBy: sortBy,
      store99: store99,
      isFastDelivery: isFastDelivery,
      offers: offers,
      ratingFilter: ratingFilter,
      costForTwo: costForTwo,
      vegNonVeg: vegNonVeg,
    );
  }

  bool getIsDefault({bool isApiDriven = false}) {
    if (isApiDriven) {
      return (sortBy == '' || sortBy == 'relevance') &&
          (vegNonVeg == '' || vegNonVeg == 'both' || vegNonVeg == 'all');
    }
    return sortBy == 'relevance' &&
        store99 == 'all' &&
        !isFastDelivery &&
        offers == 'all' &&
        ratingFilter == 'all' &&
        costForTwo == 'all' &&
        vegNonVeg == 'all';
  }

  bool get isDefault => getIsDefault();

  int getActiveFiltersCount({bool isApiDriven = false}) {
    int count = 0;
    if (isApiDriven) {
      if (sortBy != '' && sortBy != 'relevance') count++;
      if (vegNonVeg != '' && vegNonVeg != 'both' && vegNonVeg != 'all') count++;
    } else {
      if (sortBy != 'relevance') count++;
      if (store99 != 'all') count++;
      if (isFastDelivery) count++;
      if (offers != 'all') count++;
      if (ratingFilter != 'all') count++;
      if (costForTwo != 'all') count++;
      if (vegNonVeg != 'all') count++;
    }
    return count;
  }

  int get activeFiltersCount => getActiveFiltersCount();
}

// ----------------------------------------------------
// Swiggy Filter Modal Bottom Sheet
// ----------------------------------------------------
class FilterWidget extends StatefulWidget {
  final SwiggyFilterState initialState;
  final String initialTab;
  final Function(SwiggyFilterState) onApply;
  final List<FilterOption> sortOptions;
  final List<FilterOption> foodTypes;

  const FilterWidget({
    super.key,
    required this.initialState,
    required this.initialTab,
    required this.onApply,
    this.sortOptions = const [],
    this.foodTypes = const [],
  });

  static void show(
    BuildContext context, {
    required SwiggyFilterState initialState,
    required String initialTab,
    required Function(SwiggyFilterState) onApply,
    List<FilterOption> sortOptions = const [],
    List<FilterOption> foodTypes = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: FilterWidget(
          initialState: initialState,
          initialTab: initialTab,
          onApply: onApply,
          sortOptions: sortOptions,
          foodTypes: foodTypes,
        ),
      ),
    );
  }

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  late SwiggyFilterState _currentState;
  late String _activeTab;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState.copy();
    _activeTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final bool isApiDriven =
        widget.sortOptions.isNotEmpty || widget.foodTypes.isNotEmpty;
    final bool isDefaultState = _currentState.getIsDefault(
      isApiDriven: isApiDriven,
    );

    // List of filter categories
    final List<Map<String, String>> tabs = [];
    if (isApiDriven) {
      if (widget.sortOptions.isNotEmpty) {
        tabs.add({"id": "Sort", "label": "Sort"});
      }
      if (widget.foodTypes.isNotEmpty) {
        tabs.add({"id": "Veg", "label": "Veg/Non-Veg"});
      }
    } else {
      tabs.addAll([
        {"id": "Sort", "label": "Sort"},
        {"id": "99store", "label": "99store"},
        {"id": "15mins", "label": "15 mins"},
        {"id": "Offers", "label": "Offers"},
        {"id": "Ratings", "label": "Ratings"},
        {"id": "Cost", "label": "Cost for two"},
        {"id": "Veg", "label": "Veg/Non-Veg"},
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.w)),
      ),
      child: Column(
        children: [
          // 1. Header (Filter Title + Close Button)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade700,
                      size: 16.w,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // 2. Main Content (Left Tabs + Right Option Grid/List)
          Expanded(
            child: Row(
              children: [
                // Left Column: Tab list
                Container(
                  width: 125.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      final bool isSelected = _activeTab == tab['id'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = tab['id']!;
                          });
                        },
                        child: Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              // Active orange left bar indicator
                              Container(
                                width: 4.w,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFC8019)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(2.w),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 14.w),
                                  child: Text(
                                    tab['label']!,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      color: isSelected
                                          ? const Color(0xFFFC8019)
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Right Column: Active Option content panel
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    child: _buildRightPanelContent(),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom Actions (Clear + Apply)
          const Divider(height: 1, thickness: 1),
          Container(
            height: 65.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    final clearedState = SwiggyFilterState();
                    setState(() {
                      _currentState = clearedState;
                    });
                    widget.onApply(clearedState);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Clear Filters",
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onApply(_currentState);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDefaultState
                          ? Colors.grey.shade200
                          : const Color(0xFFFC8019),
                      borderRadius: BorderRadius.circular(12.w),
                      boxShadow: isDefaultState
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFFFC8019).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 36.w,
                      vertical: 8.h,
                    ),
                    child: Text(
                      "Apply",
                      style: TextStyle(
                        color: isDefaultState
                            ? Colors.grey.shade500
                            : Colors.white,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
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

  // ----------------------------------------------------
  // Right Option List Renderers
  // ----------------------------------------------------
  Widget _buildRightPanelContent() {
    switch (_activeTab) {
      case "Sort":
        return _buildSortOptions();
      case "99store":
        return _build99StoreOptions();
      case "15mins":
        return _build15MinsOptions();
      case "Offers":
        return _buildOffersOptions();
      case "Ratings":
        return _buildRatingsOptions();
      case "Cost":
        return _buildCostOptions();
      case "Veg":
        return _buildVegOptions();
      default:
        return Container();
    }
  }

  Widget _buildSortOptions() {
    final List<Map<String, String>> fallbackOptions = [
      {"id": "relevance", "label": "Relevance (Default)"},
      {"id": "delivery_time", "label": "Delivery Time"},
      {"id": "rating", "label": "Rating"},
      {"id": "cost_low_high", "label": "Cost: Low to High"},
      {"id": "cost_high_low", "label": "Cost: High to Low"},
    ];

    final hasSortOptions = widget.sortOptions.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("SORT BY"),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: hasSortOptions
                ? widget.sortOptions.length
                : fallbackOptions.length,
            itemBuilder: (context, index) {
              if (hasSortOptions) {
                final opt = widget.sortOptions[index];
                final bool isSelected = _currentState.sortBy == opt.key;

                return _buildRadioItem(
                  label: opt.label ?? '',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentState.sortBy = opt.key ?? '';
                    });
                  },
                );
              } else {
                final opt = fallbackOptions[index];
                final bool isSelected = _currentState.sortBy == opt['id'];

                return _buildRadioItem(
                  label: opt['label']!,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentState.sortBy = opt['id']!;
                    });
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _build99StoreOptions() {
    final List<Map<String, String>> options = [
      {"id": "all", "label": "All Foods"},
      {"id": "meals_99", "label": "Meals at ₹99"},
      {"id": "meals_under_99", "label": "Deals under ₹99"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("99 STORE DEALS"),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final bool isSelected = _currentState.store99 == opt['id'];

              return _buildRadioItem(
                label: opt['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentState.store99 = opt['id']!;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _build15MinsOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("DELIVERY TIME"),
        SizedBox(height: 12.h),
        _buildCheckboxItem(
          label: "Fast Delivery (under 15 mins)",
          isSelected: _currentState.isFastDelivery,
          onTap: () {
            setState(() {
              _currentState.isFastDelivery = !_currentState.isFastDelivery;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOffersOptions() {
    final List<Map<String, String>> options = [
      {"id": "all", "label": "All Deals"},
      {"id": "flat_discount", "label": "Flat Discounts"},
      {"id": "free_delivery", "label": "Free Delivery Offer"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("DISCOUNTS & OFFERS"),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final bool isSelected = _currentState.offers == opt['id'];

              return _buildRadioItem(
                label: opt['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentState.offers = opt['id']!;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsOptions() {
    final List<Map<String, String>> options = [
      {"id": "all", "label": "All Ratings"},
      {"id": "4.5_plus", "label": "Rated 4.5+"},
      {"id": "4.0_plus", "label": "Rated 4.0+"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("RATINGS"),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final bool isSelected = _currentState.ratingFilter == opt['id'];

              return _buildRadioItem(
                label: opt['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentState.ratingFilter = opt['id']!;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCostOptions() {
    final List<Map<String, String>> options = [
      {"id": "all", "label": "All Budgets"},
      {"id": "under_250", "label": "Under ₹250"},
      {"id": "250_500", "label": "₹250 to ₹500"},
      {"id": "over_500", "label": "Over ₹500"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("COST FOR TWO"),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final bool isSelected = _currentState.costForTwo == opt['id'];

              return _buildRadioItem(
                label: opt['label']!,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _currentState.costForTwo = opt['id']!;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVegOptions() {
    final List<Map<String, String>> fallbackOptions = [
      {"id": "all", "label": "All items"},
      {"id": "veg", "label": "Pure Veg"},
      {"id": "non_veg", "label": "Non-Veg Only"},
    ];

    final hasFoodTypes = widget.foodTypes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("CUISINE PREFERENCE"),
        SizedBox(height: 12.h),
        Expanded(
          child: ListView.builder(
            itemCount: hasFoodTypes
                ? widget.foodTypes.length
                : fallbackOptions.length,
            itemBuilder: (context, index) {
              if (hasFoodTypes) {
                final opt = widget.foodTypes[index];
                final bool isSelected =
                    _currentState.vegNonVeg == opt.key ||
                    (_currentState.vegNonVeg == '' && opt.key == 'both') ||
                    (_currentState.vegNonVeg == 'all' && opt.key == 'both');

                return _buildRadioItem(
                  label: opt.label ?? '',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentState.vegNonVeg = opt.key ?? '';
                    });
                  },
                );
              } else {
                final opt = fallbackOptions[index];
                final bool isSelected = _currentState.vegNonVeg == opt['id'];

                return _buildRadioItem(
                  label: opt['label']!,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _currentState.vegNonVeg = opt['id']!;
                    });
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Helper Elements
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRadioItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48.h,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            // Gorgeous circular Swiggy radio selector
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFC8019)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFC8019),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48.h,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            // Checked indicator
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected
                  ? const Color(0xFFFC8019)
                  : Colors.grey.shade400,
              size: 22.w,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Reusable Swiggy-Style Horizontal Filter Bar
// ----------------------------------------------------
class CommonFilterBar extends StatefulWidget {
  final SwiggyFilterState filterState;
  final Function(SwiggyFilterState) onFilterChanged;
  final bool show99Store;
  final List<FilterOption> sortOptions;
  final List<FilterOption> foodTypes;

  const CommonFilterBar({
    super.key,
    required this.filterState,
    required this.onFilterChanged,
    this.show99Store = true,
    this.sortOptions = const [],
    this.foodTypes = const [],
  });

  @override
  State<CommonFilterBar> createState() => _CommonFilterBarState();
}

class _CommonFilterBarState extends State<CommonFilterBar> {
  final GlobalKey _sortByKey = GlobalKey();

  void _openFilterModal(BuildContext context, String initialTab) {
    FilterWidget.show(
      context,
      initialState: widget.filterState,
      initialTab: initialTab,
      onApply: widget.onFilterChanged,
      sortOptions: widget.sortOptions,
      foodTypes: widget.foodTypes,
    );
  }

  void _showSortPopup(BuildContext context) {
    final RenderBox? renderBox =
        _sortByKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(
        0.01,
      ), // Ultra-subtle overlay background
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        final screenWidth = MediaQuery.of(context).size.width;
        final popupWidth = 220.w;
        final leftPos = (offset.dx + popupWidth > screenWidth)
            ? (screenWidth - popupWidth - 16.w)
            : offset.dx;

        return Stack(
          children: [
            Positioned(
              top: offset.dy + size.height + 6.h,
              left: leftPos,
              child: Material(
                color: Colors.transparent,
                child: _SortPopupCard(
                  animation: animation,
                  currentState: widget.filterState,
                  sortOptions: widget.sortOptions,
                  onApply: widget.onFilterChanged,
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final opacity = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: scale,
            alignment: const Alignment(
              -0.6,
              -1.0,
            ), // Scale out organically from the Sort By chip
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isApiDriven = widget.sortOptions.isNotEmpty || widget.foodTypes.isNotEmpty;
    final int activeCount = widget.filterState.getActiveFiltersCount(isApiDriven: isApiDriven);

    // Dynamic Sort By label & selection state
    final selectedSortOpt = widget.sortOptions.firstWhere(
      (opt) => opt.key == widget.filterState.sortBy,
      orElse: () => FilterOption(key: '', label: ''),
    );
    final bool isSortSelected = selectedSortOpt.key != null && selectedSortOpt.key!.isNotEmpty;
    final String sortLabel = isSortSelected ? (selectedSortOpt.label ?? "Sort by") : "Sort by";

    // Dynamic Food Type / Cuisine preference label & selection state
    final selectedFoodTypeOpt = widget.foodTypes.firstWhere(
      (opt) {
        final key = opt.key ?? '';
        final currentVal = widget.filterState.vegNonVeg;
        if (key == 'both') {
          return currentVal == 'both' || currentVal == 'all' || currentVal == '';
        }
        return currentVal == key;
      },
      orElse: () => FilterOption(key: '', label: ''),
    );
    final bool isFoodTypeSelected = selectedFoodTypeOpt.key != null &&
        selectedFoodTypeOpt.key!.isNotEmpty &&
        selectedFoodTypeOpt.key != 'both';
    final String foodTypeLabel = selectedFoodTypeOpt.label ?? "Cuisine Preference";

    return SizedBox(
      height: 38.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: [
          // Filter Chip
          // _buildFilterChip(
          //   context,
          //   label: "Filter",
          //   icon: Icons.tune,
          //   hasTrailing: true,
          //   isSelected: activeCount > 0,
          //   badgeCount: activeCount > 0 ? activeCount : null,
          //   onTap: () => _openFilterModal(context, 'Sort'),
          // ),

          if (isApiDriven) ...[
            // Dynamic Sort By Chip
            // _buildFilterChip(
            //   context,
            //   key: _sortByKey,
            //   label: sortLabel,
            //   icon: Icons.keyboard_arrow_down,
            //   hasTrailing: false,
            //   isSelected: isSortSelected,
            //   onTap: () => _showSortPopup(context),
            // ),
            // Dynamic Cuisine Preference Chip
            if (widget.foodTypes.isNotEmpty) ...[
              // Veg Only Chip
              _buildIconChip(
                child: const VegIcon(),
                isSelected: widget.filterState.vegNonVeg == 'veg',
                selectedBgColor: const Color(0xFFE6F4EA),
                selectedBorderColor: const Color(0xFF0F8A5F),
                onTap: () {
                  final newState = widget.filterState.copy();
                  newState.vegNonVeg = 'veg';
                  widget.onFilterChanged(newState);
                },
              ),
              // Non-Veg Only Chip
              _buildIconChip(
                child: const NonVegIcon(),
                isSelected: widget.filterState.vegNonVeg == 'nonveg' || widget.filterState.vegNonVeg == 'non_veg',
                selectedBgColor: const Color(0xFFFCE8E6),
                selectedBorderColor: const Color(0xFFE43B3F),
                onTap: () {
                  final newState = widget.filterState.copy();
                  newState.vegNonVeg = 'nonveg';
                  widget.onFilterChanged(newState);
                },
              ),
              // Both Chip
              _buildIconChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VegIcon(),
                    SizedBox(width: 6.w),
                    const NonVegIcon(),
                  ],
                ),
                isSelected: widget.filterState.vegNonVeg == 'both' || widget.filterState.vegNonVeg == 'all' || widget.filterState.vegNonVeg == '',
                selectedBgColor: const Color(0xFFF0F4F9),
                selectedBorderColor: const Color(0xFF8BA4C7),
                onTap: () {
                  final newState = widget.filterState.copy();
                  newState.vegNonVeg = 'both';
                  widget.onFilterChanged(newState);
                },
              ),
            ],
          ] else ...[
            // Sort By Chip
            // _buildFilterChip(
            //   context,
            //   key: _sortByKey,
            //   label: "Sort by",
            //   icon: Icons.keyboard_arrow_down,
            //   hasTrailing: false,
            //   isSelected: widget.filterState.sortBy != 'relevance',
            //   onTap: () => _showSortPopup(context),
            // ),
            // 99 Store Chip
            if (widget.show99Store)
              _buildFilterChip(
                context,
                label: "99 Store",
                icon: Icons.local_offer,
                hasTrailing: false,
                isSelected: widget.filterState.store99 != 'all',
                onTap: () => _openFilterModal(context, '99store'),
              ),
            // Bolt Chip
            _buildFilterChip(
              context,
              label: "Bolt 15 mins",
              icon: Icons.flash_on,
              hasTrailing: false,
              isSelected: widget.filterState.isFastDelivery,
              onTap: () {
                final newState = widget.filterState.copy();
                newState.isFastDelivery = !newState.isFastDelivery;
                widget.onFilterChanged(newState);
              },
            ),
            // Offers Chip
            _buildFilterChip(
              context,
              label: "Offers",
              icon: Icons.percent,
              hasTrailing: false,
              isSelected: widget.filterState.offers != 'all',
              onTap: () => _openFilterModal(context, 'Offers'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconChip({
    required Widget child,
    required bool isSelected,
    required Color selectedBgColor,
    required Color selectedBorderColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.5.h),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.white,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(
            color: isSelected ? selectedBorderColor : Colors.black.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? selectedBorderColor.withOpacity(0.08)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.w),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    Key? key,
    required String label,
    required IconData icon,
    required bool hasTrailing,
    required bool isSelected,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.5.h),
      child: Container(
        key: key,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0E6) : Colors.white,
          borderRadius: BorderRadius.circular(8.w),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFC8019)
                : Colors.black.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFC8019).withOpacity(0.08)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.w),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasTrailing) ...[
                    Icon(
                      icon,
                      color: isSelected
                          ? const Color(0xFFFC8019)
                          : Colors.grey.shade600,
                      size: 13.w,
                    ),
                    SizedBox(width: 4.w),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFC8019)
                          : Colors.grey.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                  if (hasTrailing) ...[
                    if (badgeCount != null) ...[
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 5.w,
                          vertical: 1.h,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFC8019),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$badgeCount",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(width: 4.w),
                    Icon(
                      icon,
                      color: isSelected
                          ? const Color(0xFFFC8019)
                          : Colors.grey.shade600,
                      size: 13.w,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Reusable Anchored Swiggy-Style Sort Dropdown Card
// ----------------------------------------------------
class _SortPopupCard extends StatelessWidget {
  final Animation<double> animation;
  final SwiggyFilterState currentState;
  final List<FilterOption> sortOptions;
  final Function(SwiggyFilterState) onApply;

  const _SortPopupCard({
    required this.animation,
    required this.currentState,
    required this.sortOptions,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> fallbackOptions = [
      {"id": "relevance", "label": "Relevance (Default)"},
      {"id": "delivery_time", "label": "Delivery Time"},
      {"id": "rating", "label": "Rating"},
      {"id": "cost_low_high", "label": "Cost: Low to High"},
      {"id": "cost_high_low", "label": "Cost: High to Low"},
    ];

    final hasSortOptions = sortOptions.isNotEmpty;

    return Container(
      width: 220.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: hasSortOptions
            ? sortOptions.map((opt) {
                final bool isSelected = currentState.sortBy == opt.key;

                return GestureDetector(
                  onTap: () {
                    final newState = currentState.copy();
                    newState.sortBy = opt.key ?? '';
                    onApply(newState);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          opt.label ?? '',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.black87
                                : Colors.grey.shade700,
                          ),
                        ),
                        // Premium Swiggy radio selector
                        Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFC8019)
                                  : Colors.grey.shade400,
                              width: 1.8,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 9.w,
                                    height: 9.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFC8019),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()
            : fallbackOptions.map((opt) {
                final bool isSelected = currentState.sortBy == opt['id'];

                return GestureDetector(
                  onTap: () {
                    final newState = currentState.copy();
                    newState.sortBy = opt['id']!;
                    onApply(newState);
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          opt['label']!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.black87
                                : Colors.grey.shade700,
                          ),
                        ),
                        // Premium Swiggy radio selector
                        Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFC8019)
                                  : Colors.grey.shade400,
                              width: 1.8,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 9.w,
                                    height: 9.w,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFC8019),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
      ),
    );
  }
}

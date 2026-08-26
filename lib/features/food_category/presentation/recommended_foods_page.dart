import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/food_category/widget/Vendor_Item_Details_Card.dart';
import 'package:my_vegiz_flutter/features/cart/presentation/widgets/cart_conflict_dialog.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/bloc/restaurant_details_bloc.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/bloc/restaurant_details_event.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/bloc/restaurant_details_state.dart';
import 'package:my_vegiz_flutter/features/food_category/widget/Vendor_Item_Details_Card.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../routes/app_route_path.dart';
import '../data/models/vendor_home_section_model.dart';
import '../widget/veg_nonveg_filter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/core/storage/food_cart_db.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/food_cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/cart/data/cart_data.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';

class RecommendedFoodsPage extends StatefulWidget {
  final List<HomeSectionVendorItem> items;
  final String title;

  const RecommendedFoodsPage({
    super.key,
    required this.items,
    required this.title,
  });

  @override
  State<RecommendedFoodsPage> createState() => _RecommendedFoodsPageState();
}

class _RecommendedFoodsPageState extends State<RecommendedFoodsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'all'; // 'all', 'veg', 'nonveg'
  bool _isBoltActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTopSearchRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          // Elegant search bar container
          Expanded(
            child: Container(
              height: 46.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6), // Matches screenshot background
                borderRadius: BorderRadius.circular(16.w),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                children: [
                  // Back arrow button inside search bar
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black87,
                      size: 16,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Icon(Icons.search, color: Colors.grey.shade400, size: 20.w),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search in '${widget.title}'",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                      style: TextStyle(color: Colors.black87, fontSize: 13.sp),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade500,
                        size: 18.w,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                  // Divider
                  Container(
                    width: 1,
                    height: 20.h,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    Icons.mic,
                    color: const Color(0xFFC2410C),
                    size: 20.w,
                  ), // Premium brown-orange mic icon
                  SizedBox(width: 16.w),
                ],
              ),
            ),
          ),
          // SizedBox(width: 12.w),
          // Share/Guest button in soft purple background matching screenshot
          // Container(
          //   width: 46.h,
          //   height: 46.h,
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFF3E8FF), // Light purple
          //     borderRadius: BorderRadius.circular(16.w),
          //   ),
          //   child: const Center(
          //     child: Icon(
          //       Icons.person_add_alt_1,
          //       color: Color(0xFF8B5CF6), // Dark purple
          //       size: 20,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildMiniSwitch(bool isActive, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28.w,
      height: 16.h,
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10.w),
      ),
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 10.w,
        height: 10.w,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSwitchToggleChip({
    required Widget icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(width: 8.w),
            _buildMiniSwitch(isActive, activeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBoltFilterPill({
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(
            color: isSelected ? const Color(0xFFFC8019) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Bolt ",
              style: TextStyle(
                color: const Color(0xFFFC8019),
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            Icon(Icons.bolt, color: Colors.orange.shade800, size: 14.w),
            Text(
              " Food in 10-15 mins",
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotDeliverableButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(color: const Color(0xFFFFD2D7)),
      ),
      child: Text(
        'Not Deliverable',
        style: TextStyle(
          color: const Color(0xFF2C3E50),
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.w),
          border: Border.all(
            color: isSelected ? const Color(0xFFFC8019) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFC8019)
                  : Colors.grey.shade800,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersScrollRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          // Veg switch toggle chip
          _buildSwitchToggleChip(
            icon: const VegIcon(),
            isActive: _activeFilter == 'veg',
            activeColor: const Color(0xFF0F8A5F),
            onTap: () {
              setState(() {
                _activeFilter = _activeFilter == 'veg' ? 'all' : 'veg';
              });
            },
          ),
          SizedBox(width: 8.w),
          // Non-veg switch toggle chip
          _buildSwitchToggleChip(
            icon: const NonVegIcon(),
            isActive: _activeFilter == 'nonveg',
            activeColor: const Color(0xFFE43B3F),
            onTap: () {
              setState(() {
                _activeFilter = _activeFilter == 'nonveg' ? 'all' : 'nonveg';
              });
            },
          ),
          SizedBox(width: 8.w),
          // Bolt filter chip
          _buildBoltFilterPill(
            isSelected: _isBoltActive,
            onTap: () {
              setState(() {
                _isBoltActive = !_isBoltActive;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter and search list
    final filteredItems = widget.items.where((item) {
      // search query filter
      if (_searchQuery.isNotEmpty) {
        final name = item.itemName?.toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }

      // Veg / Non-Veg filter
      final type = item.cuisineType?.toLowerCase().trim();
      if (_activeFilter == 'veg' && type != 'veg' && type != 'both')
        return false;
      if (_activeFilter == 'nonveg' &&
          type != 'nonveg' &&
          type != 'non-veg' &&
          type != 'both')
        return false;

      // Bolt filter (15 mins preparation or delivery time)
      if (_isBoltActive) {
        final prepTime = item.preparationTime ?? 0;
        final deliveryTime = item.defaultDeliveryMinutes ?? 0;
        if (prepTime > 15 && deliveryTime > 15) return false;
      }

return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: BlocListener<FoodCartBloc, CartState>(
        listener: (context, state) {
          if (state is CartActionSuccess) {
            SnackbarUtils.showSuccessSnackbar(context, state.message);
          } else if (state is CartError) {
            SnackbarUtils.showErrorSnackbar(context, state.message);
          }
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              _buildTopSearchRow(context),
              SizedBox(height: 4.h),
              _buildFiltersScrollRow(),
              SizedBox(height: 12.h),
              // Divider
              Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: Colors.grey.shade200,
                              size: 64.w,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "No items found matching your filters",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 16.h,
                          childAspectRatio:
                              MediaQuery.of(context).size.width > 600
                                  ? 0.72
                                  : 0.65,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isDeliverable =
                              item.vendor?.isDeliverable ?? true;

                          final Widget cardContent = GestureDetector(
                            onTap: () {
                              VenderItemDetailsCard.show(
                                context,
                                item.id ?? 0,
                                isDeliverable,
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.w),
                                border: Border.all(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image stack with rounded corners
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16.w),
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 1.3,
                                          child: Image.network(
                                            item.primaryImage ?? '',
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors
                                                          .orange.shade50,
                                                      child: Icon(
                                                        Icons.fastfood,
                                                        color: Colors
                                                            .orange.shade200,
                                                        size: 32.w,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      if (!isDeliverable)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            child: Center(
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4.w,
                                                      ),
                                                ),
                                                child: Text(
                                                  'OUT OF AREA',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // Item Info
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.all(10.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                              children: [
                                              FoodTypeIcon(foodType: item.cuisineType),
                                              SizedBox(width: 6.w),
                                              Expanded(
                                                child: Text(
                                                  item.itemName ?? 'Dish',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 3.h),
                                          // Preparation time or description
                                          Text(
                                            item.description ??
                                                'Delicious food prepared fresh',
                                            style: TextStyle(
                                              fontSize: 9.5.sp,
                                              color: Colors.grey.shade500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Spacer(),
                                          // Row 3: Price Column and ADD Button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              // Price vertically stacked
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6.w,
                                                          vertical: 2.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFFFC000,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4.w,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "₹${item.salePrice?.toInt() ?? 0}",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // ADD Button matching screenshot
                                              item.itemStatus == false
                                                  ? _buildNotDeliverableButton()
                                                  : GestureDetector(
                                                      onTap: isDeliverable
                                                    ? () async {
                                                        final vendorId =
                                                                item.vendor
                                                                        ?.id ??
                                                                    30;
                                                        await CartValidationHelper
                                                            .checkAndShowConflictDialog(
                                                          context,
                                                          isAddingFood: true,
                                                          newVendorId: vendorId,
                                                          onClearAndAdd:
                                                              () async {
                                                            await FoodCartDb
                                                                .instance
                                                                .insertOrUpdateItem(
                                                                  vendorId:
                                                                      vendorId,
                                                                  vendorItemId:
                                                                      item.id ??
                                                                          0,
                                                                  quantity: 1,
                                                                  name:
                                                                      item.itemName ??
                                                                      'Dish',
                                                                  price:
                                                                      item.salePrice ??
                                                                      0.0,
                                                                  image:
                                                                      item.primaryImage,
                                                                  description:
                                                                      item.description,
                                                                  cuisineType:
                                                                      item.cuisineType,
                                                                );
                                                            try {
                                                              final loc =
                                                                  locationService
                                                                      .locationNotifier
                                                                      .value;
                                                              if (context
                                                                  .mounted) {
                                                                context
                                                                    .read<
                                                                      FoodCartBloc
                                                                    >()
                                                                    .add(
                                                                      GetCartListEvent(
                                                                        lat:
                                                                            loc?.lat ??
                                                                            0.0,
                                                                        lng:
                                                                            loc?.lng ??
                                                                            0.0,
                                                                      ),
                                                                    );
                                                              }
                                                            } catch (e) {
                                                              logger.w(
                                                                '⚠️ RecommendedFoodsPage: FoodCartBloc not found in context — $e',
                                                              );
                                                            }
                                                          },
                                                        );
                                                      }
                                                    : null,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 14.w,
                                                    vertical: 6.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.w,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.02,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    "ADD",
                                                    style: TextStyle(
                                                      color: isDeliverable
                                                          ? const Color(
                                                              0xFF0F8A5F,
                                                            )
                                                          : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ),
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

                          if (!isDeliverable) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ]),
                              child: Opacity(opacity: 0.8, child: cardContent),
                            );
                          }

                          return cardContent;
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

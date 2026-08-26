import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class FilterBottomSheet extends StatefulWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterApplied;

  const FilterBottomSheet({
    super.key,
    required this.activeFilter,
    required this.onFilterApplied,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String tempFilter;

  @override
  void initState() {
    super.initState();
    tempFilter = widget.activeFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter by Food Preference',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          SizedBox(height: 12.h),
          _buildFilterOption(
            title: 'Show All (Veg & Non-Veg)',
            subtitle: 'Show all food preferences',
            isActive: tempFilter == 'all',
            icon: Row(
              children: [
                const VegIcon(),
                SizedBox(width: 4.w),
                const NonVegIcon(),
              ],
            ),
            onTap: () {
              setState(() {
                tempFilter = 'all';
              });
            },
          ),
          SizedBox(height: 12.h),
          _buildFilterOption(
            title: 'Veg Only',
            subtitle: 'Show pure vegetarian restaurants',
            isActive: tempFilter == 'veg',
            icon: const VegIcon(),
            onTap: () {
              setState(() {
                tempFilter = 'veg';
              });
            },
          ),
          SizedBox(height: 12.h),
          _buildFilterOption(
            title: 'Non-Veg Only',
            subtitle: 'Show non-vegetarian delicacies',
            isActive: tempFilter == 'nonveg',
            icon: const NonVegIcon(),
            onTap: () {
              setState(() {
                tempFilter = 'nonveg';
              });
            },
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      tempFilter = 'all';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFilterApplied(tempFilter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC8019),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    'Apply Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required String title,
    required String subtitle,
    required bool isActive,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFC8019).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            color: isActive ? const Color(0xFFFC8019) : Colors.grey.shade200,
            width: isActive ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            icon,
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFFC8019)
                      : Colors.grey.shade400,
                  width: isActive ? 6.w : 2.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showFoodFilterBottomSheet(
  BuildContext context,
  String activeFilter,
  ValueChanged<String> onFilterApplied,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
    ),
    builder: (context) {
      return FilterBottomSheet(
        activeFilter: activeFilter,
        onFilterApplied: onFilterApplied,
      );
    },
  );
}

////////////////////////// veg_nonVeg_activeIcons.dart ////////////////////////////////////

class VegIcon extends StatelessWidget {
  const VegIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0F8A5F)),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Center(
        child: Container(
          width: 6.w,
          height: 6.w,
          decoration: const BoxDecoration(
            color: Color(0xFF0F8A5F),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class NonVegIcon extends StatelessWidget {
  const NonVegIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14.w,
      height: 14.w,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE43B3F)),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Center(
        child: Container(
          width: 6.w,
          height: 6.w,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 255, 0, 0),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class FoodTypeIcon extends StatelessWidget {
  final String? foodType;

  const FoodTypeIcon({super.key, this.foodType});

  @override
  Widget build(BuildContext context) {
    final type = foodType?.toLowerCase().trim();
    if (type == 'veg') {
      return const VegIcon();
    } else if (type == 'nonveg' || type == 'non-veg') {
      return const NonVegIcon();
    } else if (type == 'both') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VegIcon(),
          SizedBox(width: 4.w),
          const NonVegIcon(),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

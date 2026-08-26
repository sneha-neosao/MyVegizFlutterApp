import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/features/restaurant_details/data/models/vendor_details_model.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/distance_formatter.dart';

class RestaurantDarkHeader extends StatefulWidget {
  final Map<String, dynamic>? item;

  const RestaurantDarkHeader({super.key, this.item});

  @override
  State<RestaurantDarkHeader> createState() => _RestaurantDarkHeaderState();
}

class _RestaurantDarkHeaderState extends State<RestaurantDarkHeader> {
  bool _isFavourite = false;

  void _toggleFavourite() {
    setState(() {
      _isFavourite = !_isFavourite;
    });
  }

  void _handleShare() {
    final name =
        widget.item?["entity_name"] ?? widget.item?["name"] ?? "Restaurant";
    final area = widget.item?["area"] ?? widget.item?["city"] ?? "";
    final shareText = area.isNotEmpty
        ? "Check out $name in $area! Amazing food at great prices."
        : "Check out $name! Amazing food at great prices.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Share Restaurant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shareText,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.copy, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Copy to Clipboard (Mock)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFFFC8019),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showInfoBottomSheet() {
    final item = widget.item;

    final fullName = [
      if (item != null &&
          item["first_name"] != null &&
          item["first_name"].toString().isNotEmpty)
        item["first_name"],
      if (item != null &&
          item["middle_name"] != null &&
          item["middle_name"].toString().isNotEmpty)
        item["middle_name"],
      if (item != null &&
          item["last_name"] != null &&
          item["last_name"].toString().isNotEmpty)
        item["last_name"],
    ].join(' ').trim();

    final cuisinesList = item?["cuisines"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildVendorProfileSheet(item, fullName, cuisinesList);
      },
    );
  }

  Widget _buildVendorProfileSheet(
    Map<String, dynamic>? item,
    String fullName,
    dynamic cuisinesList,
  ) {
    final String entityName =
        item?["entity_name"] ?? item?["name"] ?? "Restaurant";
    final String? entityImage = item?["entity_image"] ?? item?["image"];
    final String? entityCategory = item?["entity_category_name"];
    final String? contact = item?["entity_contact"];
    final String? email = item?["email"];
    final String? area = item?["area"];
    final String? city = item?["city"];
    final String? address = item?["address"];
    final dynamic distanceKmRaw = item?["distanceKm"];
    final String? packagingType = item?["delivery_packaging_type"];
    final dynamic packagingPrice = item?["delivery_packaging_price"];
    final String? foodType = item?["food_type"] ?? item?["foodType"];
    final bool isServiceable =
        item?["isServiceable"] == true ||
        item?["is_serviceable"] == true ||
        item?["isDeliverable"] == true;
    final bool isDeliverable = item?["isDeliverable"] == true;
    final bool isActive = item?["is_active"] == true;
    final bool isPopular = item?["is_popular"] == true;

    // "Shivaji Nagar, Kolhapur"
    final locationLine = [
      if (area != null && area.isNotEmpty) area,
      if (city != null && city.isNotEmpty) city,
    ].join(', ');

    // Distance formatted
    String? distanceFormatted;
    if (distanceKmRaw != null) {
      distanceFormatted = formatDistance((distanceKmRaw as num).toDouble());
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // ── Scrollable content ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header image with gradient overlay ───────────
                      _buildHeaderImage(
                        entityImage,
                        entityName,
                        entityCategory,
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Status badges ────────────────────────────
                            _buildStatusBadges(
                              isServiceable: isServiceable,
                              isDeliverable: isDeliverable,
                              isActive: isActive,
                              isPopular: isPopular,
                            ),
                            const SizedBox(height: 20),

                            // ── Owner ─────────────────────────────────────
                            if (fullName.isNotEmpty) ...[
                              _buildSectionTitle('Owner'),
                              const SizedBox(height: 8),
                              _buildInfoTile(
                                icon: Icons.person_outline_rounded,
                                value: fullName,
                              ),
                              const SizedBox(height: 20),
                            ],

                            // ── Contact ───────────────────────────────────
                            if (contact != null || email != null) ...[
                              _buildSectionTitle('Contact'),
                              const SizedBox(height: 8),
                              if (contact != null)
                                _buildInfoTile(
                                  icon: Icons.phone_outlined,
                                  value: contact,
                                ),
                              if (contact != null && email != null)
                                const SizedBox(height: 8),
                              if (email != null)
                                _buildInfoTile(
                                  icon: Icons.email_outlined,
                                  value: email,
                                ),
                              const SizedBox(height: 20),
                            ],

                            // ── Location ──────────────────────────────────
                            _buildSectionTitle('Location'),
                            const SizedBox(height: 8),
                            if (locationLine.isNotEmpty)
                              _buildInfoTile(
                                icon: Icons.location_on_outlined,
                                value: locationLine,
                              ),
                            if (distanceFormatted != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoTile(
                                icon: Icons.directions_walk_outlined,
                                value: '$distanceFormatted away',
                                valueColor: const Color(0xFF0F8A5F),
                              ),
                            ],
                            if (address != null && address.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoTile(
                                icon: Icons.home_outlined,
                                value: address,
                                valueColor: Colors.grey.shade700,
                              ),
                            ],
                            const SizedBox(height: 20),

                            // ── Food Type ─────────────────────────────────
                            if (foodType != null) ...[
                              _buildSectionTitle('Food Type'),
                              const SizedBox(height: 10),
                              _buildFoodTypeRow(foodType),
                              const SizedBox(height: 20),
                            ],

                            // ── Cuisines ──────────────────────────────────
                            if (cuisinesList is List &&
                                cuisinesList.isNotEmpty) ...[
                              _buildSectionTitle('Cuisines'),
                              const SizedBox(height: 10),
                              _buildCuisineChips(cuisinesList),
                              const SizedBox(height: 20),
                            ],

                            // ── Delivery & Packaging ──────────────────────
                            if (packagingType != null ||
                                packagingPrice != null) ...[
                              _buildSectionTitle('Delivery & Packaging'),
                              const SizedBox(height: 8),
                              if (packagingType != null)
                                _buildInfoTile(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Packaging Type',
                                  value: packagingType,
                                ),
                              if (packagingPrice != null) ...[
                                const SizedBox(height: 8),
                                _buildInfoTile(
                                  icon: Icons.currency_rupee,
                                  label: 'Packaging Charge',
                                  value:
                                      '₹${(packagingPrice as num).toStringAsFixed(0)}',
                                ),
                              ],
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header image with gradient & close button ────────────────────────────
  Widget _buildHeaderImage(
    String? imageUrl,
    String entityName,
    String? entityCategory,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
        // Gradient overlay
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.4, 1.0],
              ),
            ),
          ),
        ),
        // Close button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
        // Name & category pill at bottom
        Positioned(
          left: 20,
          right: 56,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entityName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (entityCategory != null && entityCategory.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC8019).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entityCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFF1A1A2E),
      child: const Icon(Icons.restaurant, color: Colors.white30, size: 56),
    );
  }

  // ── Status badge row ─────────────────────────────────────────────────────
  Widget _buildStatusBadges({
    required bool isServiceable,
    required bool isDeliverable,
    required bool isActive,
    required bool isPopular,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildBadge(
          icon: Icons.check_circle_outline,
          label: isServiceable ? 'Serviceable' : 'Not Serviceable',
          bgColor: isServiceable
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFF3F3),
          textColor: isServiceable
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
        _buildBadge(
          icon: Icons.delivery_dining_outlined,
          label: isDeliverable ? 'Deliverable' : 'Not Deliverable',
          bgColor: isDeliverable
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFF3F3),
          textColor: isDeliverable
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
        _buildBadge(
          icon: Icons.store_outlined,
          label: isActive ? 'Active' : 'Inactive',
          bgColor: isActive ? const Color(0xFFE3F2FD) : const Color(0xFFFAFAFA),
          textColor: isActive ? const Color(0xFF1565C0) : Colors.grey,
        ),
        if (isPopular)
          _buildBadge(
            icon: Icons.local_fire_department_outlined,
            label: 'Popular',
            bgColor: const Color(0xFFFFF3E0),
            textColor: const Color(0xFFE65100),
          ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Info tile (icon + optional sub-label + value) ─────────────────────────
  Widget _buildInfoTile({
    required IconData icon,
    String? label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFC8019).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFC8019), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Food type row ────────────────────────────────────────────────────────
  Widget _buildFoodTypeRow(String foodType) {
    final ft = foodType.toLowerCase();
    final bool showVeg = ft == 'veg' || ft == 'both';
    final bool showNonVeg = ft == 'non-veg' || ft == 'nonveg' || ft == 'both';
    return Row(
      children: [
        if (showVeg) ...[
          _buildFoodTypeChip(
            label: 'Veg',
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
            dotColor: const Color(0xFF2E7D32),
          ),
          if (showNonVeg) const SizedBox(width: 10),
        ],
        if (showNonVeg)
          _buildFoodTypeChip(
            label: 'Non-Veg',
            color: const Color(0xFFC62828),
            bgColor: const Color(0xFFFFF3F3),
            dotColor: const Color(0xFFC62828),
          ),
      ],
    );
  }

  Widget _buildFoodTypeChip({
    required String label,
    required Color color,
    required Color bgColor,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              border: Border.all(color: dotColor, width: 1.5),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cuisine chips with network images ────────────────────────────────────
  Widget _buildCuisineChips(List cuisinesList) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cuisinesList.map<Widget>((e) {
        String name = '';
        String? imageUrl;
        if (e is VendorCuisineMapping) {
          name = e.cuisine?.cuisineName ?? '';
          imageUrl = e.cuisine?.image;
        } else if (e is Map) {
          name = e['cuisine']?['cuisine_name'] ?? '';
          imageUrl = e['cuisine']?['image'];
        }
        if (name.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                const Icon(Icons.restaurant, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN HEADER WIDGET
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final String? imageUrl = item?["entity_image"] ?? item?["image"];
    final dynamic ratingVal = item?["rating"] ?? item?["avg_rating"] ?? item?["avgRating"];
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 680;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isCompact = isSmallScreen || isLandscape;

    final double spacing12 = isCompact ? 4.0 : 8.0;
    final double spacing16 = isCompact ? 6.0 : 12.0;
    final double spacing20 = isCompact ? 8.0 : 16.0;
    final double cardPadding = isCompact ? 10.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF101014),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /*GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),*/
                            const Spacer(),
                            Row(
                              children: [
                                /*Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 8.w : 12.w,
                                    vertical: isCompact ? 4.h : 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(color: Colors.white60),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.group_add_outlined,
                                        color: Colors.white,
                                        size: isCompact ? 13.sp : 16.sp,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'GROUP ORDER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isCompact ? 10.sp : 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),*/
                                /*PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'favourite') {
                                      _toggleFavourite();
                                    } else if (value == 'share') {
                                      _handleShare();
                                    } else if (value == 'info') {
                                      _showInfoBottomSheet();
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        PopupMenuItem<String>(
                                          value: 'favourite',
                                          child: Row(
                                            children: [
                                              Icon(
                                                _isFavourite
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: _isFavourite
                                                    ? Colors.red
                                                    : Colors.black87,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('Favourite'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'share',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.share, color: Colors.black87),
                                              SizedBox(width: 8),
                                              Text('Share'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'info',
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.black87,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Info'),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),*/
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: spacing12),
                    // ── Restaurant White Card ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item?["entity_name"] ??
                                  item?["name"] ??
                                  "Restaurant",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF001F3F), // Dark blue/black as in image
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            if (ratingVal != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF24963F),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$ratingVal (${item?["ratingsCount"] ?? item?["reviews_count"] ?? item?["totalReviews"] ?? item?["total_reviews"] ?? "0"} ratings)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              item?["entity_category_name"] ?? "",
                              style: const TextStyle(
                                color: Color(0xFFFF5200), // Brighter orange
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Outlet ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF4A4A4A),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    [
                                      if (item?["area"] != null &&
                                          item!["area"].toString().isNotEmpty)
                                        item["area"],
                                      if (item?["city"] != null &&
                                          item!["city"].toString().isNotEmpty)
                                        item["city"],
                                    ].join(', '),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Address: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Color(0xFF4A4A4A),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item?["address"] ?? "",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isCompact ? 4.0 : 8.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

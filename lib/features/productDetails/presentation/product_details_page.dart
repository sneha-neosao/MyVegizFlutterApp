import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_vegiz_flutter/core/api/api/api_url.dart';
import 'package:my_vegiz_flutter/core/utils/location_service.dart';
import 'package:my_vegiz_flutter/core/utils/logger.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_state.dart';
import 'package:my_vegiz_flutter/widgets/shimmer_placeholder.dart';
import 'package:my_vegiz_flutter/core/models/common_models.dart';
import 'package:my_vegiz_flutter/features/productDetails/data/models/product_details_model.dart';
import 'package:my_vegiz_flutter/features/cart/presentation/widgets/cart_conflict_dialog.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_bloc.dart';
import 'package:my_vegiz_flutter/features/cart/bloc/cart_event.dart';
import 'package:my_vegiz_flutter/features/cart/data/models/cart_model.dart';
import 'package:my_vegiz_flutter/core/utils/snackbar_utils.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_bloc.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_event.dart';
import 'package:my_vegiz_flutter/features/wishlist/bloc/wishlist_state.dart';
import 'package:my_vegiz_flutter/core/utils/responsive_utils.dart';
import 'package:my_vegiz_flutter/widgets/floating_view_cart_bar.dart';
import 'package:my_vegiz_flutter/config/injector_conf.dart';
import 'package:my_vegiz_flutter/features/productDetails/domain/usecase/product_details_usecase.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final String slug;
  final int? initialVariantId;
  final List<dynamic>? productsList;
  final int initialIndex;

  const ProductDetailsPage({
    super.key,
    required this.slug,
    this.initialVariantId,
    this.productsList,
    this.initialIndex = 0,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final PageController _pageController;
  late final List<Map<String, dynamic>> _items;
  int _currentIndex = 0;

  final Map<String, ProductData> _cachedProducts = {};
  final Map<String, bool> _loadingMap = {};
  final Map<String, String?> _errorMap = {};
  final Map<String, SharedVariantModel?> _selectedVariantMap = {};
  final Map<String, int> _imageIndexMap = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final Map<int, bool> _cartActionLoading = {};

  @override
  void initState() {
    super.initState();

    // Prepare items list from sibling products or fallback to single initial product
    if (widget.productsList != null && widget.productsList!.isNotEmpty) {
      _items = widget.productsList!.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else {
          return {
            'slug': item.toString(),
            'variantId': widget.initialVariantId,
          };
        }
      }).toList();
      _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    } else {
      _items = [
        {
          'slug': widget.slug,
          'variantId': widget.initialVariantId,
        }
      ];
      _currentIndex = 0;
    }

    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.93,
    );

    _fetchProductAt(_currentIndex);
    if (_currentIndex + 1 < _items.length) {
      _fetchProductAt(_currentIndex + 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getSlugAt(int index) {
    if (index >= 0 && index < _items.length) {
      return _items[index]['slug'] as String? ?? widget.slug;
    }
    return widget.slug;
  }

  int? _getVariantIdAt(int index) {
    if (index >= 0 && index < _items.length) {
      return _items[index]['variantId'] as int? ?? widget.initialVariantId;
    }
    return widget.initialVariantId;
  }

  Future<void> _fetchProductAt(int index) async {
    final slug = _getSlugAt(index);
    if (slug.isEmpty) return;
    if (_cachedProducts.containsKey(slug) || _loadingMap[slug] == true) return;

    setState(() {
      _loadingMap[slug] = true;
      _errorMap[slug] = null;
    });

    try {
      final loc = locationService.locationNotifier.value;
      final useCase = getIt<ProductDetailsUseCase>();
      final response = await useCase(
        slug: slug,
        lat: loc?.lat,
        lng: loc?.lng,
      );

      if (!mounted) return;

      if (response.data.isNotEmpty) {
        final product = response.data.first;
        final targetVariantId = _getVariantIdAt(index);

        SharedVariantModel? selected;
        if (product.variants.isNotEmpty) {
          if (targetVariantId != null) {
            selected = product.variants.firstWhere(
              (v) => v.id == targetVariantId,
              orElse: () => product.variants.firstWhere(
                (v) => v.isDeliverable,
                orElse: () => product.variants.first,
              ),
            );
          } else {
            selected = product.variants.firstWhere(
              (v) => v.isDeliverable,
              orElse: () => product.variants.first,
            );
          }
        }

        setState(() {
          _cachedProducts[slug] = product;
          _selectedVariantMap[slug] = selected;
          _loadingMap[slug] = false;
        });
      } else {
        setState(() {
          _loadingMap[slug] = false;
          _errorMap[slug] = response.message ?? 'Product not found';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMap[slug] = false;
        _errorMap[slug] = e.toString();
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _fetchProductAt(index);
    if (index + 1 < _items.length) {
      _fetchProductAt(index + 1);
    }
    if (index - 1 >= 0) {
      _fetchProductAt(index - 1);
    }
  }

  Future<void> _shareProduct(ProductData product, SharedVariantModel? variant) async {
    if (!mounted) return;

    SnackbarUtils.showSuccessSnackbar(context, 'Preparing product to share...');

    String? primaryImageUrl;
    if (product.images.isNotEmpty) {
      final primary = product.images.firstWhere(
        (img) => img.isPrimary,
        orElse: () => product.images.first,
      );
      primaryImageUrl = primary.productImage;
    }

    File? tempFile;
    if (primaryImageUrl != null && primaryImageUrl.isNotEmpty) {
      try {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          primaryImageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          final tempDir = await getTemporaryDirectory();
          String extension = 'png';
          try {
            final uri = Uri.parse(primaryImageUrl);
            final pathSegments = uri.pathSegments;
            if (pathSegments.isNotEmpty && pathSegments.last.contains('.')) {
              extension = pathSegments.last.split('.').last;
            }
          } catch (_) {}

          tempFile = File('${tempDir.path}/product_share_${product.id}.$extension');
          await tempFile.writeAsBytes(response.data!);
        }
      } catch (e) {
        logger.e('Error downloading product image for sharing: $e');
      }
    }

    final buffer = StringBuffer();
    buffer.writeln(product.productName);

    final price = variant?.sellingPrice ?? 0.0;
    if (price > 0) {
      final formattedPrice = price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2);
      buffer.writeln('₹$formattedPrice');
    }

    final description = product.longDescription.isNotEmpty
        ? product.longDescription
        : product.shortDescription;
    if (description.isNotEmpty) {
      buffer.writeln('\n$description');
    }

    if (product.slug.isNotEmpty && product.uuId != null) {
      buffer.writeln('\nLink: ${ApiUrl.baseUrl}/web/products/share/${product.uuId}');
    }

    buffer.writeln('\nAvailable on MyVegiz');

    if (tempFile != null && await tempFile.exists()) {
      await Share.shareXFiles([XFile(tempFile.path)], text: buffer.toString());
    } else {
      await Share.share(buffer.toString());
    }
  }

  String _variantLabel(SharedVariantModel v) {
    final qty = v.quantity != null
        ? (v.quantity! % 1 == 0 ? v.quantity!.toInt().toString() : v.quantity!.toString())
        : '';
    final subUom = v.subUomShortName ?? v.uomShortName ?? v.subUomName ?? '';
    return '$qty $subUom'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.78),
      body: SafeArea(
        child: Stack(
          children: [
            // Horizontally Scrollable Product Cards (sized to clear bottom cart bar)
            Padding(
              padding: EdgeInsets.fromLTRB(0, 8.h, 0, 76.h),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final slug = _getSlugAt(index);
                  return _buildProductCardPage(slug, index);
                },
              ),
            ),

            // Floating View Cart Bar at Bottom
            Positioned(
              bottom: 12.h,
              left: 0,
              right: 0,
              child: const FloatingViewCartBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCardPage(String slug, int index) {
    final product = _cachedProducts[slug];
    final isLoading = _loadingMap[slug] == true && product == null;
    final errorMessage = _errorMap[slug];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoading
          ? _buildCardShimmer()
          : (errorMessage != null
              ? _buildCardError(slug, errorMessage, index)
              : (product != null ? _buildCardContent(product, slug) : const SizedBox.shrink())),
    );
  }

  Widget _buildCardShimmer() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerPlaceholder.rounded(
            height: 280.h,
            width: double.infinity,
            borderRadius: 0,
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder.rounded(height: 16.h, width: 90.w),
                SizedBox(height: 8.h),
                ShimmerPlaceholder.rounded(height: 22.h, width: 220.w),
                SizedBox(height: 8.h),
                ShimmerPlaceholder.rounded(height: 16.h, width: 100.w),
                SizedBox(height: 12.h),
                ShimmerPlaceholder.rounded(height: 20.h, width: 140.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardError(String slug, String message, int index) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48.w, color: Colors.red.shade400),
            SizedBox(height: 12.h),
            Text(
              'Could not load product',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E242B)),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _fetchProductAt(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.w)),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(ProductData product, String slug) {
    final selectedVariant = _selectedVariantMap[slug] ??
        (product.variants.isNotEmpty ? product.variants.first : null);

    final sellingPrice = selectedVariant?.sellingPrice ?? 0.0;
    final actualPrice = selectedVariant?.actualPrice ?? 0.0;
    final discount = actualPrice > sellingPrice && actualPrice > 0
        ? (((actualPrice - sellingPrice) / actualPrice) * 100).toInt()
        : 0;

    final images = product.images;
    final currentImageIndex = _imageIndexMap[slug] ?? 0;
    final scrollController = _scrollControllers.putIfAbsent(slug, () => ScrollController());

    final variantLabel = selectedVariant != null ? _variantLabel(selectedVariant) : '1 unit';

    return Stack(
      children: [
        // Scrollable Card Content
        SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Image Carousel ──
              Stack(
                children: [
                  Container(
                    color: Colors.white,
                    height: 240.h,
                    width: double.infinity,
                    child: images.isNotEmpty
                        ? PageView.builder(
                            itemCount: images.length,
                            onPageChanged: (idx) {
                              setState(() => _imageIndexMap[slug] = idx);
                            },
                            itemBuilder: (context, idx) {
                              final imgUrl = images[idx].productImage;
                              return imgUrl.isNotEmpty
                                  ? Image.network(
                                      imgUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.white,
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 50.w,
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 50.w,
                                        color: Colors.grey.shade300,
                                      ),
                                    );
                            },
                          )
                        : Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.image_outlined,
                              size: 50.w,
                              color: Colors.grey.shade300,
                            ),
                          ),
                  ),

                  // Indicator Dots at Bottom Center
                  if (images.length > 1)
                    Positioned(
                      bottom: 12.h,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (idx) {
                          final isActive = idx == currentImageIndex;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                            width: isActive ? 6.5.w : 4.5.w,
                            height: isActive ? 6.5.w : 4.5.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF94A3B8).withValues(alpha: 0.6),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Top Overlay Bar: Back/Dismiss Button on Left, Wishlist & Share on Right
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBE3D5).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 17.w,
                          color: const Color(0xFF2D3139),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Wishlist Button
                        BlocConsumer<WishlistBloc, WishlistState>(
                          listenWhen: (prev, curr) {
                            return (curr is WishlistActionSuccess && curr.productId == product.id) ||
                                curr is WishlistActionError;
                          },
                          listener: (context, state) {
                            if (state is WishlistActionSuccess) {
                              if (state.isSaved) {
                                SnackbarUtils.showSuccessSnackbar(context, state.message);
                              } else {
                                SnackbarUtils.showErrorSnackbar(context, state.message);
                              }
                            } else if (state is WishlistActionError) {
                              SnackbarUtils.showErrorSnackbar(context, state.message);
                            }
                          },
                          builder: (context, state) {
                            final blocIds = context.read<WishlistBloc>().wishlistedProductIds;
                            final isSaved = blocIds.isNotEmpty
                                ? blocIds.contains(product.id)
                                : product.isWishlisted;

                            return GestureDetector(
                              onTap: () {
                                context.read<WishlistBloc>().add(ToggleWishlistEvent(product.id));
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE3D5).withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isSaved ? Icons.favorite : Icons.favorite_border,
                                  size: 18.w,
                                  color: isSaved ? Colors.red : const Color(0xFF2D3139),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8.w),

                        // Share Button
                        GestureDetector(
                          onTap: () => _shareProduct(product, selectedVariant),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBE3D5).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.share_outlined,
                              size: 18.w,
                              color: const Color(0xFF2D3139),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Product Information White Box ──
              Container(
                margin: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 6.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E242B),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Weight / Unit text
                    Text(
                      variantLabel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${sellingPrice.toInt()}',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E242B),
                          ),
                        ),
                        if (actualPrice > sellingPrice) ...[
                          SizedBox(width: 6.w),
                          Text(
                            'MRP ₹${actualPrice.toInt()}',
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (discount > 0) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4.w),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: TextStyle(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5.sp,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Variants Section (if multiple variants) ──
              if (product.variants.length > 1)
                Container(
                  margin: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 6.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Variant',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E242B),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: product.variants.map((v) {
                          final isSelected = selectedVariant?.id == v.id;
                          final label = _variantLabel(v);
                          final vSelling = v.sellingPrice ?? 0.0;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVariantMap[slug] = v;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEAF7EE) : Colors.white,
                                borderRadius: BorderRadius.circular(10.w),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF334155),
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 11.5.sp,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '₹${vSelling.toInt()}',
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              // ── Description Section ──
              if (product.longDescription.isNotEmpty || product.shortDescription.isNotEmpty)
                Container(
                  margin: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 6.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E242B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        product.longDescription.isNotEmpty
                            ? product.longDescription
                            : product.shortDescription,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

              // Clearance for sticky bottom action bar
              SizedBox(height: 90.h),
            ],
          ),
        ),

        // ── Sticky Bottom Action Bar inside the Card ──
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildStickyBottomBar(product, selectedVariant, variantLabel, sellingPrice, actualPrice),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar(
    ProductData product,
    SharedVariantModel? selectedVariant,
    String variantLabel,
    double sellingPrice,
    double actualPrice,
  ) {
    final variantId = selectedVariant?.id;
    final isDeliverable = selectedVariant != null && selectedVariant.isDeliverable;

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.w),
          bottomRight: Radius.circular(24.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          CartData? cartData;
          if (cartState is CartLoaded) {
            cartData = cartState.cartData;
          } else if (cartState is CartActionSuccess) {
            cartData = cartState.cartData;
          } else if (cartState is CartLoading) {
            cartData = cartState.cartData;
          } else if (cartState is CartError) {
            cartData = cartState.cartData;
          }

          CartItem? cartItem;
          if (cartData != null && cartData.items != null && variantId != null) {
            for (final item in cartData.items!) {
              if (item.productVariantId == variantId) {
                cartItem = item;
                break;
              }
            }
          }

          final bool isCartStateAvailable = (cartState is CartLoaded ||
                  cartState is CartActionSuccess ||
                  cartState is CartLoading ||
                  cartState is CartError) &&
              cartData != null;

          int effectiveQuantity = 0;
          if (cartItem != null) {
            effectiveQuantity = cartItem.quantity;
          } else {
            effectiveQuantity = !isCartStateAvailable ? (selectedVariant?.cartQuantity ?? 0) : 0;
          }

          final bool isBtnLoading = _cartActionLoading[variantId ?? 0] == true;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Unit, Price, Taxes
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variantLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E242B),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${sellingPrice.toInt()}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E242B),
                          ),
                        ),
                        if (actualPrice > sellingPrice) ...[
                          SizedBox(width: 5.w),
                          Text(
                            'MRP ₹${actualPrice.toInt()}',
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Inclusive of all taxes',
                      style: TextStyle(
                        fontSize: 8.5.sp,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Action Button / Stepper
              if (!isDeliverable)
                Container(
                  height: 38.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF0),
                    borderRadius: BorderRadius.circular(10.w),
                    border: Border.all(color: const Color(0xFFFFD2D7)),
                  ),
                  child: Text(
                    'Not deliverable',
                    style: TextStyle(
                      color: const Color(0xFFC62828),
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (effectiveQuantity > 0)
                Container(
                  width: 95.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10.w),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isBtnLoading
                      ? const Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (variantId == null) return;
                                final loc = locationService.locationNotifier.value;
                                setState(() => _cartActionLoading[variantId] = true);

                                if (cartItem != null) {
                                  if (cartItem.quantity > 1) {
                                    context.read<CartBloc>().add(
                                      UpdateCartEvent(
                                        cartItemId: cartItem.id,
                                        quantity: cartItem.quantity - 1,
                                        lat: loc?.lat ?? 0.0,
                                        lng: loc?.lng ?? 0.0,
                                      ),
                                    );
                                  } else {
                                    context.read<CartBloc>().add(
                                      RemoveCartItemEvent(cartItem.id),
                                    );
                                  }
                                } else if (effectiveQuantity > 1) {
                                  context.read<CartBloc>().add(
                                    AddToCartEvent(
                                      productVariantId: variantId,
                                      quantity: effectiveQuantity - 1,
                                      lat: loc?.lat ?? 0.0,
                                      lng: loc?.lng ?? 0.0,
                                    ),
                                  );
                                } else {
                                  context.read<CartBloc>().add(
                                    AddToCartEvent(
                                      productVariantId: variantId,
                                      quantity: 0,
                                      lat: loc?.lat ?? 0.0,
                                      lng: loc?.lng ?? 0.0,
                                    ),
                                  );
                                }

                                Future.delayed(const Duration(milliseconds: 600), () {
                                  if (mounted) setState(() => _cartActionLoading[variantId] = false);
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                child: const Icon(Icons.remove, color: Colors.white, size: 18),
                              ),
                            ),
                            Text(
                              '$effectiveQuantity',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5.sp,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (variantId == null) return;
                                final loc = locationService.locationNotifier.value;
                                setState(() => _cartActionLoading[variantId] = true);

                                if (cartItem != null) {
                                  context.read<CartBloc>().add(
                                    UpdateCartEvent(
                                      cartItemId: cartItem.id,
                                      quantity: cartItem.quantity + 1,
                                      lat: loc?.lat ?? 0.0,
                                      lng: loc?.lng ?? 0.0,
                                    ),
                                  );
                                } else {
                                  context.read<CartBloc>().add(
                                    AddToCartEvent(
                                      productVariantId: variantId,
                                      quantity: effectiveQuantity + 1,
                                      lat: loc?.lat ?? 0.0,
                                      lng: loc?.lng ?? 0.0,
                                    ),
                                  );
                                }

                                Future.delayed(const Duration(milliseconds: 600), () {
                                  if (mounted) setState(() => _cartActionLoading[variantId] = false);
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                child: const Icon(Icons.add, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                )
              else
                GestureDetector(
                  onTap: isBtnLoading
                      ? null
                      : () {
                          if (variantId == null) return;
                          final loc = locationService.locationNotifier.value;
                          final lat = loc?.lat ?? 0.0;
                          final lng = loc?.lng ?? 0.0;

                          setState(() => _cartActionLoading[variantId] = true);

                          CartValidationHelper.checkAndShowConflictDialog(
                            context,
                            isAddingFood: false,
                            onClearAndAdd: () {
                              context.read<CartBloc>().add(
                                AddToCartEvent(
                                  productVariantId: variantId,
                                  quantity: 1,
                                  lat: lat,
                                  lng: lng,
                                ),
                              );
                            },
                          ).then((success) {
                            if (!success && mounted) {
                              setState(() => _cartActionLoading[variantId] = false);
                            } else {
                              Future.delayed(const Duration(milliseconds: 600), () {
                                if (mounted) setState(() => _cartActionLoading[variantId] = false);
                              });
                            }
                          });
                        },
                  child: Container(
                    width: 90.w,
                    height: 38.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.w),
                      border: Border.all(color: const Color(0xFF2E7D32), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isBtnLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                              ),
                            )
                          : Text(
                              'ADD',
                              style: TextStyle(
                                color: const Color(0xFF2E7D32),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

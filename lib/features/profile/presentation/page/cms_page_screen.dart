import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../bloc/cms_page/cms_page_bloc.dart';
import '../../bloc/cms_page/cms_page_event.dart';
import '../../bloc/cms_page/cms_page_state.dart';

class CmsPageScreen extends StatefulWidget {
  final String pageKey;
  final String? customTitle;

  const CmsPageScreen({super.key, required this.pageKey, this.customTitle});

  @override
  State<CmsPageScreen> createState() => _CmsPageScreenState();
}

class _CmsPageScreenState extends State<CmsPageScreen> {
  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  void _fetchPage() {
    context.read<CmsPageBloc>().add(FetchCmsPageEvent(widget.pageKey));
  }

  @override
  Widget build(BuildContext context) {
    final String defaultTitle = widget.customTitle ?? (widget.pageKey == 'privacy' 
        ? 'Privacy & Security' 
        : widget.pageKey == 'terms'
            ? 'Terms & Conditions'
            : 'Refund Policy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            logger.i("📄 CmsPageScreen: Back pressed for ${widget.pageKey}");
            context.pop();
          },
        ),
        title: BlocBuilder<CmsPageBloc, CmsPageState>(
          builder: (context, state) {
            if (widget.customTitle != null) {
              return Text(
                widget.customTitle!,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            if (state is CmsPageLoaded) {
              return Text(
                state.page.metaTitle ?? defaultTitle,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
            return Text(
              defaultTitle,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchPage(),
          color: Colors.green,
          child: BlocBuilder<CmsPageBloc, CmsPageState>(
            builder: (context, state) {
              if (state is CmsPageLoading || state is CmsPageInitial) {
                return _buildShimmerLoading();
              }

              if (state is CmsPageError) {
                return _buildErrorState(state.message);
              }

              if (state is CmsPageEmpty) {
                return _buildEmptyState();
              }

              if (state is CmsPageLoaded) {
                final page = state.page;
                final content = page.pageContent ?? '';

                if (content.trim().isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle
                      if (page.subtitle != null && page.subtitle!.isNotEmpty) ...[
                        Text(
                          page.subtitle!,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      // Meta Description / Summary
                      if (page.metaDescription != null && page.metaDescription!.isNotEmpty) ...[
                        Text(
                          page.metaDescription!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Divider(color: Colors.grey.shade300, thickness: 0.5),
                        SizedBox(height: 16.h),
                      ],
                      // HTML parsed content
                      HtmlText(htmlText: content),
                      SizedBox(height: 32.h),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerPlaceholder.rounded(height: 30.h, width: 220.w),
          SizedBox(height: 12.h),
          ShimmerPlaceholder.rounded(height: 16.h, width: 280.w),
          SizedBox(height: 24.h),
          Divider(color: Colors.grey.shade200, thickness: 1),
          SizedBox(height: 24.h),
          ShimmerPlaceholder.rounded(height: 20.h, width: 140.w),
          SizedBox(height: 12.h),
          ShimmerPlaceholder.rounded(height: 100.h),
          SizedBox(height: 24.h),
          ShimmerPlaceholder.rounded(height: 20.h, width: 180.w),
          SizedBox(height: 12.h),
          ShimmerPlaceholder.rounded(height: 80.h),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 60.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            SizedBox(height: 16.h),
            Text(
              "Failed to load content",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _fetchPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.w),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                "Retry",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 60.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16.h),
            Text(
              "No Content Available",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "There is currently no information published on this page.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HtmlText extends StatelessWidget {
  final String htmlText;

  const HtmlText({super.key, required this.htmlText});

  @override
  Widget build(BuildContext context) {
    // Strip common empty tags and translate breaks
    String cleaned = htmlText
        .replaceAll('<p></p>', '')
        .replaceAll('<p>&nbsp;</p>', '')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n');

    // Split text into structural blocks using headings and paragraphs
    final blocks = cleaned.split(RegExp(r'(?=<h1>|<h2>|<h3>|<p>|<li>|<ul>|<div>)'));

    final List<Widget> widgets = [];

    for (var block in blocks) {
      if (block.trim().isEmpty) continue;

      bool isHeading = block.startsWith(RegExp(r'<(h1|h2|h3)'));
      bool isBullet = block.startsWith('<li>');

      // Strip tag tags to leave content and match inline text modifications
      final List<TextSpan> spans = [];
      final regExp = RegExp(r'<[^>]*>|[^<]+');
      final matches = regExp.allMatches(block);

      bool isBold = false;

      for (var match in matches) {
        final text = match.group(0) ?? '';
        if (text.startsWith('<')) {
          final tag = text.toLowerCase();
          if (tag.startsWith('<strong') || tag.startsWith('<b')) {
            isBold = true;
          } else if (tag.startsWith('</strong') || tag.startsWith('</b')) {
            isBold = false;
          }
        } else {
          // Decode simple HTML entities if any
          final decodedText = text
              .replaceAll('&nbsp;', ' ')
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"');

          if (decodedText.trim().isNotEmpty || decodedText == ' ') {
            spans.add(
              TextSpan(
                text: decodedText,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }
        }
      }

      if (spans.isEmpty) continue;

      if (isHeading) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 18.h, bottom: 8.h),
            child: RichText(
              text: TextSpan(
                children: spans,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBullet) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, right: 8.w, left: 4.w),
                    child: const Icon(Icons.circle, size: 6, color: Colors.black54),
                  ),
                ],
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: spans,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

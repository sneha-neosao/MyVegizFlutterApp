import 'package:flutter/material.dart';

class StickySearchBar extends StatelessWidget {
  final bool isScrolledToTop;
  final Map<String, dynamic>? item;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;

  const StickySearchBar({
    super.key,
    required this.isScrolledToTop,
    this.item,
    this.searchController,
    this.onSearchChanged,
    this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  if (isScrolledToTop) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: isScrolledToTop
                            ? (item?["name"] != null
                                  ? 'Search in ${item!["name"]}'
                                  : 'Search in Domino\'s Pizza')
                            : 'Search for dishes',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (searchController != null && searchController!.text.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onSearchClear,
                      child: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.search, color: Colors.grey.shade600, size: 24),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.mic_none,
                    color: Color(0xFFF16E2B),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          /*if (isScrolledToTop) ...[
            const SizedBox(width: 12),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                color: Colors.purple,
                size: 26,
              ),
            ),
          ],*/
        ],
      ),
    );
  }
}

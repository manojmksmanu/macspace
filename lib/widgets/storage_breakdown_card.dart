import 'package:flutter/material.dart';
import '../models/storage_item.dart';

class StorageBreakdownCard extends StatefulWidget {
  final List<StorageCategory> categories;
  final List<StorageCategory> fileTypes;

  const StorageBreakdownCard({
    super.key,
    required this.categories,
    required this.fileTypes,
  });

  @override
  State<StorageBreakdownCard> createState() => _StorageBreakdownCardState();
}

class _StorageBreakdownCardState extends State<StorageBreakdownCard> {
  bool _showCategories = true;

  @override
  Widget build(BuildContext context) {
    final list = _showCategories ? widget.categories : widget.fileTypes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Storage Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // Segmented Switch Toggle Pill
          Container(
            height: 32,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCategories = true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _showCategories
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: _showCategories
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _showCategories
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showCategories = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_showCategories
                            ? const Color(0xFF2563EB)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'File Types',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: !_showCategories
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: !_showCategories
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories List
          Column(
            children: list.map((cat) => _buildCategoryRow(cat)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(StorageCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          // Color Circle
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: cat.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Category Name
          Expanded(
            child: Text(
              cat.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),

          // Size in GB
          Text(
            '${cat.sizeGB.toStringAsFixed(1)} GB',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 10),

          // Percentage
          SizedBox(
            width: 40,
            child: Text(
              '${cat.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

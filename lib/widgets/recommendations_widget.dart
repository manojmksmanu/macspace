import 'package:flutter/material.dart';
import '../models/storage_item.dart';
import '../theme/app_theme.dart';

class RecommendationsWidget extends StatelessWidget {
  final List<StorageRecommendation> recommendations;

  const RecommendationsWidget({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgTranslucent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.amberGold, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Storage Optimization Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: recommendations.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: rec.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(rec.icon, color: rec.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          Text(
                            rec.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${rec.title} cleaned! Saved ${rec.potentialSavingsGB} GB'),
                            backgroundColor: AppTheme.emeraldGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rec.color.withValues(alpha: 0.2),
                        foregroundColor: rec.color,
                        elevation: 0,
                        side: BorderSide(color: rec.color.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        rec.actionText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


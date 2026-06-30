import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SensorCard extends StatelessWidget {
  final int distanceCm;
  final VoidCallback onMeasure;

  const SensorCard({
    super.key,
    required this.distanceCm,
    required this.onMeasure,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bölüm başlığı
            const Text(
              'MESAFE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Büyük mesafe değeri
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$distanceCm',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'cm',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                // Tek seferlik ölçüm butonu
                OutlinedButton.icon(
                  onPressed: onMeasure,
                  icon: const Icon(Icons.straighten, size: 16),
                  label: const Text('Ölç'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

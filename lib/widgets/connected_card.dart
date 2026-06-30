import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ConnectedCard extends StatelessWidget {
  final String deviceName;
  final VoidCallback onDisconnect;

  const ConnectedCard({
    super.key,
    required this.deviceName,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bağlı cihaz adı
                Text(
                  deviceName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Bağlantı durumu
                const Text(
                  'Bağlı',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // Bağlantıyı kes butonu
            OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.bluetooth_disabled, size: 16),
              label: const Text('Kes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

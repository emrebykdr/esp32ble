import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../ble_device_model.dart';

class DeviceList extends StatelessWidget {
  final List<BleDeviceModel> devices;
  final Function(BleDeviceModel) onDeviceTap;

  const DeviceList({
    super.key,
    required this.devices,
    required this.onDeviceTap,
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
              'BULUNAN CİHAZLAR',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Cihaz listesi — her cihaz bir satır
            ...devices.map((device) => _DeviceTile(
                  device: device,
                  onTap: () => onDeviceTap(device),
                )),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BleDeviceModel device;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Sinyal gücüne göre nokta rengi
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: device.rssi > -60 ? AppColors.accent : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            // Cihaz adı
            Expanded(
              child: Text(
                device.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // RSSI değeri
            Text(
              '${device.rssi} dBm',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

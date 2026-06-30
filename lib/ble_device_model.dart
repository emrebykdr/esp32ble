import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleDeviceModel {
  final String id; //mac adersi
  final String name; //Ekranda gösterilecek isim
  final int rssi; //sinyal gücü
  final BluetoothDevice device; //Bağlantı kurmak için gereken nesne

  BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });
}

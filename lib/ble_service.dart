import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_device_model.dart';

class BleService {
  // Bulunan cihazlar listesi
  final List<BleDeviceModel> _foundDevices = [];

  // Bağlı cihaz
  BluetoothDevice? _connectedDevice;

  // LED/Röle için write karakteristiği
  BluetoothCharacteristic? _writeCharacteristic;

  // Sensör için notify karakteristiği
  BluetoothCharacteristic? _notifyCharacteristic;

  // Stream'ler — UI bunları dinleyecek
  final _devicesController = StreamController<List<BleDeviceModel>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _sensorController = StreamController<int>.broadcast();

  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get sensorStream => _sensorController.stream;

  bool get isConnected => _connectedDevice != null;

  // 10 saniye boyunca çevredeki BLE cihazlarını tarar
  Future<void> startScan() async {
    // Bluetooth açık değilse aç
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    // Yeni taramadan önce eski listeyi temizle
    _foundDevices.clear();

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        final name = result.device.platformName;
        // İsmi olmayan cihazları (bilinmeyenleri) listeye ekleme
        if (name.isEmpty) continue;

        // Aynı cihazı tekrar eklememek için ID kontrolü yap
        final exists = _foundDevices.any(
          (d) => d.id == result.device.remoteId.str,
        );
        if (!exists) {
          _foundDevices.add(
            BleDeviceModel(
              id: result.device.remoteId.str,
              name: name,
              rssi: result.rssi,
              device: result.device,
            ),
          );
          // Her yeni cihaz bulunca stream'e güncel listeyi gönder — UI otomatik güncellenir
          _devicesController.add(List.from(_foundDevices));
        }
      }
    });
  }

  // Butona tekrar basılınca taramayı durdurur
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // Seçilen cihaza bağlanır ve bağlantı durumunu stream'e gönderir
  Future<void> connect(BleDeviceModel model) async {
    await model.device.connect();
    _connectedDevice = model.device;

    // Bağlantı kopunca otomatik temizlik yap
    model.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _writeCharacteristic = null;
        _notifyCharacteristic = null;
        _connectionController.add(false);
      }
    });

    // Bağlantı başarılı — servisleri keşfet
    await _discoverServices(model.device);
    _connectionController.add(true);
  }

  // Bağlantıyı keser
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _connectionController.add(false);
  }

  // Bağlandıktan sonra LED ve sensör karakteristiklerini bulur
  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        // Yazma özelliği varsa LED/Röle kontrolü için sakla
        if (c.properties.write) {
          _writeCharacteristic = c;
        }
        // Bildirim özelliği varsa sensör verisi için sakla
        if (c.properties.notify) {
          _notifyCharacteristic = c;
          await c.setNotifyValue(true);
          // Gelen sensör verisini stream'e gönder
          c.onValueReceived.listen((value) {
            if (value.isNotEmpty) {
              final cm = (value[0] << 8) | value[1];
              _sensorController.add(cm);
            }
          });
        }
      }
    }
  }

  // LED ve Röle için byte komut tablosu
  // ESP32 tarafındaki kod bu byte'lara göre çalışacak
  static const int redLedOn = 0x11;
  static const int redLedOff = 0x10;
  static const int greenLedOn = 0x21;
  static const int greenLedOff = 0x20;
  static const int blueLedOn = 0x31;
  static const int blueLedOff = 0x30;
  static const int relayOn = 0x41;
  static const int relayOff = 0x40;

  // Verilen byte komutunu ESP32'ye gönderir
  Future<void> sendCommand(int command) async {
    if (_writeCharacteristic == null) return;
    await _writeCharacteristic!.write([command]);
  }

  // Sensör için tek seferlik okuma isteği gönderir
  Future<void> requestSensor() async {
    if (_writeCharacteristic == null) return;
    // 0xFF → ESP32'ye "mesafeyi ölç ve gönder" komutu
    await _writeCharacteristic!.write([0xFF]);
  }

  // Stream controller'ları kapat — widget dispose olduğunda çağrılır
  void dispose() {
    _devicesController.close();
    _connectionController.close();
    _sensorController.close();
  }
}

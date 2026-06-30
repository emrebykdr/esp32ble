# ESP32 BLE Flutter Uygulaması — Adım Adım Implementation Planı

## Hedef UI (Referans: image.png)
Dark temalı, tek sayfa uygulama:
- Header: "ESP32 / BLE Controller" + bağlantı durumu göstergesi
- Cihaz tarama butonu
- Bulunan cihazlar listesi (isim + RSSI)
- Bağlı cihaz kartı + bağlantı kes butonu
- LED & Röle kontrol bölümü (toggle'lar)
- Mesafe sensörü bölümü (cm cinsinden değer + Ölç butonu)

---

## Mevcut Durum
- `pubspec.yaml` → `flutter_blue_plus: ^1.32.0` ve `permission_handler: ^11.3.0` zaten eklenmiş
- `AndroidManifest.xml` → BLE izinleri zaten tanımlanmış
- `lib/main.dart` → Varsayılan Flutter sayaç uygulaması (tamamen değiştirilecek)

---

## ADIM 1 — Proje Klasör Yapısını Oluştur

```
lib/
├── main.dart                  ← Sadece MaterialApp ve tema
├── theme/
│   └── app_theme.dart         ← Dark tema renkleri ve stiller
├── models/
│   └── ble_device_model.dart  ← BLE cihaz veri modeli
├── services/
│   └── ble_service.dart       ← BLE iş mantığı (scan, connect, write, notify)
├── screens/
│   └── home_screen.dart       ← Ana ekran (tüm bölümler buraya)
└── widgets/
    ├── scan_button.dart        ← "Cihazları Tara" butonu
    ├── device_list.dart        ← Bulunan cihazlar listesi
    ├── connected_card.dart     ← Bağlı cihaz kartı
    ├── led_relay_card.dart     ← LED & Röle toggle'ları
    └── sensor_card.dart        ← Mesafe sensörü kartı
```

**Yapılacaklar:**
- `lib/theme/`, `lib/models/`, `lib/services/`, `lib/screens/`, `lib/widgets/` klasörlerini oluştur (içine dosya koyunca otomatik oluşur)

---

## ADIM 2 — Tema Dosyası (`lib/theme/app_theme.dart`)

Dark tema renk paleti (screenshot'tan alınan değerler):

| Değişken | Renk | Kullanım |
|---|---|---|
| `bgColor` | `#0D1117` | Sayfa arka planı |
| `cardColor` | `#161B22` | Kart arka planı |
| `accentGreen` | `#00E5A0` | Bağlı gösterge, vurgu |
| `textPrimary` | `#E6EDF3` | Ana metin |
| `textSecondary` | `#8B949E` | RSSI, etiketler |
| `toggleActive` | `#30363D` | Toggle açık rengi |

**İçerik:**
```dart
// ThemeData ile MaterialApp'e verilecek dark tema
// TextTheme, InputDecorationTheme, CardTheme tanımlanacak
```

---

## ADIM 3 — Veri Modeli (`lib/models/ble_device_model.dart`)

```dart
class BleDeviceModel {
  final String id;         // cihaz MAC adresi
  final String name;       // cihaz adı
  final int rssi;          // sinyal gücü (dBm)
  
  // Kopyalama ve karşılaştırma metodları
}
```

---

## ADIM 4 — BLE Servis Katmanı (`lib/services/ble_service.dart`)

Bu dosya uygulamanın en kritik parçası. `FlutterBluePlus` paketini saran bir sınıf.

### 4.1 Cihaz Tarama
```dart
// FlutterBluePlus.startScan(timeout: Duration(seconds: 10))
// scanResults stream'ini dinle → BleDeviceModel listesi üret
// Tarama durumunu (isScanning) stream ile yönet
```

### 4.2 Bağlantı
```dart
// device.connect()
// Bağlantı durumunu (connectionState) stream ile dinle
// Bağlantı kopunca otomatik temizlik
```

### 4.3 Servis & Karakteristik Keşfi
```dart
// device.discoverServices()
// LED/Röle için WRITE karakteristiği bul
// Sensör için NOTIFY karakteristiği bul
```

**ESP32 BLE UUID Şeması (önemli — ESP32 koduna göre değişecek):**
```
Service UUID      : "12345678-1234-1234-1234-123456789012"  (örnek)
Karakteristik UUID:
  - LED kontrol   : WRITE özellikli
  - Sensör verisi : NOTIFY özellikli
```
> **Not:** Gerçek UUID'leri ESP32 Arduino kodundan alacaksın.

### 4.4 LED / Röle Komut Gönderme
```dart
// characteristic.write(Uint8List.fromList([komutByte]))
// Örnek protokol:
//   0x01 → Kırmızı LED aç
//   0x00 → Kırmızı LED kapat
//   0x03 → Yeşil LED aç ...
```

### 4.5 Sensör Verisi Okuma
```dart
// characteristic.setNotifyValue(true)
// characteristic.onValueReceived.listen(...)
// Gelen byte'ları cm'e dönüştür
```

---

## ADIM 5 — Widget'lar

### 5.1 `scan_button.dart`
- Tek büyük buton
- Taranıyorsa: dönen ikon + "Taranıyor..." yazısı
- Değilse: tarama ikonu + "Cihazları Tara"

### 5.2 `device_list.dart`
- `BleDeviceModel` listesini alır
- Her cihaz için bir `ListTile`:
  - Sol: yeşil/gri nokta (bağlı/değil)
  - Orta: cihaz adı
  - Sağ: RSSI değeri (dBm)
- Tıklanınca bağlanmayı tetikler

### 5.3 `connected_card.dart`
- Bağlı cihaz adını gösterir
- "Bağlı" yeşil yazısı
- "Kes" butonu (bluetooth ikon + yazı)
- Bağlı cihaz yoksa görünmez (`Visibility` veya koşullu render)

### 5.4 `led_relay_card.dart`
- Başlık: "LED & RÖLE"
- 4 satır: Kırmızı LED, Yeşil LED, Mavi LED, Röle
- Her satır: küçük renkli nokta + isim + `Switch` (sağda)
- Switch değişince BLE komutu gönderir

### 5.5 `sensor_card.dart`
- Başlık: "MESAFE"
- Büyük sayı (örn: "392") + "cm" küçük yazısı
- "Ölç" butonu — tıklanınca BLE'den tek seferlik okuma ister
- (Notify açıksa otomatik güncellenir, buton alternatif yol)

---

## ADIM 6 — Ana Ekran (`lib/screens/home_screen.dart`)

```dart
class HomeScreen extends StatefulWidget { ... }
class _HomeScreenState extends State<HomeScreen> {
  // BleService instance
  // İzin kontrolü (initState'de)
  // Widget'ları dikey listede sırala:
  //   1. ScanButton
  //   2. DeviceList (BULUNAN CİHAZLAR başlıklı kart içinde)
  //   3. ConnectedCard (bağlıysa görünür)
  //   4. LedRelayCard (bağlıysa görünür)
  //   5. SensorCard (bağlıysa görünür)
}
```

State yönetimi: `StreamBuilder` + `setState` kombinasyonu (paket gerekmez, basit tutacağız)

---

## ADIM 7 — `main.dart` Güncelleme

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,   // Adım 2'deki tema
      home: const HomeScreen(),
    );
  }
}
```

---

## ADIM 8 — İzin Yönetimi

`permission_handler` paketi zaten eklenmiş. `HomeScreen.initState`'de:

```dart
Future<void> _checkPermissions() async {
  // Android 12+ için BLUETOOTH_SCAN + BLUETOOTH_CONNECT
  // Android 12- için ACCESS_FINE_LOCATION
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.locationWhenInUse.request();
}
```

---

## ADIM 9 — Test & Debug

Gerçek ESP32 cihazı yokken test için:
- `flutter_blue_plus` mock modda çalışmaz ama Android emülatörde BLE desteği sınırlıdır
- Fiziksel Android telefon + ESP32 en sağlıklı test ortamı
- Debug için `FlutterBluePlus.setLogLevel(LogLevel.verbose)` ekle

---

## Uygulama Adımları Sırası

```
1. [ ] lib/ klasör yapısını oluştur
2. [ ] app_theme.dart yaz → main.dart'a bağla
3. [ ] ble_device_model.dart yaz
4. [ ] ble_service.dart yaz (scan + connect + write + notify)
5. [ ] scan_button.dart yaz
6. [ ] device_list.dart yaz
7. [ ] connected_card.dart yaz
8. [ ] led_relay_card.dart yaz
9. [ ] sensor_card.dart yaz
10. [ ] home_screen.dart yaz (tüm widget'ları bir araya getir)
11. [ ] main.dart güncelle
12. [ ] Fiziksel cihazda test et
13. [ ] ESP32 UUID'lerine göre ble_service.dart ince ayar yap
```

---

## Önemli Notlar

- **UUID'ler:** ESP32 Arduino/IDF kodundaki `BLEServer.createService(UUID)` ve `BLECharacteristic` UUID'lerini birebir kullanmak zorundasın.
- **Komut Protokolü:** LED komutları için byte protokolü ESP32 tarafıyla anlaşılmalı. Önce ESP32 kodunu yaz, sonra Flutter tarafını o protokole göre ayarla.
- **Android minSdk:** `flutter_blue_plus` için `minSdkVersion 21` gerekir. `android/app/build.gradle.kts` dosyasını kontrol et.
- **Bağlantı Kopması:** `connectionState` stream'i dinleyerek bağlantı kopunca UI'yı otomatik güncelle.
- **Dispose:** `HomeScreen` dispose olduğunda `ble_service.disconnect()` çağır, stream subscription'ları iptal et.

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class BleScanner {
  static bool _isScanning = false;
  static Timer? _scanTimer;
  static const Duration _scanPeriod = Duration(seconds: 10);
  
  // ESP32C3 BLE service UUIDs
  static final List<Guid> _esp32ServiceUUIDs = [
    Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b'), // ESP32C3 BLE service
  ];

  static Future<void> startScan({
    required Function(List<ScanResult>) onResults,
    required Function(bool) onScanStatus,
    required Function(String) onError,
  }) async {
    try {
      if (!_isScanning) {
        // Stop any ongoing scan first
        if (await FlutterBluePlus.isScanning.first) {
          await FlutterBluePlus.stopScan();
        }

        // Start scanning
        await FlutterBluePlus.startScan(
          timeout: _scanPeriod,
          androidUsesFineLocation: true,
        );
        
        _isScanning = true;
        onScanStatus(true);

        // Listen to scan results and filter for ESP32C3 devices
        FlutterBluePlus.scanResults.listen((results) {
          // Filter results for ESP32C3 devices
          final esp32Devices = results.where((result) {
            final device = result.device;
            final name = device.platformName.toLowerCase();
            final services = result.advertisementData.serviceUuids;
            
            // Check if device name contains ESP32 or matches known ESP32 service UUIDs
            return name.contains('esp32') || 
                   services.any((uuid) => _esp32ServiceUUIDs.contains(uuid));
          }).toList();

          if (esp32Devices.isNotEmpty) {
            print("Found ${esp32Devices.length} ESP32 devices");
            onResults(esp32Devices);
          }
        });

        // When scan completes
        FlutterBluePlus.isScanning.listen((scanning) {
          print("Scanning status changed: $scanning");
          if (!scanning) {
            _isScanning = false;
            onScanStatus(false);
          }
        });
      } else {
        // If already scanning, stop it
        await stopScan();
      }
    } catch (e) {
      print("Error scanning: $e");
      onError(e.toString());
    }
  }

  static Future<void> stopScan() async {
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    }
  }
}
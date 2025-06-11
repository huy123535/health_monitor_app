import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class BleController extends GetxController {
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  StreamSubscription? _connectionSubscription;
  
  // GUID của thiết bị cần kết nối
  final String targetServiceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

  @override
  void onInit() {
    super.onInit();
    // Tự động kết nối khi controller được khởi tạo
    autoConnectToDevice();
  }

  // Phương thức tự động kết nối đơn giản
  Future<void> autoConnectToDevice() async {
    try {
      // Thử đọc remoteId từ file
      final String remoteId = await File('/remoteId.txt').readAsString();
      var device = BluetoothDevice.fromId(remoteId);
      
      // AutoConnect thuận tiện vì không "time out" ngay cả khi thiết bị không có sẵn
      await device.connect(autoConnect: true);
      
      // Cập nhật trạng thái kết nối
      isConnected.value = true;
      connectedDevice.value = device;
      print("Tự động kết nối thành công đến thiết bị: ${device.platformName}");
      
    } catch (e) {
      print("Không thể tự động kết nối từ file: $e");
      // Nếu file không tồn tại hoặc lỗi, quét thiết bị mới
      await scanDevices();
    }
  }

  // Quét và kết nối đến thiết bị có GUID cụ thể
  Future<void> scanAndConnectToTargetDevice() async {
    isScanning.value = true;
    
    // Bắt đầu quét với service UUID cụ thể
    FlutterBluePlus.startScan(
      withServices: [Guid(targetServiceUUID)],
      timeout: Duration(seconds: 15)
    );

    // Lắng nghe kết quả quét
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        // Kiểm tra xem thiết bị có service UUID mong muốn không
        if (result.advertisementData.serviceUuids.contains(Guid(targetServiceUUID))) {
          print("Tìm thấy thiết bị với GUID mong muốn: ${result.device.platformName}");
          
          // Dừng quét và kết nối
          FlutterBluePlus.stopScan();
          isScanning.value = false;
          
          // Lưu remoteId vào file để sử dụng lần sau
          try {
            await File('/remote_id.txt').writeAsString(result.device.remoteId.toString());
          } catch (e) {
            print("Không thể lưu remote ID: $e");
          }
          
          // Kết nối đến thiết bị
          await connectToDevice(result.device);
          break;
        }
      }
    });

    // Dừng quét sau timeout
    FlutterBluePlus.isScanning.listen((scanning) {
      isScanning.value = scanning;
      if (!scanning) {
        print("Quét thiết bị đã dừng");
      }
    });
  }

  // Use FlutterBluePlus directly in your methods
  Future scanDevices() async {
    if(await Permission.bluetoothScan.request().isGranted){
      if(await Permission.bluetoothConnect.request().isGranted){
        isScanning.value = true;
        // Start scanning with timeout
        FlutterBluePlus.startScan(
          withServices: [Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b")],
          timeout: Duration(seconds: 10));
        // Listen to scanning state
        FlutterBluePlus.isScanning.listen((scanning) {
          isScanning.value = scanning;
        });
      }
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Cancel any existing connection subscription
      await _connectionSubscription?.cancel();
      
      // Connect to device
      await device.connect(timeout: Duration(seconds: 10));
      
      // Lưu remoteId vào file để tự động kết nối lần sau
      try {
        await File('/remoteId.txt').writeAsString(device.remoteId.toString());
        print("Đã lưu remoteId: ${device.remoteId}");
      } catch (e) {
        print("Không thể lưu remoteId: $e");
      }
      
      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) {
        print("Connection state changed: $state");
        if (state == BluetoothConnectionState.connected) {
          isConnected.value = true;
          connectedDevice.value = device;
          print("Device Connected: ${device.platformName}");
          
          // Navigate back to home page after successful connection
          Get.back(result: device);
        } else if (state == BluetoothConnectionState.disconnected) {
          isConnected.value = false;
          connectedDevice.value = null;
          print("Device Disconnected: ${device.platformName}");
        } else if (state == BluetoothConnectionState.connecting) {
          print("Connecting to device: ${device.platformName}");
        }
      });
    } catch (e) {
      print("Error connecting to device: $e");
      isConnected.value = false;
      connectedDevice.value = null;
    }
  }

  @override
  void onClose() {
    _connectionSubscription?.cancel();
    super.onClose();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;  
}

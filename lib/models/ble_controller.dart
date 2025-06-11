import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:connect_ble/models/sensor_data.dart';
import 'package:connect_ble/services/database_services.dart';

class BleController extends GetxController {
  final RxBool isScanning = false.obs;
  final RxBool isConnected = false.obs;
  final Rx<BluetoothDevice?> connectedDevice = Rx<BluetoothDevice?>(null);
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;
  
  // Service và Characteristic UUID
  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // Observable data từ sensor
  final RxDouble heartRate = 0.0.obs;
  final RxDouble spo2 = 0.0.obs;
  final RxDouble temperature = 0.0.obs;
  final RxDouble batteryPercentage = 0.0.obs;
  final RxBool isTemperatureEnabled = true.obs;
  final RxBool isHeartRateEnabled = true.obs;
  final RxBool isSpo2Enabled = true.obs;
  final RxString lastJsonReceived = "".obs;
  final RxString connectionStatus = "Disconnected".obs;
  
  // Data validity flags
  final RxBool hasValidHeartRate = false.obs;
  final RxBool hasValidSpo2 = false.obs;
  final RxBool hasValidTemperature = false.obs;
  final RxBool hasValidBattery = false.obs;


  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    super.onClose();
  }

  Future<void> _enableNotifications(BluetoothCharacteristic characteristic) async {
    try {
      // Enable notifications
      await characteristic.setNotifyValue(true);
      
      // Listen to characteristic changes
      _characteristicSubscription = characteristic.lastValueStream.listen(
        (value) {
          _handleReceivedData(value);
        },
        onError: (error) {
          print("Error listening to characteristic: $error");
        }
      );
      
      print("Notifications enabled successfully");
      connectionStatus.value = "Receiving data...";
    } catch (e) {
      print("Error enabling notifications: $e");
      connectionStatus.value = "Failed to enable notifications";
    }
  }

  void _handleReceivedData(List<int> data) {
    try {
      // Convert bytes to string
      String jsonString = String.fromCharCodes(data);
      print("Received raw data: $jsonString");
      
      // Check if this is a JSON message (should start with '{')
      if (!jsonString.trim().startsWith('{')) {
        print("Ignoring non-JSON message: $jsonString");
        return;
      }
      
      // Update last received JSON
      lastJsonReceived.value = jsonString;
      
      // Parse JSON
      Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Check if this is a status update response
      if (jsonData.containsKey('status')) {
        String status = jsonData['status'];
        if (status == 'sensors_updated' || status == 'mode_changed') {
          print("Received status update: $status");
          // Handle enabledSensors status if present
          if (jsonData.containsKey('enabledSensors')) {
            Map<String, dynamic> enabledSensors = jsonData['enabledSensors'];
            // Update local flags to match ESP32 status
            isTemperatureEnabled.value = enabledSensors['temperature'] == true;
            isHeartRateEnabled.value = enabledSensors['heartRate'] == true;
            isSpo2Enabled.value = enabledSensors['spo2'] == true;
            print("Updated sensor flags from ESP32: Temp=${isTemperatureEnabled.value}, HR=${isHeartRateEnabled.value}, SpO2=${isSpo2Enabled.value}");
          }
          return; // Don't process as sensor data
        }
      }

      // Create SensorData object from JSON
      final sensorData = SensorData.fromJson(jsonData);
      
      // Only update UI and store data if we have valid values
      if (sensorData.hasValidData()) {
        // Update UI values if they are valid
        if (sensorData.heartRate != null && isHeartRateEnabled.value) {
          heartRate.value = sensorData.heartRate!;
          hasValidHeartRate.value = true;
        }
        
        if (sensorData.spo2 != null && isSpo2Enabled.value) {
          spo2.value = sensorData.spo2!;
          hasValidSpo2.value = true;
        }
        
        if (sensorData.temperature != null && isTemperatureEnabled.value) {
          temperature.value = sensorData.temperature!;
          hasValidTemperature.value = true;
        }
        
        if (sensorData.batteryPercentage != null) {
          batteryPercentage.value = sensorData.batteryPercentage!;
          hasValidBattery.value = true;
        }

        // Store data in database
        DatabaseServices.instance.insertSensorData(sensorData);
        
        print("Data processing complete - HR: ${heartRate.value} (valid: ${hasValidHeartRate.value}), SpO2: ${spo2.value} (valid: ${hasValidSpo2.value}), Temp: ${temperature.value} (valid: ${hasValidTemperature.value})");
      }
      
      // Check for enabledSensors status in regular data messages
      if (jsonData.containsKey('enabledSensors')) {
        Map<String, dynamic> enabledSensors = jsonData['enabledSensors'];
        // Update local flags to match ESP32 status
        isTemperatureEnabled.value = enabledSensors['temperature'] == true;
        isHeartRateEnabled.value = enabledSensors['heartRate'] == true;
        isSpo2Enabled.value = enabledSensors['spo2'] == true;
      }
      
    } catch (e) {
      print("Error parsing received data: $e");
      print("Raw data was: ${String.fromCharCodes(data)}");
      // Don't update connectionStatus for parsing errors of non-JSON data
      if (String.fromCharCodes(data).trim().startsWith('{')) {
        connectionStatus.value = "Data parsing error";
      }
    }
  }

  // Method to update sensor modes
  void updateSensorModes(bool temp, bool hr, bool spo2) async {
    print("Updating sensor modes - Temperature: $temp, HeartRate: $hr, SpO2: $spo2");
    
    // Send individual commands for each sensor based on the new state
    // Temperature
    if (temp != isTemperatureEnabled.value) {
      await sendCommand(temp ? "TEMP_ON" : "TEMP_OFF");
      await Future.delayed(Duration(milliseconds: 100)); // Small delay
    }
    
    // Heart Rate  
    if (hr != isHeartRateEnabled.value) {
      await sendCommand(hr ? "HR_ON" : "HR_OFF");
      await Future.delayed(Duration(milliseconds: 100)); // Small delay
    }
    
    // SpO2
    if (spo2 != isSpo2Enabled.value) {
      await sendCommand(spo2 ? "SPO2_ON" : "SPO2_OFF");
      await Future.delayed(Duration(milliseconds: 100)); // Small delay
    }
    
    // Update local flags
    isTemperatureEnabled.value = temp;
    isHeartRateEnabled.value = hr;
    isSpo2Enabled.value = spo2;
  }

  // Method to send command to ESP32
  Future<void> sendCommand(String command) async {
    if (!isConnected.value || connectedDevice.value == null) {
      print("Device not connected");
      return;
    }

    try {
      List<BluetoothService> services = await connectedDevice.value!.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              // Write command
              List<int> bytes = utf8.encode(command);
              await characteristic.write(bytes);
              print("Command sent: $command");
              break;
            }
          }
          break;
        }
      }
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  void _resetSensorData() {
    heartRate.value = 0.0;
    spo2.value = 0.0;
    temperature.value = 0.0;
    batteryPercentage.value = 0.0;
    lastJsonReceived.value = "";
    hasValidHeartRate.value = false;
    hasValidSpo2.value = false;
    hasValidTemperature.value = false;
    hasValidBattery.value = false;
  }

  // Use FlutterBluePlus directly in your methods
  Future scanDevices() async {
    try {
      // Check if Bluetooth is turned on
      if (!await FlutterBluePlus.isSupported) {
        print("Bluetooth not supported");
        return;
      }

      // Request permissions
      if (!await Permission.bluetoothScan.isGranted) {
        final status = await Permission.bluetoothScan.request();
        if (!status.isGranted) {
          print("Bluetooth scan permission denied");
          return;
        }
      }

      if (!await Permission.bluetoothConnect.isGranted) {
        final status = await Permission.bluetoothConnect.request();
        if (!status.isGranted) {
          print("Bluetooth connect permission denied");
          return;
        }
      }

      if (!await Permission.location.isGranted) {
        final status = await Permission.location.request();
        if (!status.isGranted) {
          print("Location permission denied");
          return;
        }
      }

      // Make sure any previous scan is stopped
      if (isScanning.value) {
        await FlutterBluePlus.stopScan();
        await Future.delayed(Duration(milliseconds: 100));
      }

      isScanning.value = true;
      
      // Start scanning with timeout
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUUID)],
        timeout: Duration(seconds: 10),
      );

      // Listen to scanning state
      FlutterBluePlus.isScanning.listen((scanning) {
        isScanning.value = scanning;
      }, onError: (error) {
        print("Scanning error: $error");
        isScanning.value = false;
      });
    } catch (e) {
      print("Error during scan: $e");
      isScanning.value = false;
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
      await _characteristicSubscription?.cancel();

      connectionStatus.value = "Connecting...";
      
      // Connect to device
      await device.connect(timeout: Duration(seconds: 10));
    
      // Listen to connection state
      _connectionSubscription = device.connectionState.listen((state) {
        print("Connection state changed: $state");
        if (state == BluetoothConnectionState.connected) {
          isConnected.value = true;
          connectedDevice.value = device;
          print("Device Connected: ${device.platformName}");

          // Discover services sau khi kết nối thành công
          _discoverServices(device);
          
          // Navigate back to home page after successful connection
          Get.back(result: device);
        } else if (state == BluetoothConnectionState.disconnected) {
          isConnected.value = false;
          connectedDevice.value = null;
          connectionStatus.value = "Disconnected";
          _resetSensorData();
          print("Device Disconnected: ${device.platformName}");
        } else if (state == BluetoothConnectionState.connecting) {
          print("Connecting to device: ${device.platformName}");
        }
      });
    } catch (e) {
      print("Error connecting to device: $e");
      isConnected.value = false;
      connectedDevice.value = null;
      connectionStatus.value = "Connection failed";
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      connectionStatus.value = "Discovering services...";
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Tìm service cần thiết
      for (BluetoothService service in services) {
        print("Found service: ${service.uuid}");
        
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          print("Found target service!");
          
          // Tìm characteristic cần thiết
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            print("Found characteristic: ${characteristic.uuid}");
            
            if (characteristic.uuid.toString().toLowerCase() == characteristicUUID.toLowerCase()) {
              print("Found target characteristic!");
              
              // Enable notifications
              await _enableNotifications(characteristic);
              break;
            }
          }
          break;
        }
      }
      
      connectionStatus.value = "Ready to receive data";
      
      // Request current sensor status from ESP32
      await Future.delayed(Duration(milliseconds: 500)); // Small delay to ensure connection is stable
      await requestSensorStatus();
      
    } catch (e) {
      print("Error discovering services: $e");
      connectionStatus.value = "Service discovery failed";
    }
  }

  // Method to manually request data (nếu ESP32 hỗ trợ read)
  Future<void> requestSensorData() async {
    if (!isConnected.value || connectedDevice.value == null) {
      print("Device not connected");
      return;
    }

    try {
      // Send REQUEST_DATA command to ESP32
      await sendCommand("REQUEST_DATA");
      print("Requested sensor data from ESP32");
    } catch (e) {
      print("Error requesting sensor data: $e");
    }
  }

  Future<void> disconnect() async {
    try {
      if (connectedDevice.value != null) {
        await connectedDevice.value!.disconnect();
      }
    } catch (e) {
      print("Error disconnecting: $e");
    }
  }

  // Method to request current sensor status from ESP32
  Future<void> requestSensorStatus() async {
    if (!isConnected.value || connectedDevice.value == null) {
      print("Device not connected");
      return;
    }

    try {
      await sendCommand("GET_SENSOR_STATUS");
      print("Requested sensor status from ESP32");
    } catch (e) {
      print("Error requesting sensor status: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;  
}
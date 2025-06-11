import 'package:connect_ble/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connect_ble/pages/scan_page.dart';
import 'package:connect_ble/models/ble_controller.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BleController bleController;
  
  // Vital signs data
  double heartRate = 75.0;
  double spo2 = 98.0;
  double temperature = 36.8;

  // Measurement modes
  bool isTemperatureEnabled = true;
  bool isHeartRateEnabled = true;
  bool isSpo2Enabled = true;

  @override
  void initState() {
    super.initState();
    bleController = Get.put(BleController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            cardConnect(),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Measurement Control Panel
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Color(0xFF2E86AB), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Measurement Modes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          // Temperature Toggle
                          Obx(() => _buildMeasurementToggle(
                            'Body Temperature (Forehead)',
                            Icons.thermostat,
                            Colors.orange[400]!,
                            bleController.isTemperatureEnabled.value,
                            (value) {
                              bleController.updateSensorModes(
                                value,
                                bleController.isHeartRateEnabled.value,
                                bleController.isSpo2Enabled.value,
                              );
                            },
                          )),
                          
                          SizedBox(height: 12),
                          
                          // Heart Rate Toggle
                          Obx(() => _buildMeasurementToggle(
                            'Heart Rate (Finger)',
                            Icons.favorite,
                            Colors.red[400]!,
                            bleController.isHeartRateEnabled.value,
                            (value) {
                              bleController.updateSensorModes(
                                bleController.isTemperatureEnabled.value,
                                value,
                                bleController.isSpo2Enabled.value,
                              );
                            },
                          )),
                          
                          SizedBox(height: 12),
                          
                          // SpO2 Toggle
                          Obx(() => _buildMeasurementToggle(
                            'Blood Oxygen (Finger)',
                            Icons.water_drop,
                            Colors.blue[400]!,
                            bleController.isSpo2Enabled.value,
                            (value) {
                              bleController.updateSensorModes(
                                bleController.isTemperatureEnabled.value,
                                bleController.isHeartRateEnabled.value,
                                value,
                              );
                            },
                          )),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Vital Signs
                  Text(
                    'Vital Signs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E86AB),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Heart Rate
                  Obx(() {
                    if (bleController.isHeartRateEnabled.value) {
                      return Column(
                        children: [
                          _buildSensorCard(
                            'Heart Rate',
                            bleController.hasValidHeartRate.value 
                              ? '${bleController.heartRate.value.toInt()}' 
                              : 'NA',
                            'BPM',
                            Icons.favorite,
                            Colors.red[400]!,
                            bleController.hasValidHeartRate.value,
                          ),
                          SizedBox(height: 12),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }),

                  // SpO2
                  Obx(() {
                    if (bleController.isSpo2Enabled.value) {
                      return Column(
                        children: [
                          _buildSensorCard(
                            'Blood Oxygen',
                            bleController.hasValidSpo2.value 
                              ? '${bleController.spo2.value.toInt()}' 
                              : 'NA',
                            '%',
                            Icons.water_drop,
                            Colors.blue[400]!,
                            bleController.hasValidSpo2.value,
                          ),
                          SizedBox(height: 12),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }),

                  // Temperature
                  Obx(() {
                    if (bleController.isTemperatureEnabled.value) {
                      return Column(
                        children: [
                          _buildSensorCard(
                            'Body Temperature',
                            bleController.hasValidTemperature.value 
                              ? '${bleController.temperature.value.toStringAsFixed(1)}' 
                              : 'NA',
                            '°C',
                            Icons.thermostat,
                            Colors.orange[400]!,
                            bleController.hasValidTemperature.value,
                          ),
                          SizedBox(height: 12),
                        ],
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }),

                  SizedBox(height: 20),

                  // Control Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() => ElevatedButton.icon(
                          onPressed: bleController.isConnected.value 
                            ? () => bleController.requestSensorData()
                            : null,
                          icon: Icon(Icons.refresh),
                          label: Text('Request Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E86AB),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[600],
                          ),
                        )),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // // Test Database Button
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton.icon(
                  //     onPressed: () async {
                  //       try {
                  //         await DatabaseServices.instance.insertTestData();
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             content: Text('Test data inserted successfully!'),
                  //             backgroundColor: Colors.green,
                  //           ),
                  //         );
                  //       } catch (e) {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             content: Text('Error inserting test data: $e'),
                  //             backgroundColor: Colors.red,
                  //           ),
                  //         );
                  //       }
                  //     },
                  //     icon: Icon(Icons.storage),
                  //     label: Text('Insert Test Data to Database'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Color(0xFF4CAF50),
                  //       foregroundColor: Colors.white,
                  //       padding: EdgeInsets.symmetric(vertical: 12),
                  //     ),
                  //   ),
                  // ),

                  // SizedBox(height: 16),

                  // Connection Status
                  Obx(() => Card(
                    color: bleController.isConnected.value 
                      ? Colors.green[50] 
                      : Colors.orange[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            bleController.isConnected.value 
                              ? Icons.check_circle 
                              : Icons.info,
                            color: bleController.isConnected.value 
                              ? Colors.green 
                              : Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bleController.connectionStatus.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: bleController.isConnected.value 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

                  // Raw JSON Display (for debugging)
                  Obx(() => bleController.lastJsonReceived.value.isNotEmpty
                    ? Card(
                        margin: EdgeInsets.only(top: 16),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Icon(Icons.code, size: 16),
                              SizedBox(width: 8),
                              Text('Raw JSON Data'),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  bleController.lastJsonReceived.value,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink()
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Card cardConnect() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bluetooth, color: Color(0xFF2E86AB)),
                SizedBox(width: 8),
                Text(
                  'Device Connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                          bleController.connectedDevice.value?.platformName ?? 'No Device Connected',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: bleController.isConnected.value 
                              ? Colors.black 
                              : Colors.grey[600],
                          ),
                        )),
                        SizedBox(height: 4),
                        Obx(() => Text(
                          bleController.isConnected.value 
                            ? "Connected to ${bleController.connectedDevice.value?.platformName ?? 'Unknown Device'}"
                            : "Tap 'Connect' to scan for ESP32 devices",
                          style: TextStyle(
                            color: bleController.isConnected.value ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        )),
                        // Battery status
                        Obx(() => bleController.isConnected.value && bleController.hasValidBattery.value
                          ? Column(
                              children: [
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      _getBatteryIcon(bleController.batteryPercentage.value),
                                      size: 16,
                                      color: _getBatteryColor(bleController.batteryPercentage.value),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${bleController.batteryPercentage.value.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _getBatteryColor(bleController.batteryPercentage.value),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: bleController.batteryPercentage.value / 100,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getBatteryColor(bleController.batteryPercentage.value),
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : SizedBox.shrink()
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => ElevatedButton.icon(
                  onPressed: () async {
                    if (bleController.isConnected.value) {
                      bleController.disconnect();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanPage()),
                      );
                    }
                  },
                  icon: Icon(
                    bleController.isConnected.value 
                      ? Icons.bluetooth_disabled
                      : Icons.bluetooth,
                    size: 16,
                  ),
                  label: Text(bleController.isConnected.value ? 'Disconnect' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bleController.isConnected.value 
                      ? Colors.red[400]
                      : const Color(0xFF2E86AB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, String unit, IconData icon, Color color, bool isActive) {
    return Card(
      elevation: isActive ? 8 : 2,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive 
            ? LinearGradient(
                colors: [color.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          border: isActive 
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(isActive ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: isActive ? color : color.withOpacity(0.5), 
                size: 30,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      fontSize: 16, 
                      color: isActive ? Colors.grey[700] : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isActive && value != "NA" ? color : Colors.grey[400],
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        unit, 
                        style: TextStyle(
                          fontSize: 16, 
                          color: isActive ? Colors.grey[600] : Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isActive && value != "NA")
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementToggle(String label, IconData icon, Color color, bool isEnabled, Function(bool) onToggle) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(isEnabled ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon, 
            color: isEnabled ? color : color.withOpacity(0.5), 
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isEnabled ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: (value) => onToggle(value),
          activeColor: color,
          activeTrackColor: color.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ],
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text(
        "ESP32 Health Monitor",
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          margin: EdgeInsets.all(10.0),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/arrow-left-2-svgrepo-com.svg',
            width: 20.0,
            height: 20.0,
          ),
          decoration: BoxDecoration(
            color: Color(0xffF7F8F8),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage()));// Handle history icon tap here - có thể thêm trang lịch sử dữ liệu
          },
          child: Container(
            margin: EdgeInsets.all(10.0),
            alignment: Alignment.center,
            width: 37,
            child: SvgPicture.asset(
              'assets/icons/history-svgrepo-com.svg',
              width: 15.0,
              height: 15.0,
            ),
            decoration: BoxDecoration(
              color: Color(0xffF7F8F8),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBatteryColor(double percentage) {
    if (percentage < 15) {
      return Colors.red[700]!;
    } else if (percentage < 30) {
      return Colors.orange[700]!;
    } else if (percentage < 50) {
      return Colors.orange[500]!;
    } else if (percentage < 70) {
      return Colors.yellow[700]!;
    } else if (percentage < 90) {
      return Colors.lightGreen[600]!;
    } else {
      return Colors.green[600]!;
    }
  }

  IconData _getBatteryIcon(double percentage) {
    if (percentage < 20) {
      return Icons.battery_0_bar;
    } else if (percentage < 30) {
      return Icons.battery_1_bar;
    } else if (percentage < 50) {
      return Icons.battery_2_bar;
    } else if (percentage < 70) {
      return Icons.battery_3_bar;
    } else if (percentage < 90) {
      return Icons.battery_4_bar;
    } else {
      return Icons.battery_full;
    }
  }
}

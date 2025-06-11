import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connect_ble/services/ble_scanner.dart';
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
                          style: TextStyle(fontWeight: FontWeight.w500),
                        )),
                        SizedBox(height: 4),
                        Obx(() => Text(
                          bleController.isConnected.value 
                            ? "Connected to ${bleController.connectedDevice.value?.platformName ?? 'Unknown Device'}"
                            : "Waiting for ESP32 connection...",
                          style: TextStyle(
                            color: bleController.isConnected.value ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanPage()),
                    );
                  },
                  icon: const Icon(Icons.bluetooth, size: 16),
                  label: const Text('Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text(
        "ESP32 Monitor",
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
          // Handle back button tap here
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
            // Handle history icon tap here
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
}

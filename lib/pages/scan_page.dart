import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connect_ble/models/ble_controller.dart';
import 'package:get/get.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Devices'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: GetBuilder<BleController>(
        init: BleController(),
        builder: (controller) {
          return Column(
            children: [
              Obx(() => controller.isScanning.value
                ? LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E86AB)),
                  )
                : SizedBox.shrink()
              ),
              StreamBuilder<List<ScanResult>>(
                stream: controller.scanResults,
                builder: (context, snapshot) {
                  if(snapshot.hasData){
                    return Expanded(
                      child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data![index];
                          return Card(
                            child: ListTile(
                              title: Text(data.device.platformName.isEmpty ? 'Unknown Device' : data.device.platformName),
                              subtitle: Text(data.device.remoteId.str),
                              trailing: Text(data.rssi.toString()),
                              onTap: ()=> controller.connectToDevice(data.device),
                            ),
                          );
                        }
                      ),
                    );
                  } else {
                    return Expanded(
                      child: Center(child: Text("No devices found")),
                    );
                  }
                }
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isScanning.value 
                    ? () => controller.stopScan()
                    : () => controller.scanDevices(),
                  child: Text(controller.isScanning.value ? "Stop Scan" : "Scan Devices"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                )),
              ),
            ],
          );
        }
      ),
    );
  }
}
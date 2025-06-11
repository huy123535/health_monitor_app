import 'package:flutter/material.dart';
import 'package:connect_ble/pages/home_page.dart';
import 'package:connect_ble/pages/measurement_info_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom - 
                        kToolbarHeight - 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600, // Maximum width for cards
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuCard(
                      context,
                      title: 'Measurement Information',
                      description: 'Learn about heart rate, SpO2, and temperature measurements',
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MeasurementInfoPage()),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    _buildMenuCard(
                      context,
                      title: 'Start Measurement',
                      description: 'Connect to device and start measuring vital signs',
                      icon: Icons.medical_services_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E86AB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Color(0xFF2E86AB),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
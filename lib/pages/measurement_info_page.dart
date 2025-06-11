import 'package:flutter/material.dart';

class MeasurementInfoPage extends StatelessWidget {
  const MeasurementInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Measurement Information",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMeasurementSection(
                  title: 'Nhịp tim (Heart Rate)',
                  icon: Icons.favorite,
                  color: Colors.red[400]!,
                  items: [
                    'Người lớn nghỉ ngơi: 60-100 nhịp/phút',
                    'Vận động viên: có thể thấp hơn, khoảng 40-60 nhịp/phút',
                    'Trẻ em: cao hơn người lớn (trẻ sơ sinh: 100-160 nhịp/phút)',
                  ],
                ),
                SizedBox(height: 24),
                _buildMeasurementSection(
                  title: 'SpO2 (độ bão hòa oxy trong máu)',
                  icon: Icons.water_drop,
                  color: Colors.blue[400]!,
                  items: [
                    'Bình thường: 95-100%',
                    'Dưới 90% được coi là thấp và cần chú ý y tế',
                    'Người có bệnh phổi mãn tính có thể có SpO2 thấp hơn bình thường',
                  ],
                ),
                SizedBox(height: 24),
                _buildMeasurementSection(
                  title: 'Nhiệt độ ngoài da tại trán (Forehead Temperature)',
                  icon: Icons.thermostat,
                  color: Colors.orange[400]!,
                  items: [
                    'Khoảng từ 36.1°C đến 37.2°C',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
} 
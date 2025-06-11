import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../services/database_services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DatabaseServices _databaseServices = DatabaseServices.instance;
  final _formKey = GlobalKey<FormState>();
  final _heartRateController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _temperatureController = TextEditingController();
  
  String _selectedTimeRange = '24h'; // Default time range

  @override
  void dispose() {
    _heartRateController.dispose();
    _spo2Controller.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurement History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTrendCharts(),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5, // Set a fixed height for the list
              child: _buildMeasurementsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTestDataDialog,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF2E86AB),
      ),
    );
  }

  Widget _buildTrendCharts() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: FutureBuilder<List<SensorData>>(
            future: _getFilteredData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error loading trend data'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data available for selected period'));
              }

              return PageView(
                children: [
                  _buildTrendChart(
                    snapshot.data!,
                    'Heart Rate',
                    Colors.red[400]!,
                    (data) => data.heartRate,
                    'BPM',
                  ),
                  _buildTrendChart(
                    snapshot.data!,
                    'SpO2',
                    Colors.blue[400]!,
                    (data) => data.spo2,
                    '%',
                  ),
                  _buildTrendChart(
                    snapshot.data!,
                    'Temperature',
                    Colors.orange[400]!,
                    (data) => data.temperature,
                    '°C',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<SensorData>> _getFilteredData() async {
    final now = DateTime.now();
    final DateTime startDate;
    
    switch (_selectedTimeRange) {
      case '24h':
        startDate = now.subtract(Duration(hours: 24));
        break;
      case '10d':
        startDate = now.subtract(Duration(days: 10));
        break;
      case '30d':
        startDate = now.subtract(Duration(days: 30));
        break;
      case '365d':
        startDate = now.subtract(Duration(days: 365));
        break;
      default:
        startDate = now.subtract(Duration(hours: 24));
    }
    
    return await _databaseServices.getMeasurementsInRange(startDate, now);
  }

  Widget _buildTrendChart(
    List<SensorData> data,
    String title,
    Color color,
    double? Function(SensorData) getValue,
    String unit,
  ) {
    // Filter out null values and sort by timestamp
    final validData = data
        .where((d) => getValue(d) != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (validData.isEmpty) {
      return Center(child: Text('No $title data available'));
    }

    // Create spots for the line chart
    final spots = validData.map((d) {
      return FlSpot(
        d.timestamp.millisecondsSinceEpoch.toDouble(),
        getValue(d)!,
      );
    }).toList();

    // Set fixed Y-axis ranges based on measurement type
    double minY;
    double maxY;
    switch (title) {
      case 'Heart Rate':
        minY = 40;
        maxY = 180;
        break;
      case 'SpO2':
        minY = 80;
        maxY = 100;
        break;
      case 'Temperature':
        minY = 32;
        maxY = 42;
        break;
      default:
        // Fallback to dynamic range if title doesn't match
        final values = validData.map((d) => getValue(d)!).toList();
        minY = values.reduce((min, value) => value < min ? value : min);
        maxY = values.reduce((max, value) => value > max ? value : max);
        final padding = (maxY - minY) * 0.1;
        minY -= padding;
        maxY += padding;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedTimeRange,
                items: [
                  DropdownMenuItem(value: '24h', child: Text('Last 24h')),
                  DropdownMenuItem(value: '10d', child: Text('Last 10 days')),
                  DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
                  DropdownMenuItem(value: '365d', child: Text('Last 365 days')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeRange = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  // Add horizontal grid lines at important values
                  getDrawingHorizontalLine: (value) {
                    if (title == 'Heart Rate') {
                      // Add lines at 60 and 100 BPM
                      if (value == 60 || value == 100) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      }
                    } else if (title == 'SpO2') {
                      // Add line at 95% (normal threshold)
                      if (value == 95) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      }
                    } else if (title == 'Temperature') {
                      // Add lines at 37°C (normal body temperature)
                      if (value == 37) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      }
                    }
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(title == 'Temperature' ? 1 : 0),
                          style: TextStyle(fontSize: 10),
                        );
                      },
                      interval: title == 'Temperature' ? 2 : // Every 2°C
                               title == 'SpO2' ? 5 : // Every 5%
                               20, // Every 20 BPM
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _selectedTimeRange == '24h'
                                ? DateFormat('HH:mm').format(date)
                                : DateFormat('MM/dd').format(date),
                            style: TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minX: validData.first.timestamp.millisecondsSinceEpoch.toDouble(),
                maxX: validData.last.timestamp.millisecondsSinceEpoch.toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          touchedSpot.x.toInt(),
                        );
                        return LineTooltipItem(
                          '${DateFormat('MM/dd HH:mm').format(date)}\n${touchedSpot.y.toStringAsFixed(title == 'Temperature' ? 1 : 0)} $unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTestDataDialog() {
    // Reset controllers
    _heartRateController.clear();
    _spo2Controller.clear();
    _temperatureController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Test Data'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _heartRateController,
                    decoration: InputDecoration(
                      labelText: 'Heart Rate (BPM)',
                      prefixIcon: Icon(Icons.favorite, color: Colors.red[400]),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = int.tryParse(value);
                        if (number == null) return 'Please enter a valid number';
                        if (number < 0 || number > 250) return 'Enter a value between 0 and 250';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _spo2Controller,
                    decoration: InputDecoration(
                      labelText: 'SpO2 (%)',
                      prefixIcon: Icon(Icons.water_drop, color: Colors.blue[400]),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = int.tryParse(value);
                        if (number == null) return 'Please enter a valid number';
                        if (number < 0 || number > 100) return 'Enter a value between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _temperatureController,
                    decoration: InputDecoration(
                      labelText: 'Temperature (°C)',
                      prefixIcon: Icon(Icons.thermostat, color: Colors.orange[400]),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = double.tryParse(value);
                        if (number == null) return 'Please enter a valid number';
                        if (number < 30 || number > 45) return 'Enter a value between 30 and 45';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Create SensorData object
                  final testData = SensorData(
                    heartRate: _heartRateController.text.isNotEmpty 
                      ? double.parse(_heartRateController.text) 
                      : null,
                    spo2: _spo2Controller.text.isNotEmpty 
                      ? double.parse(_spo2Controller.text) 
                      : null,
                    temperature: _temperatureController.text.isNotEmpty 
                      ? double.parse(_temperatureController.text) 
                      : null,
                  );

                  // Save to database
                  if (testData.hasValidData()) {
                    await _databaseServices.insertSensorData(testData);
                    Navigator.of(context).pop();
                    setState(() {}); // Refresh the list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Test data added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter at least one measurement'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeasurementsList() {
    return FutureBuilder<List<SensorData>>(
      future: _databaseServices.getAllMeasurements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No measurements recorded yet'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final measurement = snapshot.data![index];
            return Dismissible(
              key: Key(measurement.timestamp.toIso8601String()),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Delete Record'),
                      content: Text('Are you sure you want to delete this measurement?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) async {
                try {
                  await _databaseServices.deleteMeasurement(measurement.timestamp);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Measurement deleted'),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting measurement: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM d, y').format(measurement.timestamp),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm:ss').format(measurement.timestamp),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (measurement.heartRate != null)
                            _buildMeasurementItem(
                              Icons.favorite,
                              Colors.red[400]!,
                              'Heart Rate',
                              '${measurement.heartRate!.round()} BPM',
                            ),
                          if (measurement.spo2 != null)
                            _buildMeasurementItem(
                              Icons.water_drop,
                              Colors.blue[400]!,
                              'SpO2',
                              '${measurement.spo2!.round()}%',
                            ),
                          if (measurement.temperature != null)
                            _buildMeasurementItem(
                              Icons.thermostat,
                              Colors.orange[400]!,
                              'Temperature',
                              '${measurement.temperature!.toStringAsFixed(1)}°C',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMeasurementItem(IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
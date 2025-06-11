class SensorData {
  final double? heartRate;
  final double? spo2;
  final double? temperature;
  final double? batteryPercentage; // Keep for display only
  final DateTime timestamp;

  SensorData({
    this.heartRate,
    this.spo2,
    this.temperature,
    this.batteryPercentage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Factory constructor to create SensorData from JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      heartRate: _parseDoubleValue(json['heartRate']),
      spo2: _parseDoubleValue(json['spo2']),
      temperature: _parseDoubleValue(json['temperature']),
      batteryPercentage: _parseDoubleValue(json['batteryPercentage']),
    );
  }

  // Helper method to parse values that might be int, double, or string
  static double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Convert to Map for database storage - exclude batteryPercentage
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'heart_rate': heartRate?.round(),
      'spo2': spo2?.round(),
      'temperature': temperature,
    };
  }

  // Check if data has any valid values (excluding battery)
  bool hasValidData() {
    return heartRate != null || spo2 != null || temperature != null;
  }

  @override
  String toString() {
    return 'SensorData(heartRate: $heartRate, spo2: $spo2, temperature: $temperature, batteryPercentage: $batteryPercentage, timestamp: $timestamp)';
  }
} 
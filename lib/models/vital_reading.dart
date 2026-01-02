// Data model for storing vital health readings
class VitalReading {
  final String id;
  final VitalType type;
  final double value;
  final double? secondaryValue; // For blood pressure (diastolic)
  final DateTime timestamp;
  final String? notes;
  final String? measurementType; // For blood glucose: 'fasting' or 'post-meal'
  final String? unit; // For temperature: 'celsius' or 'fahrenheit'

  VitalReading({
    required this.id,
    required this.type,
    required this.value,
    this.secondaryValue,
    required this.timestamp,
    this.notes,
    this.measurementType,
    this.unit,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'value': value,
      'secondaryValue': secondaryValue,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'measurementType': measurementType,
      'unit': unit,
    };
  }

  // Create from Map
  factory VitalReading.fromMap(Map<String, dynamic> map) {
    return VitalReading(
      id: map['id'],
      type: VitalType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      value: map['value'],
      secondaryValue: map['secondaryValue'],
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
      measurementType: map['measurementType'],
      unit: map['unit'],
    );
  }
}

// Types of vital measurements
enum VitalType {
  heartRate,
  restingHeartRate,
  bloodPressure,
  respiratoryRate,
  bloodOxygen,
  bloodGlucose,
  bodyTemperature,
  hrv,
}

// Extension to get display names and units
extension VitalTypeExtension on VitalType {
  String get displayName {
    switch (this) {
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.restingHeartRate:
        return 'Resting Heart Rate';
      case VitalType.bloodPressure:
        return 'Blood Pressure';
      case VitalType.respiratoryRate:
        return 'Respiratory Rate';
      case VitalType.bloodOxygen:
        return 'Blood Oxygen';
      case VitalType.bloodGlucose:
        return 'Blood Glucose';
      case VitalType.bodyTemperature:
        return 'Body Temperature';
      case VitalType.hrv:
        return 'Heart Rate Variability';
    }
  }

  String get unit {
    switch (this) {
      case VitalType.heartRate:
      case VitalType.restingHeartRate:
        return 'BPM';
      case VitalType.bloodPressure:
        return 'mmHg';
      case VitalType.respiratoryRate:
        return 'breaths/min';
      case VitalType.bloodOxygen:
        return '%';
      case VitalType.bloodGlucose:
        return 'mg/dL';
      case VitalType.bodyTemperature:
        return '°C';
      case VitalType.hrv:
        return 'ms';
    }
  }

  String get icon {
    switch (this) {
      case VitalType.heartRate:
      case VitalType.restingHeartRate:
        return '❤️';
      case VitalType.bloodPressure:
        return '🩺';
      case VitalType.respiratoryRate:
        return '🫁';
      case VitalType.bloodOxygen:
        return '💨';
      case VitalType.bloodGlucose:
        return '🩸';
      case VitalType.bodyTemperature:
        return '🌡️';
      case VitalType.hrv:
        return '📊';
    }
  }
}

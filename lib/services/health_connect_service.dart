import 'package:health/health.dart';
import '../models/vital_reading.dart';

class HealthConnectService {
  final Health _health = Health();
  bool _isAuthorized = false;

  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  ];

  Future<bool> requestPermissions() async {
    try {
      _isAuthorized = await _health.requestAuthorization(_types);
      return _isAuthorized;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<VitalReading?> getLatestHeartRate() async {
    final data = await _fetchLatestData(HealthDataType.HEART_RATE);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.heartRate,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
    );
  }

  Future<VitalReading?> getLatestRestingHeartRate() async {
    final data = await _fetchLatestData(HealthDataType.RESTING_HEART_RATE);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.restingHeartRate,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
    );
  }

  Future<VitalReading?> getLatestBloodPressure() async {
    final systolic = await _fetchLatestData(HealthDataType.BLOOD_PRESSURE_SYSTOLIC);
    final diastolic = await _fetchLatestData(HealthDataType.BLOOD_PRESSURE_DIASTOLIC);
    if (systolic == null || diastolic == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.bloodPressure,
      value: (systolic.value as NumericHealthValue).numericValue.toDouble(),
      secondaryValue: (diastolic.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: systolic.dateTo,
    );
  }

  Future<VitalReading?> getLatestBloodOxygen() async {
    final data = await _fetchLatestData(HealthDataType.BLOOD_OXYGEN);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.bloodOxygen,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
    );
  }

  Future<VitalReading?> getLatestBloodGlucose() async {
    final data = await _fetchLatestData(HealthDataType.BLOOD_GLUCOSE);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.bloodGlucose,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
    );
  }

  Future<VitalReading?> getLatestBodyTemperature() async {
    final data = await _fetchLatestData(HealthDataType.BODY_TEMPERATURE);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.bodyTemperature,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
      unit: 'celsius',
    );
  }

  Future<VitalReading?> getLatestRespiratoryRate() async {
    final data = await _fetchLatestData(HealthDataType.RESPIRATORY_RATE);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.respiratoryRate,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
    );
  }

  Future<VitalReading?> getLatestHRV() async {
    final data = await _fetchLatestData(HealthDataType.HEART_RATE_VARIABILITY_SDNN);
    if (data == null) return null;
    return VitalReading(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: VitalType.hrv,
      value: (data.value as NumericHealthValue).numericValue.toDouble(),
      timestamp: data.dateTo,
    );
  }

  Future<List<VitalReading>> getHRVHistory({int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: startDate,
        endTime: now,
      );
      
      return data.map((point) => VitalReading(
        id: point.dateFrom.millisecondsSinceEpoch.toString(),
        type: VitalType.hrv,
        value: (point.value as NumericHealthValue).numericValue.toDouble(),
        timestamp: point.dateTo,
      )).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error fetching HRV history: $e');
      return [];
    }
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: midnight,
        endTime: now,
      );
      
      int totalSteps = 0;
      for (var point in data) {
        totalSteps += (point.value as NumericHealthValue).numericValue.toInt();
      }
      return totalSteps;
    } catch (e) {
      print('Error fetching steps: $e');
      return 0;
    }
  }

  Future<HealthDataPoint?> _fetchLatestData(HealthDataType type) async {
    if (!_isAuthorized) {
      await requestPermissions();
    }
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 7));
    
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: yesterday,
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      return data.first;
    } catch (e) {
      print('Error fetching $type: $e');
      return null;
    }
  }
}

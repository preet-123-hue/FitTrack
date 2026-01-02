import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/vital_reading.dart';

// Service to manage vital readings storage and retrieval
class VitalsService {
  static const String _storageKey = 'vital_readings';

  // Save a new vital reading
  Future<void> saveReading(VitalReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    final readings = await getAllReadings();
    readings.add(reading);
    
    final jsonList = readings.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  // Get all readings
  Future<List<VitalReading>> getAllReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => VitalReading.fromMap(json)).toList();
  }

  // Get readings by type
  Future<List<VitalReading>> getReadingsByType(VitalType type) async {
    final allReadings = await getAllReadings();
    return allReadings.where((r) => r.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get latest reading for a type
  Future<VitalReading?> getLatestReading(VitalType type) async {
    final readings = await getReadingsByType(type);
    return readings.isEmpty ? null : readings.first;
  }

  // Get average for a type over last N days
  Future<double?> getAverage(VitalType type, int days) async {
    final readings = await getReadingsByType(type);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final recentReadings = readings
        .where((r) => r.timestamp.isAfter(cutoffDate))
        .toList();
    
    if (recentReadings.isEmpty) return null;
    
    final sum = recentReadings.fold<double>(0, (sum, r) => sum + r.value);
    return sum / recentReadings.length;
  }

  // Generate dummy data for testing
  Future<void> generateDummyData() async {
    final now = DateTime.now();
    final readings = <VitalReading>[];

    // Heart Rate - last 7 days
    for (int i = 0; i < 7; i++) {
      readings.add(VitalReading(
        id: 'hr_$i',
        type: VitalType.heartRate,
        value: 70 + (i * 2).toDouble(),
        timestamp: now.subtract(Duration(days: i)),
      ));
    }

    // Blood Pressure
    for (int i = 0; i < 5; i++) {
      readings.add(VitalReading(
        id: 'bp_$i',
        type: VitalType.bloodPressure,
        value: 120 + i.toDouble(),
        secondaryValue: 80 + i.toDouble(),
        timestamp: now.subtract(Duration(days: i)),
      ));
    }

    // Blood Oxygen
    for (int i = 0; i < 7; i++) {
      readings.add(VitalReading(
        id: 'spo2_$i',
        type: VitalType.bloodOxygen,
        value: 97 + (i % 3).toDouble(),
        timestamp: now.subtract(Duration(days: i)),
      ));
    }

    // Save all dummy readings
    for (final reading in readings) {
      await saveReading(reading);
    }
  }
}

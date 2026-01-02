import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 1)
class Activity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime endTime;

  @HiveField(4)
  final double distance; // in km

  @HiveField(5)
  final int steps;

  @HiveField(6)
  final int heartPoints;

  @HiveField(7)
  final ActivityType type;

  Activity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.steps,
    required this.heartPoints,
    required this.type,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  factory Activity.fromSteps({
    required int steps,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final distance = steps * 0.0008; // Rough conversion
    final heartPoints = (distance * 2).round(); // Dummy calculation
    
    return Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _getActivityName(startTime),
      startTime: startTime,
      endTime: endTime,
      distance: distance,
      steps: steps,
      heartPoints: heartPoints,
      type: ActivityType.walking,
    );
  }

  static String _getActivityName(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) return 'Morning walk';
    if (hour >= 11 && hour < 16) return 'Afternoon walk';
    if (hour >= 16 && hour < 21) return 'Evening walk';
    return 'Late night walk';
  }
}

@HiveType(typeId: 2)
enum ActivityType {
  @HiveField(0)
  walking,
  @HiveField(1)
  running,
  @HiveField(2)
  cycling,
  @HiveField(3)
  manual,
}
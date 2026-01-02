import 'package:hive/hive.dart';

part 'daily_summary.g.dart';

@HiveType(typeId: 3)
class DailySummary extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final int totalSteps;

  @HiveField(2)
  final int totalHeartPoints;

  @HiveField(3)
  final double totalDistance;

  @HiveField(4)
  final List<String> activityIds;

  DailySummary({
    required this.date,
    required this.totalSteps,
    required this.totalHeartPoints,
    required this.totalDistance,
    required this.activityIds,
  });

  // Activity ring progress (0.0 to 1.0)
  double get stepsProgress => (totalSteps / 10000).clamp(0.0, 1.0);
  double get heartPointsProgress => (totalHeartPoints / 30).clamp(0.0, 1.0);

  factory DailySummary.empty(DateTime date) {
    return DailySummary(
      date: DateTime(date.year, date.month, date.day),
      totalSteps: 0,
      totalHeartPoints: 0,
      totalDistance: 0.0,
      activityIds: [],
    );
  }

  DailySummary copyWith({
    int? totalSteps,
    int? totalHeartPoints,
    double? totalDistance,
    List<String>? activityIds,
  }) {
    return DailySummary(
      date: date,
      totalSteps: totalSteps ?? this.totalSteps,
      totalHeartPoints: totalHeartPoints ?? this.totalHeartPoints,
      totalDistance: totalDistance ?? this.totalDistance,
      activityIds: activityIds ?? this.activityIds,
    );
  }
}
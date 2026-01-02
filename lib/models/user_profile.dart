import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 4)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String gender;

  @HiveField(2)
  DateTime dob;

  @HiveField(3)
  double heightCm;

  @HiveField(4)
  double weightKg;

  @HiveField(5)
  int dailyStepGoal;

  @HiveField(6)
  int weeklyHeartGoal;

  @HiveField(7)
  int bedtimeHour;

  @HiveField(8)
  int bedtimeMinute;

  @HiveField(9)
  int wakeUpHour;

  @HiveField(10)
  int wakeUpMinute;

  @HiveField(11)
  String email;

  @HiveField(12)
  String photoUrl;

  UserProfile({
    required this.name,
    required this.gender,
    required this.dob,
    required this.heightCm,
    required this.weightKg,
    required this.dailyStepGoal,
    required this.weeklyHeartGoal,
    required this.bedtimeHour,
    required this.bedtimeMinute,
    required this.wakeUpHour,
    required this.wakeUpMinute,
    required this.email,
    required this.photoUrl,
  });

  TimeOfDay get bedtime => TimeOfDay(hour: bedtimeHour, minute: bedtimeMinute);
  TimeOfDay get wakeUp => TimeOfDay(hour: wakeUpHour, minute: wakeUpMinute);

  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: 'User',
      gender: 'Other',
      dob: DateTime.now().subtract(const Duration(days: 365 * 25)),
      heightCm: 170.0,
      weightKg: 70.0,
      dailyStepGoal: 10000,
      weeklyHeartGoal: 150,
      bedtimeHour: 22,
      bedtimeMinute: 0,
      wakeUpHour: 7,
      wakeUpMinute: 0,
      email: '',
      photoUrl: '',
    );
  }
}

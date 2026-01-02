// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 4;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      gender: fields[1] as String,
      dob: fields[2] as DateTime,
      heightCm: fields[3] as double,
      weightKg: fields[4] as double,
      dailyStepGoal: fields[5] as int,
      weeklyHeartGoal: fields[6] as int,
      bedtimeHour: fields[7] as int,
      bedtimeMinute: fields[8] as int,
      wakeUpHour: fields[9] as int,
      wakeUpMinute: fields[10] as int,
      email: fields[11] as String,
      photoUrl: fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.gender)
      ..writeByte(2)
      ..write(obj.dob)
      ..writeByte(3)
      ..write(obj.heightCm)
      ..writeByte(4)
      ..write(obj.weightKg)
      ..writeByte(5)
      ..write(obj.dailyStepGoal)
      ..writeByte(6)
      ..write(obj.weeklyHeartGoal)
      ..writeByte(7)
      ..write(obj.bedtimeHour)
      ..writeByte(8)
      ..write(obj.bedtimeMinute)
      ..writeByte(9)
      ..write(obj.wakeUpHour)
      ..writeByte(10)
      ..write(obj.wakeUpMinute)
      ..writeByte(11)
      ..write(obj.email)
      ..writeByte(12)
      ..write(obj.photoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import 'activity_repository.dart';

class StepTrackingService {
  final ActivityRepository _repository;
  StreamSubscription<StepCount>? _stepCountStream;

  int _baseStepCount = 0;
  int _currentDailySteps = 0;
  DateTime _sessionStartTime = DateTime.now();
  int _sessionStartSteps = 0;
  bool _isTracking = false;

  StepTrackingService(this._repository);

  Stream<int> get stepStream => _stepController.stream;
  final _stepController = StreamController<int>.broadcast();

  Future<void> startTracking() async {
    if (_isTracking) return;

    if (await Permission.activityRecognition.request().isGranted) {
      _isTracking = true;
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );
    }
  }

  void _onStepCount(StepCount event) {
    final totalSteps = event.steps;

    // Initialize base count on first reading
    if (_baseStepCount == 0) {
      _baseStepCount = totalSteps;
      _sessionStartSteps = totalSteps;
      _currentDailySteps = 0;
    } else {
      _currentDailySteps = totalSteps - _baseStepCount;
    }

    // Emit current daily steps immediately
    _stepController.add(_currentDailySteps);

    // Update repository
    _repository.updateStepsForToday(_currentDailySteps);

    // Check for walking session (every 50 steps)
    if ((totalSteps - _sessionStartSteps) >= 50) {
      _checkForWalkingSession(totalSteps);
    }
  }

  void _checkForWalkingSession(int totalSteps) {
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime);
    final sessionSteps = totalSteps - _sessionStartSteps;

    // Create activity if session is 2+ minutes and 50+ steps
    if (sessionDuration.inMinutes >= 2 && sessionSteps >= 50) {
      final activity = Activity.fromSteps(
        steps: sessionSteps,
        startTime: _sessionStartTime,
        endTime: now,
      );

      _repository.saveActivity(activity);

      // Reset session tracking
      _sessionStartTime = now;
      _sessionStartSteps = totalSteps;
    }
  }

  void _onStepCountError(error) {
    debugPrint('Step Counter Error: $error');
    // Don't stop tracking on error, pedometer will retry
  }

  void dispose() {
    _stepCountStream?.cancel();
    _stepController.close();
    _isTracking = false;
  }
}

// Riverpod providers
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

final stepTrackingServiceProvider = Provider<StepTrackingService>((ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return StepTrackingService(repository);
});

final currentStepsProvider = StreamProvider<int>((ref) {
  final service = ref.watch(stepTrackingServiceProvider);
  return service.stepStream;
});

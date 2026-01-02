import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class DailyStepTracker extends StatefulWidget {
  const DailyStepTracker({super.key});

  @override
  _DailyStepTrackerState createState() => _DailyStepTrackerState();
}

class _DailyStepTrackerState extends State<DailyStepTracker> {
  int _todaySteps = 0;
  int _sensorSteps = 0;
  int _baselineSteps = 0;
  String _lastSavedDate = '';

  StreamSubscription<StepCount>? _stepCountStream;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _initializeDailyTracking();
  }

  // Initialize daily step tracking system
  Future<void> _initializeDailyTracking() async {
    // Load stored data first
    await _loadStoredData();

    // Check if new day started
    await _checkForNewDay();

    // Start step counting
    await _startStepCounting();

    // Setup midnight reset timer
    _setupMidnightTimer();
  }

  // Load stored step data from device storage
  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    setState(() {
      // Load today's accumulated steps
      _todaySteps = prefs.getInt('steps_$today') ?? 0;

      // Load sensor baseline (last known sensor reading)
      _baselineSteps = prefs.getInt('baseline_steps') ?? 0;

      // Load last saved date
      _lastSavedDate = prefs.getString('last_saved_date') ?? '';
    });
  }

  // Check if a new day has started and reset if needed
  Future<void> _checkForNewDay() async {
    final today = _getTodayKey();

    // If last saved date is different from today, it's a new day
    if (_lastSavedDate.isNotEmpty && _lastSavedDate != today) {
      await _resetForNewDay();
    }
  }

  // Reset step count for new day
  Future<void> _resetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    setState(() {
      _todaySteps = 0; // Reset today's steps to 0
      _baselineSteps = _sensorSteps; // Set new baseline from current sensor
    });

    // Save reset data
    await prefs.setInt('steps_$today', 0);
    await prefs.setInt('baseline_steps', _baselineSteps);
    await prefs.setString('last_saved_date', today);

    debugPrint('🌅 New day started! Steps reset to 0');
  }

  // Start listening to step counter sensor
  Future<void> _startStepCounting() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) => debugPrint('Step Count Error: $error'),
      );
    }
  }

  // Handle new step count from sensor
  void _onStepCount(StepCount event) {
    setState(() {
      _sensorSteps = event.steps;
    });

    // Calculate today's steps and save
    _calculateAndSaveTodaySteps();
  }

  // Calculate today's steps from sensor data
  void _calculateAndSaveTodaySteps() {
    // If no baseline set, use current sensor reading as baseline
    if (_baselineSteps == 0) {
      _baselineSteps = _sensorSteps;
      _saveTodaySteps();
      return;
    }

    // Calculate steps taken today = current sensor - baseline
    int newStepsToday = _sensorSteps - _baselineSteps;

    // Only update if positive (sensor can reset)
    if (newStepsToday >= 0) {
      setState(() {
        _todaySteps = newStepsToday;
      });
      _saveTodaySteps();
    }
  }

  // Save today's steps to local storage
  Future<void> _saveTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    await prefs.setInt('steps_$today', _todaySteps);
    await prefs.setInt('baseline_steps', _baselineSteps);
    await prefs.setString('last_saved_date', today);
  }

  // Setup timer to reset at midnight
  void _setupMidnightTimer() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    // Set timer for midnight
    _midnightTimer = Timer(timeUntilMidnight, () {
      _resetForNewDay();
      _setupMidnightTimer(); // Setup next day's timer
    });

    debugPrint(
        '⏰ Midnight reset timer set for: ${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes % 60}m');
  }

  // Get today's date as storage key (YYYY-MM-DD format)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Step Tracker'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Today's date
            Text(
              _getTodayKey(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Main step count card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Steps Today',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_todaySteps',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Debug info (for development)
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Info:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Sensor Steps: $_sensorSteps'),
                    Text('Baseline Steps: $_baselineSteps'),
                    Text('Last Saved: $_lastSavedDate'),
                    Text('Today Key: ${_getTodayKey()}'),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Manual reset button (for testing)
            ElevatedButton(
              onPressed: _resetForNewDay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset for New Day (Test)'),
            ),
          ],
        ),
      ),
    );
  }
}

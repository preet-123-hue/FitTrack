import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Main fitness tracking screen following Flutter best practices
class RefactoredFitnessScreen extends StatefulWidget {
  const RefactoredFitnessScreen({super.key});

  @override
  State<RefactoredFitnessScreen> createState() =>
      _RefactoredFitnessScreenState();
}

class _RefactoredFitnessScreenState extends State<RefactoredFitnessScreen> {
  // Step tracking variables with meaningful names
  int currentDailyStepCount = 0;
  int previousSensorReading = 0;
  StreamSubscription<StepCount>? stepCounterSubscription;

  // Constants for calculations
  static const double caloriesPerStep = 0.04;
  static const double kilometersPerStep = 0.0008;
  static const String stepCountStoragePrefix = 'daily_steps_';
  static const String lastSensorReadingKey = 'last_sensor_reading';

  @override
  void initState() {
    super.initState();
    _initializeFitnessTracking();
  }

  @override
  void dispose() {
    stepCounterSubscription?.cancel();
    super.dispose();
  }

  /// Initialize fitness tracking system
  Future<void> _initializeFitnessTracking() async {
    await _loadStoredStepData();
    await _requestPermissionsAndStartTracking();
  }

  /// Load previously stored step data from device storage
  Future<void> _loadStoredStepData() async {
    final preferences = await SharedPreferences.getInstance();
    final todayDateKey = _generateTodayDateKey();

    setState(() {
      currentDailyStepCount =
          preferences.getInt('$stepCountStoragePrefix$todayDateKey') ?? 0;
      previousSensorReading = preferences.getInt(lastSensorReadingKey) ?? 0;
    });
  }

  /// Request activity recognition permission and start step tracking
  Future<void> _requestPermissionsAndStartTracking() async {
    final permissionStatus = await Permission.activityRecognition.request();

    if (permissionStatus.isGranted) {
      _startListeningToStepCounter();
    } else {
      _showPermissionDeniedMessage();
    }
  }

  /// Start listening to device step counter sensor
  void _startListeningToStepCounter() {
    stepCounterSubscription = Pedometer.stepCountStream.listen(
      _handleNewStepCount,
      onError: _handleStepCountError,
    );
  }

  /// Handle new step count data from sensor
  void _handleNewStepCount(StepCount stepCountEvent) {
    final currentSensorReading = stepCountEvent.steps;

    // Initialize baseline on first reading
    if (previousSensorReading == 0) {
      previousSensorReading = currentSensorReading;
      _saveStepDataToStorage();
      return;
    }

    // Calculate new steps since last reading
    final newStepsSinceLastReading =
        currentSensorReading - previousSensorReading;

    // Only add positive step differences (handles sensor resets)
    if (newStepsSinceLastReading > 0) {
      setState(() {
        currentDailyStepCount += newStepsSinceLastReading;
      });

      previousSensorReading = currentSensorReading;
      _saveStepDataToStorage();
    }
  }

  /// Handle step counter sensor errors
  void _handleStepCountError(dynamic error) {
    debugPrint('Step counter error: $error');
    _showErrorMessage('Step counter unavailable: $error');
  }

  /// Save current step data to device storage
  Future<void> _saveStepDataToStorage() async {
    final preferences = await SharedPreferences.getInstance();
    final todayDateKey = _generateTodayDateKey();

    await preferences.setInt(
        '$stepCountStoragePrefix$todayDateKey', currentDailyStepCount);
    await preferences.setInt(lastSensorReadingKey, previousSensorReading);
  }

  /// Generate today's date key for storage (YYYY-MM-DD format)
  String _generateTodayDateKey() {
    final currentDate = DateTime.now();
    return '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
  }

  /// Calculate calories burned from step count
  double get calculatedCaloriesBurned =>
      currentDailyStepCount * caloriesPerStep;

  /// Calculate distance walked from step count
  double get calculatedDistanceInKilometers =>
      currentDailyStepCount * kilometersPerStep;

  /// Show permission denied message to user
  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Activity recognition permission is required for step counting'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Show error message to user
  void _showErrorMessage(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// Build app bar with title
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'FitTrack',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
    );
  }

  /// Build main body content
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildStepCountCard(),
          const SizedBox(height: 16),
          _buildMetricsRow(),
          const SizedBox(height: 24),
          _buildMotivationalMessage(),
        ],
      ),
    );
  }

  /// Build welcome header text
  Widget _buildWelcomeHeader() {
    return Text(
      'Today\'s Activity',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
    );
  }

  /// Build main step count display card
  Widget _buildStepCountCard() {
    return _buildMetricCard(
      icon: Icons.directions_walk,
      title: 'Steps Today',
      value: currentDailyStepCount.toString(),
      color: const Color(0xFF4CAF50),
      isLargeCard: true,
    );
  }

  /// Build row containing calories and distance metrics
  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.local_fire_department,
            title: 'Calories',
            value: '${calculatedCaloriesBurned.toStringAsFixed(1)} cal',
            color: const Color(0xFFFF7043),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.straighten,
            title: 'Distance',
            value: '${calculatedDistanceInKilometers.toStringAsFixed(2)} km',
            color: const Color(0xFF42A5F5),
          ),
        ),
      ],
    );
  }

  /// Build reusable metric card widget
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLargeCard = false,
  }) {
    final cardPadding = isLargeCard ? 24.0 : 20.0;
    final iconSize = isLargeCard ? 40.0 : 28.0;
    final valueTextSize = isLargeCard ? 48.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(isLargeCard ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: isLargeCard ? 10 : 8,
            offset: Offset(0, isLargeCard ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildIconContainer(icon, color, iconSize),
          SizedBox(height: isLargeCard ? 16 : 12),
          _buildCardTitle(title),
          SizedBox(height: isLargeCard ? 8 : 4),
          _buildCardValue(value, valueTextSize),
        ],
      ),
    );
  }

  /// Build icon container with colored background
  Widget _buildIconContainer(IconData icon, Color color, double size) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }

  /// Build card title text
  Widget _buildCardTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Build card value text
  Widget _buildCardValue(String value, double fontSize) {
    return Text(
      value,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  /// Build motivational message card
  Widget _buildMotivationalMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '🎯 Keep moving! Every step counts towards a healthier you.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

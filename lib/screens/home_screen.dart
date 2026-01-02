import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  
  const HomeScreen({super.key, required this.toggleTheme, required this.isDarkMode});
  
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _todaySteps = 0; // Today's total steps from storage
  StreamSubscription<StepCount>? _stepCountStream;
  int? _lastStoredSteps; // Last step count we stored
  final List<int> _weeklySteps = []; // Last 7 days step data
  
  // Calculate calories and distance from today's steps
  double get _calories => _todaySteps * 0.04;
  double get _distance => _todaySteps * 0.0008; // km
  
  @override
  void initState() {
    super.initState();
    _loadTodaySteps(); // Load stored steps first
    _loadWeeklySteps(); // Load last 7 days data
    _requestPermissionAndStartCounting();
  }
  
  // Load today's steps from local storage
  Future<void> _loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    
    // Get stored steps for today, default to 0
    _todaySteps = prefs.getInt(today) ?? 0;
    setState(() {});
  }
  
  // Load last 7 days step data for chart
  Future<void> _loadWeeklySteps() async {
    final prefs = await SharedPreferences.getInstance();
    _weeklySteps.clear();
    
    // Get steps for last 7 days (including today)
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      final steps = prefs.getInt(dateKey) ?? 0;
      _weeklySteps.add(steps);
    }
    setState(() {});
  }
  
  // Get date key for any date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // Get today's date as storage key (format: 2024-01-15)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  // Save today's steps to local storage
  Future<void> _saveTodaySteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    await prefs.setInt(today, steps);
    
    // Update weekly data when today's steps change
    _loadWeeklySteps();
  }
  
  Future<void> _requestPermissionAndStartCounting() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error) => debugPrint('Step Count Error: $error'),
      );
    }
  }
  
  // Handle new step count from sensor
  void _onStepCount(StepCount event) {
    // First time getting steps - store as baseline
    if (_lastStoredSteps == null) {
      _lastStoredSteps = event.steps;
      return;
    }
    
    // Calculate step difference since last reading
    int stepDifference = event.steps - _lastStoredSteps!;
    
    // Only add positive differences (new steps)
    if (stepDifference > 0) {
      _todaySteps += stepDifference;
      _saveTodaySteps(_todaySteps); // Save to storage
      setState(() {});
    }
    
    // Update last stored steps
    _lastStoredSteps = event.steps;
  }
  
  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Today\'s Activity',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            
            // Main stats cards
            Expanded(
              child: Column(
                children: [
                  // Steps card (larger)
                  _buildMainCard(
                    icon: Icons.directions_walk,
                    title: 'Steps Today',
                    value: _todaySteps.toString(),
                    color: const Color(0xFF4CAF50),
                    isMain: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Weekly summary
                  _buildWeeklySummary(),
                  const SizedBox(height: 16),
                  
                  // Calories and Distance row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department,
                          title: 'Calories',
                          value: '${_calories.toStringAsFixed(1)} cal',
                          color: const Color(0xFFFF7043),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.straighten,
                          title: 'Distance',
                          value: '${_distance.toStringAsFixed(2)} km',
                          color: const Color(0xFF42A5F5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Main card for steps (larger)
  Widget _buildMainCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isMain = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
  
  // Smaller cards for calories and distance
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
  
  // Weekly summary widget
  Widget _buildWeeklySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Total steps this week: ${_weeklySteps.fold(0, (sum, steps) => sum + steps)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'screens/vitals_dashboard_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/profile_screen_new.dart';
import 'models/vital_reading.dart';
import 'models/user_profile.dart';
import 'services/vitals_service.dart';
import 'services/step_tracking_service.dart';
import 'services/activity_repository.dart';
// For DateFormat

// Import with prefix to resolve ambiguous provider
import 'package:fittrack/services/step_tracking_service.dart' as steps_service;

// Main function - app starts here
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive first
  try {
    await Hive.initFlutter();
    if (kDebugMode) {
      print('Hive initialized successfully');
    }
    // Ensure the user profile adapter is registered and the profiles box is open
    try {
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
    } catch (_) {}
    try {
      if (!Hive.isBoxOpen('profiles')) {
        await Hive.openBox<UserProfile>('profiles');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Could not open profiles box early: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Hive initialization failed: $e');
    }
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
  }
  runApp(const ProviderScope(child: FitTrackApp()));
}

// Root app widget
class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// Main navigation screen with bottom tabs
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FitnessScreen(), // Home
    const JournalScreen(), // Journal
    const VitalsDashboardScreen(), // Browse (Vitals)
    const ProfileScreen(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Main fitness tracking screen (Home tab)
class FitnessScreen extends ConsumerStatefulWidget {
  const FitnessScreen({super.key});

  @override
  ConsumerState<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends ConsumerState<FitnessScreen> {
  late VitalsService _vitalsService;
  final Map<VitalType, VitalReading?> _latestVitals = {};
  late ActivityRepository _repository;
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    try {
      _vitalsService = VitalsService();
    } catch (e) {
      _initError = 'Vitals service error: $e';
      if (kDebugMode) {
        print(_initError);
      }
    }
    _loadLatestVitals();
    _initStepTracking();
  }

  Future<void> _initStepTracking() async {
    try {
      _repository = ref.read(steps_service.activityRepositoryProvider);
      await _repository.init();

      final stepService = ref.read(stepTrackingServiceProvider);
      await stepService.startTracking();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing step tracking: $e');
      }
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  // Load latest vitals for summary
  Future<void> _loadLatestVitals() async {
    try {
      if (_initError != null) return; // Skip if vitals service failed
      for (final type in [
        VitalType.heartRate,
        VitalType.bloodPressure,
        VitalType.bloodOxygen
      ]) {
        final reading = await _vitalsService.getLatestReading(type);
        if (mounted) {
          setState(() {
            _latestVitals[type] = reading;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vitals: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Return placeholder until initialization completes
      if (!_isInitialized) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'FitTrack',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue,
            elevation: 0,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final currentSteps = ref.watch(currentStepsProvider);
      final steps = currentSteps.when(
        data: (steps) => steps,
        loading: () => 0,
        error: (_, __) => 0,
      );

      final calories = steps * 0.04;
      final distance = steps * 0.0008;

      // Safely get profile with fallback
      UserProfile profile;
      try {
        profile = _repository.getUserProfile();
      } catch (e) {
        profile = UserProfile.defaultProfile();
      }

      return Scaffold(
        // App bar with profile and info
        appBar: AppBar(
          title: const Text(
            'FitTrack',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => _showFitInfo(context),
              icon: const Icon(Icons.info_outline),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                      color: Colors.blue[700], fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        // Main content
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Welcome header
              Text(
                'Today\'s Activity',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 30),

              // Steps card with real-time updates
              _buildStatCard(
                icon: Icons.directions_walk,
                title: 'Steps',
                value: steps.toString(),
                color: Colors.green,
                isLive: currentSteps.isLoading,
              ),
              const SizedBox(height: 20),

              // Calories card
              _buildStatCard(
                icon: Icons.local_fire_department,
                title: 'Calories',
                value: calories.toStringAsFixed(1),
                color: Colors.orange,
              ),
              const SizedBox(height: 20),

              // Distance card
              _buildStatCard(
                icon: Icons.straighten,
                title: 'Distance (km)',
                value: distance.toStringAsFixed(2),
                color: Colors.blue,
              ),

              const SizedBox(height: 30),

              // Latest Vitals Summary
              _buildVitalsSummary(),

              const SizedBox(height: 30),

              // Heart rate message
              _buildHeartRateMessage(),

              const SizedBox(height: 20),

              // Motivational message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Keep moving! Every step counts! 🚶♂️',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in FitnessScreen build: $e');
      }
      // Fallback UI if build fails
      return Scaffold(
        appBar: AppBar(
          title: const Text('FitTrack'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${e.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Build vitals summary section
  Widget _buildVitalsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Vitals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildVitalSummaryCard(
                type: VitalType.heartRate,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVitalSummaryCard(
                type: VitalType.bloodPressure,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildVitalSummaryCard(
          type: VitalType.bloodOxygen,
          color: Colors.blue,
          isWide: true,
        ),
      ],
    );
  }

  // Build individual vital summary card
  Widget _buildVitalSummaryCard({
    required VitalType type,
    required Color color,
    bool isWide = false,
  }) {
    final reading = _latestVitals[type];
    final hasData = reading != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? type == VitalType.bloodPressure
                    ? '${reading.value.toInt()}/${reading.secondaryValue?.toInt() ?? 0}'
                    : reading.value.toStringAsFixed(1)
                : '--',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasData ? color : Colors.grey,
            ),
          ),
          Text(
            type.unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build stat cards
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLive = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container with live indicator
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              if (isLive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),

          // Title and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build heart rate message
  Widget _buildHeartRateMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.watch,
            color: Colors.orange[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Connect a wearable to enable real-time heart rate.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The following widgets were unused and have been removed to resolve warnings:
  // (Removed unused helper widgets to reduce analyzer warnings)

  // Show Google Fit-style info dialog
  void _showFitInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keep track of your activity'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 48),
            SizedBox(height: 8),
            Text(
              'Heart Points\nPick up the pace to score points',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Icon(Icons.directions_walk, color: Colors.green, size: 48),
            SizedBox(height: 8),
            Text(
              'Steps\nJust keep moving to meet this goal',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

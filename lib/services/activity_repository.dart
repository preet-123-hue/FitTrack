import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity.dart';
import '../models/daily_summary.dart';
import '../models/user_profile.dart';

class ActivityRepository {
  static const String _activitiesBox = 'activities';
  static const String _summariesBox = 'daily_summaries';
  // Use a stable box name for profiles
  static const String _profileBox = 'profiles';

  // Use nullable boxes and guard access to avoid LateInitializationError
  Box<Activity>? _activities;
  Box<DailySummary>? _summaries;
  Box<UserProfile>? _profiles;
  bool _initialized = false;

  /// Check if repository is initialized
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) {
      return; // Already initialized
    }

    try {
      // Initialize Hive if not already done
      // Ensure Hive is initialized (safe to call multiple times)
      try {
        await Hive.initFlutter();
      } catch (_) {}

      // Register adapters if needed
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ActivityAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ActivityTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(DailySummaryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(UserProfileAdapter());
      }

      // Open or reference boxes
      if (Hive.isBoxOpen(_activitiesBox)) {
        _activities = Hive.box<Activity>(_activitiesBox);
      } else {
        _activities = await Hive.openBox<Activity>(_activitiesBox);
      }

      if (Hive.isBoxOpen(_summariesBox)) {
        _summaries = Hive.box<DailySummary>(_summariesBox);
      } else {
        _summaries = await Hive.openBox<DailySummary>(_summariesBox);
      }

      if (Hive.isBoxOpen(_profileBox)) {
        _profiles = Hive.box<UserProfile>(_profileBox);
      } else {
        _profiles = await Hive.openBox<UserProfile>(_profileBox);
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing ActivityRepository: $e');
      rethrow;
    }
  }

  Future<void> saveActivity(Activity activity) async {
    // Ensure repository is initialized before performing writes
    await init();
    if (_activities == null) return;
    await _activities!.put(activity.id, activity);
    await _updateDailySummary(activity);
  }

  List<Activity> getActivitiesForDate(DateTime date) {
    // If not initialized yet, return empty list to avoid crashes
    if (_activities == null || !_activities!.isOpen) return [];
    final dateKey = _dateKey(date);
    final list = _activities!.values
        .where((activity) => _dateKey(activity.startTime) == dateKey)
        .toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  DailySummary getDailySummary(DateTime date) {
    if (_summaries == null || !_summaries!.isOpen) {
      return DailySummary.empty(date);
    }
    final key = _dateKey(date);
    return _summaries!.get(key) ?? DailySummary.empty(date);
  }

  Future<void> updateStepsForToday(int totalSteps) async {
    await init();
    final today = DateTime.now();
    final summary = getDailySummary(today);

    final updatedSummary = summary.copyWith(
      totalSteps: totalSteps,
      totalDistance: totalSteps * 0.0008,
      totalHeartPoints: (totalSteps * 0.0008 * 2).round(),
    );

    if (_summaries != null) {
      await _summaries!.put(_dateKey(today), updatedSummary);
    }
  }

  Future<void> _updateDailySummary(Activity activity) async {
    await init();
    final date = activity.startTime;
    final summary = getDailySummary(date);

    final updatedSummary = summary.copyWith(
      totalSteps: summary.totalSteps + activity.steps,
      totalHeartPoints: summary.totalHeartPoints + activity.heartPoints,
      totalDistance: summary.totalDistance + activity.distance,
      activityIds: [...summary.activityIds, activity.id],
    );

    if (_summaries != null) {
      await _summaries!.put(_dateKey(date), updatedSummary);
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  UserProfile getUserProfile() {
    try {
      if (_profiles == null || !_profiles!.isOpen) {
        return UserProfile.defaultProfile();
      }
      return _profiles!.get('profile') ?? UserProfile.defaultProfile();
    } catch (e) {
      print('Error getting user profile: $e');
      return UserProfile.defaultProfile();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await init();
    try {
      if (_profiles == null || !_profiles!.isOpen) {
        _profiles = await Hive.openBox<UserProfile>(_profileBox);
      }
      await _profiles!.put('profile', profile);
    } catch (e) {
      print('Error saving user profile: $e');
      rethrow;
    }
  }

  List<DailySummary> getWeeklyProgress() {
    if (_summaries == null || !_summaries!.isOpen) {
      // Return a week of empty summaries if not ready
      final today = DateTime.now();
      return List.generate(
          7, (i) => DailySummary.empty(today.subtract(Duration(days: 6 - i))));
    }
    final today = DateTime.now();
    final weeklyData = <DailySummary>[];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      weeklyData.add(getDailySummary(date));
    }

    return weeklyData;
  }

}

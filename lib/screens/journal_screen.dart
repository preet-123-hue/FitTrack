import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../services/activity_repository.dart';
import '../services/step_tracking_service.dart';
import '../widgets/activity_ring.dart';
import '../models/daily_summary.dart';
import 'package:intl/intl.dart';
import 'package:fittrack/services/step_tracking_service.dart' as steps_service;

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  late ActivityRepository _repository;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    try {
      _repository = ref.read(steps_service.activityRepositoryProvider);
      await _repository.init();

      // Start step tracking
      final stepService = ref.read(stepTrackingServiceProvider);
      await stepService.startTracking();
      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // real-time updates handled in sections via providers

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_ready) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              _buildDaySection('Today', today),
              const SizedBox(height: 24),
              _buildDaySection('Yesterday', yesterday),
              const SizedBox(height: 24),
              // Last 5 days
              for (int i = 2; i < 7; i++)
                _buildDaySection(
                    DateFormat('EEEE, MMM d')
                        .format(today.subtract(Duration(days: i))),
                    today.subtract(Duration(days: i))),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showAddActivityDialog();
          if (result == true && mounted) setState(() {});
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDaySection(String title, DateTime date) {
    final DailySummary summary = _repository.getDailySummary(date);
    final List<Activity> activities = _repository.getActivitiesForDate(date);

    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Consumer(builder: (context, ref, _) {
      final currentStepsAsync =
          isToday ? ref.watch(currentStepsProvider) : null;
      final int displaySteps =
          (isToday && currentStepsAsync != null && currentStepsAsync.hasValue)
              ? currentStepsAsync.value!
              : summary.totalSteps;

      final int displayHeartPoints =
          (isToday && currentStepsAsync != null && currentStepsAsync.hasValue)
              ? (currentStepsAsync.value! * 0.0008 * 2).round()
              : summary.totalHeartPoints;

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(DateFormat('EEEE, MMM d').format(date),
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ActivityRing(
                        size: 56,
                        stepsProgress: (displaySteps / 10000).clamp(0.0, 1.0),
                        heartPointsProgress:
                            (displayHeartPoints / 30).clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 8),
                      Text('$displaySteps steps',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('$displayHeartPoints pts',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: displaySteps.toString(),
                      color: Colors.green),
                  const SizedBox(width: 24),
                  _buildStatItem(
                      icon: Icons.favorite,
                      label: 'Heart Points',
                      value: displayHeartPoints.toString(),
                      color: Colors.red),
                ],
              ),
              if (activities.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                ...activities.map((a) => _buildActivityItem(a)),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(DateFormat('h:mm a').format(activity.startTime),
                style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8)),
            child:
                const Icon(Icons.directions_walk, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                    '${activity.distance.toStringAsFixed(2)} km • ${activity.durationMinutes} min',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.directions_walk,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${activity.steps} steps',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${activity.heartPoints} pts',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> showAddActivityDialog() async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddActivitySheet(repository: _repository),
    );
  }
}

class _AddActivitySheet extends StatefulWidget {
  final ActivityRepository repository;
  const _AddActivitySheet({required this.repository});

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  ActivityType _type = ActivityType.walking;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final _durationController = TextEditingController();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _durationController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    final startTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final duration = int.tryParse(_durationController.text) ?? 0;
    final steps = int.tryParse(_stepsController.text) ?? 0;
    final calories = double.tryParse(_caloriesController.text) ?? 0.0;
    final endTime = startTime.add(Duration(minutes: duration));
    final distance = steps * 0.0008;
    final heartPoints = (distance * 2).round();

    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${_type.name.substring(0, 1).toUpperCase()}${_type.name.substring(1)}',
      startTime: startTime,
      endTime: endTime,
      distance: distance,
      steps: steps,
      heartPoints: heartPoints,
      type: _type,
    );

    await widget.repository.saveActivity(activity);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Activity Type', border: OutlineInputBorder()),
                items: ActivityType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                        if (picked != null) setState(() => _date = picked);
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('MMM d, y').format(_date)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _time);
                        if (picked != null) setState(() => _time = picked);
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_time.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stepsController,
                decoration: const InputDecoration(labelText: 'Steps', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveActivity,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

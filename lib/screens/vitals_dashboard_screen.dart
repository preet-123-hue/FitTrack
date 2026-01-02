import 'package:flutter/material.dart';
import '../models/vital_reading.dart';
import '../services/vitals_service.dart';
import '../services/health_connect_service.dart';
import '../widgets/add_vital_reading_sheet.dart';
import 'heart_rate_detail_screen.dart';
import 'blood_glucose_detail_screen.dart';
import 'body_temperature_detail_screen.dart';
import 'respiratory_rate_detail_screen.dart';
import 'hrv_detail_screen.dart';

// Main Vitals Dashboard showing all health metrics
class VitalsDashboardScreen extends StatefulWidget {
  const VitalsDashboardScreen({super.key});

  @override
  State<VitalsDashboardScreen> createState() => _VitalsDashboardScreenState();
}

class _VitalsDashboardScreenState extends State<VitalsDashboardScreen> {
  final VitalsService _vitalsService = VitalsService();
  final HealthConnectService _healthConnect = HealthConnectService();
  final Map<VitalType, VitalReading?> _latestReadings = {};
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  // Load latest readings for all vital types
  Future<void> _loadVitals() async {
    setState(() => _isLoading = true);

    // Try to get data from Health Connect first
    _latestReadings[VitalType.heartRate] = await _healthConnect.getLatestHeartRate();
    _latestReadings[VitalType.restingHeartRate] = await _healthConnect.getLatestRestingHeartRate();
    _latestReadings[VitalType.bloodPressure] = await _healthConnect.getLatestBloodPressure();
    _latestReadings[VitalType.bloodOxygen] = await _healthConnect.getLatestBloodOxygen();
    _latestReadings[VitalType.bloodGlucose] = await _healthConnect.getLatestBloodGlucose();
    _latestReadings[VitalType.bodyTemperature] = await _healthConnect.getLatestBodyTemperature();
    _latestReadings[VitalType.respiratoryRate] = await _healthConnect.getLatestRespiratoryRate();
    _latestReadings[VitalType.hrv] = await _healthConnect.getLatestHRV();

    // Fallback to local data if Health Connect has no data
    for (final type in VitalType.values) {
      if (_latestReadings[type] == null) {
        _latestReadings[type] = await _vitalsService.getLatestReading(type);
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vitals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[400],
        elevation: 0,
        actions: [
          // Request Health Connect permissions
          IconButton(
            icon: Icon(_hasPermission ? Icons.health_and_safety : Icons.health_and_safety_outlined),
            onPressed: () async {
              final granted = await _healthConnect.requestPermissions();
              setState(() => _hasPermission = granted);
              if (granted) {
                _loadVitals();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Health Connect permissions granted')),
                  );
                }
              }
            },
            tooltip: 'Health Connect Permissions',
          ),
          // Generate dummy data button (for testing)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _vitalsService.generateDummyData();
              _loadVitals();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Dummy data generated')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVitals,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Text(
                    'Your Health Metrics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track and monitor your vital signs',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vital Cards
                  _buildVitalCard(
                    context,
                    type: VitalType.heartRate,
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HeartRateDetailScreen(),
                      ),
                    ).then((_) => _loadVitals()),
                  ),
                  const SizedBox(height: 12),

                  _buildVitalCard(
                    context,
                    type: VitalType.bloodPressure,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),

                  _buildVitalCard(
                    context,
                    type: VitalType.bloodOxygen,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  _buildVitalCard(
                    context,
                    type: VitalType.bloodGlucose,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BloodGlucoseDetailScreen(),
                      ),
                    ).then((_) => _loadVitals()),
                  ),
                  const SizedBox(height: 12),

                  _buildVitalCard(
                    context,
                    type: VitalType.bodyTemperature,
                    color: Colors.amber,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BodyTemperatureDetailScreen(),
                      ),
                    ).then((_) => _loadVitals()),
                  ),
                  const SizedBox(height: 12),

                  _buildVitalCard(
                    context,
                    type: VitalType.respiratoryRate,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RespiratoryRateDetailScreen(),
                      ),
                    ).then((_) => _loadVitals()),
                  ),
                  const SizedBox(height: 12),

                  _buildVitalCard(
                    context,
                    type: VitalType.hrv,
                    color: Colors.indigo,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HrvDetailScreen(),
                      ),
                    ).then((_) => _loadVitals()),
                  ),
                ],
              ),
            ),
    );
  }

  // Build individual vital card
  Widget _buildVitalCard(
    BuildContext context, {
    required VitalType type,
    required Color color,
    VoidCallback? onTap,
  }) {
    final reading = _latestReadings[type];
    final hasData = reading != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    type.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasData
                          ? type == VitalType.bloodPressure
                              ? '${reading.value.toInt()}/${reading.secondaryValue?.toInt() ?? 0} ${type.unit}'
                              : '${reading.value.toStringAsFixed(1)} ${type.unit}'
                          : 'No data yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasData ? color : Colors.grey,
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getTimeAgo(reading.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon and Add button
              Column(
                children: [
                  IconButton(
                    onPressed: () => _showAddReadingSheet(type),
                    icon: Icon(
                      Icons.add_circle,
                      color: color,
                      size: 28,
                    ),
                    tooltip: 'Add Reading',
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format time ago
  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // Show add reading bottom sheet
  void _showAddReadingSheet(VitalType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVitalReadingSheet(
        vitalType: type,
        onSaved: _loadVitals,
      ),
    );
  }
}

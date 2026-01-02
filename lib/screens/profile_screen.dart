import 'package:flutter/material.dart';
import '../models/vital_reading.dart';
import '../services/vitals_service.dart';

// Profile screen with user info and health preferences
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final VitalsService _vitalsService = VitalsService();
  bool _useCelsius = true;
  bool _use24HourFormat = true;
  final Map<VitalType, int> _vitalCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    // Count readings for each vital type
    for (final type in VitalType.values) {
      final readings = await _vitalsService.getReadingsByType(type);
      _vitalCounts[type] = readings.length;
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo[400],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Section
                  _buildUserInfoSection(),
                  const SizedBox(height: 24),
                  
                  // Health Preferences Section
                  _buildPreferencesSection(),
                  const SizedBox(height: 24),
                  
                  // Vitals Summary Section
                  _buildVitalsSummarySection(),
                  const SizedBox(height: 24),
                  
                  // App Info Section
                  _buildAppInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo[100],
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.indigo[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // User Name
            const Text(
              'John Doe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // User Details
            Text(
              'Age: 28 • Height: 5\'10" • Weight: 70 kg',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Edit Profile Button
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon!')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Temperature Unit
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.thermostat, color: Colors.orange[600]),
              title: const Text('Temperature Unit'),
              subtitle: Text(_useCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
              trailing: Switch(
                value: _useCelsius,
                onChanged: (value) {
                  setState(() => _useCelsius = value);
                },
              ),
            ),
            
            const Divider(),
            
            // Time Format
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.access_time, color: Colors.blue[600]),
              title: const Text('Time Format'),
              subtitle: Text(_use24HourFormat ? '24-hour format' : '12-hour format'),
              trailing: Switch(
                value: _use24HourFormat,
                onChanged: (value) {
                  setState(() => _use24HourFormat = value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSummarySection() {
    final totalReadings = _vitalCounts.values.fold(0, (sum, count) => sum + count);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Health Data Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalReadings total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Vital counts grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: VitalType.values.map((type) {
                final count = _vitalCounts[type] ?? 0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getVitalColor(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        type.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              type.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$count readings',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getVitalColor(type),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: Colors.blue[600]),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
            ),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.help_outline, color: Colors.green[600]),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help section coming soon!')),
                );
              },
            ),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined, color: Colors.purple[600]),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy policy coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getVitalColor(VitalType type) {
    switch (type) {
      case VitalType.heartRate:
      case VitalType.restingHeartRate:
        return Colors.red;
      case VitalType.bloodPressure:
        return Colors.purple;
      case VitalType.bloodOxygen:
        return Colors.blue;
      case VitalType.bloodGlucose:
        return Colors.orange;
      case VitalType.bodyTemperature:
        return Colors.amber;
      case VitalType.respiratoryRate:
        return Colors.teal;
      case VitalType.hrv:
        return Colors.indigo;
    }
  }
}
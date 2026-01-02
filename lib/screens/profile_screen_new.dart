import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../models/user_profile.dart';
import '../services/activity_repository.dart';
import '../services/google_auth_service.dart';
import '../services/step_tracking_service.dart' as steps_service;
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ActivityRepository _repository;
  late UserProfile _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      _repository = ref.read(steps_service.activityRepositoryProvider);
      await _repository.init();
      final profile = _repository.getUserProfile();
      _profile = profile;
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading profile: $e');
      }
      // Set default profile on error
      _profile = UserProfile.defaultProfile();
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
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
                    _buildSignInSection(),
                    const SizedBox(height: 24),
                    _buildUserInfoSection(),
                    const SizedBox(height: 24),
                    _buildGoalsSection(),
                    const SizedBox(height: 24),
                    _buildSleepSection(),
                  ],
                ),
              ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in ProfileScreen build: $e');
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.indigo[400],
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
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSignInSection() {
    try {
      final currentUser = GoogleAuthService().getCurrentUser();
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (currentUser != null)
                Column(
                  children: [
                    Text(
                      'Signed in as',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentUser.email ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        try {
                          await GoogleAuthService().signOut();
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Signed out successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print('Sign-out error: $e');
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Sign-out failed: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    if (!kIsWeb && Platform.isAndroid)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                        onPressed: () async {
                          try {
                            final user =
                                await GoogleAuthService().signInWithGoogle();
                            if (user != null && mounted) {
                              _profile.name = user.displayName ?? _profile.name;
                              _profile.email = user.email ?? '';
                              _profile.photoUrl = user.photoURL ?? '';
                              await _repository.saveUserProfile(_profile);
                              setState(() {});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Signed in as ${user.email}'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print('Sign-in error in UI: $e');
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Sign-in failed: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Google Sign-In is available on Android app only',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in sign in section: $e');
      }
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Sign in error: ${e.toString()}'),
        ),
      );
    }
  }

  Widget _buildUserInfoSection() {
    try {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.indigo[100],
                child: Text(
                  _profile.name.isNotEmpty
                      ? _profile.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildEditableField('Name', _profile.name, (value) async {
                _profile.name = value;
                await _repository.saveUserProfile(_profile);
                if (!mounted) return;
                setState(() {});
              }),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gender'),
                subtitle: Text(_profile.gender),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showGenderPicker(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date of Birth'),
                subtitle: Text(DateFormat('MMM d, yyyy').format(_profile.dob)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editDateOfBirth(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Height'),
                subtitle: Text('${_profile.heightCm.toStringAsFixed(1)} ft'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHeightPicker(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Weight'),
                subtitle: Text('${_profile.weightKg.toInt()} kg'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWeightPicker(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in user info section: $e');
      }
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('User info error: ${e.toString()}'),
        ),
      );
    }
  }

  Widget _buildGoalsSection() {
    try {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_walk, color: Colors.green),
                title: const Text('Daily steps goal'),
                subtitle: Text('${_profile.dailyStepGoal} steps'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editStepGoal(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Weekly heart points goal'),
                subtitle: Text('${_profile.weeklyHeartGoal} points'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editHeartGoal(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in goals section: $e');
      }
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Goals error: ${e.toString()}'),
        ),
      );
    }
  }

  Widget _buildSleepSection() {
    try {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sleep Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bedtime, color: Colors.purple),
                title: const Text('Bedtime'),
                subtitle: Text(_profile.bedtime.format(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editBedtime(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                title: const Text('Wake up time'),
                subtitle: Text(_profile.wakeUp.format(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editWakeUpTime(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in sleep section: $e');
      }
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Sleep error: ${e.toString()}'),
        ),
      );
    }
  }

  Widget _buildEditableField(
      String label, String value, Function(String) onSave) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _editTextField(label, value, onSave),
    );
  }

  void _editTextField(
      String label, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _profile.dob,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _profile.dob = date;
      await _repository.saveUserProfile(_profile);
      if (!mounted) return;
      setState(() {});
    }
  }

  void _editStepGoal() {
    final controller =
        TextEditingController(text: _profile.dailyStepGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Steps Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Steps'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              _profile.dailyStepGoal =
                  int.tryParse(controller.text) ?? _profile.dailyStepGoal;
              await _repository.saveUserProfile(_profile);
              if (!mounted) return;
              setState(() {});
              nav.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editHeartGoal() {
    final controller =
        TextEditingController(text: _profile.weeklyHeartGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weekly Heart Points Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Heart Points'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              _profile.weeklyHeartGoal =
                  int.tryParse(controller.text) ?? _profile.weeklyHeartGoal;
              await _repository.saveUserProfile(_profile);
              if (!mounted) return;
              setState(() {});
              nav.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBedtime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _profile.bedtime,
    );

    if (time != null) {
      _profile.bedtimeHour = time.hour;
      _profile.bedtimeMinute = time.minute;
      await _repository.saveUserProfile(_profile);
      if (!mounted) return;
      setState(() {});
    }
  }

  void _editWakeUpTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _profile.wakeUp,
    );

    if (time != null) {
      _profile.wakeUpHour = time.hour;
      _profile.wakeUpMinute = time.minute;
      await _repository.saveUserProfile(_profile);
      if (!mounted) return;
      setState(() {});
    }
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        String selected = _profile.gender;
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select Gender',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile(
                  title: const Text('Male'),
                  value: 'Male',
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                ),
                RadioListTile(
                  title: const Text('Female'),
                  value: 'Female',
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                ),
                RadioListTile(
                  title: const Text('Other'),
                  value: 'Other',
                  groupValue: selected,
                  onChanged: (v) => setState(() => selected = v!),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    _profile.gender = selected;
                    await _repository.saveUserProfile(_profile);
                    if (!mounted) return;
                    setState(() {});
                    nav.pop();
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  void _showHeightPicker() {
    final values = List.generate(91, (i) => 1.1 + (i * 0.1));
    int initialIndex = 0;
    try {
      initialIndex = values.indexWhere(
        (v) => (v - _profile.heightCm).abs() < 0.05,
      );
      if (initialIndex < 0) initialIndex = 0;
    } catch (_) {
      initialIndex = 0;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        double selected = _profile.heightCm;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Height (ft)', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController:
                    FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (index) {
                  selected = values[index];
                },
                children: values
                    .map((v) => Center(child: Text(v.toStringAsFixed(1))))
                    .toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                _profile.heightCm = selected;
                await _repository.saveUserProfile(_profile);
                if (!mounted) return;
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showWeightPicker() {
    final values = List.generate(150, (i) => i + 1);
    int initialIndex = (_profile.weightKg.toInt() - 1).clamp(0, 149);

    showModalBottomSheet(
      context: context,
      builder: (_) {
        int selected = _profile.weightKg.toInt();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Weight (kg)', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController:
                    FixedExtentScrollController(initialItem: initialIndex),
                onSelectedItemChanged: (index) {
                  selected = values[index];
                },
                children:
                    values.map((v) => Center(child: Text('$v kg'))).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                _profile.weightKg = selected.toDouble();
                await _repository.saveUserProfile(_profile);
                if (!mounted) return;
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

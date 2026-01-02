import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class StepCounterWithErrorHandling extends StatefulWidget {
  const StepCounterWithErrorHandling({super.key});

  @override
  _StepCounterWithErrorHandlingState createState() => _StepCounterWithErrorHandlingState();
}

class _StepCounterWithErrorHandlingState extends State<StepCounterWithErrorHandling> {
  int _steps = 0;
  StreamSubscription<StepCount>? _stepCountStream;
  
  // Status tracking variables
  bool _isPermissionGranted = false;
  bool _isSensorAvailable = true;
  String _errorMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStepCounter();
  }

  // Initialize step counter with proper error handling
  Future<void> _initializeStepCounter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Check if step counter sensor is available
      await _checkSensorAvailability();
      
      if (_isSensorAvailable) {
        // Request permission
        await _requestPermission();
        
        if (_isPermissionGranted) {
          // Start listening to step count
          _startListening();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize step counter: $e';
        _isSensorAvailable = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if step counter sensor is available on device
  Future<void> _checkSensorAvailability() async {
    try {
      // Try to access pedometer stream to check availability
      final testStream = Pedometer.stepCountStream.take(1);
      await testStream.first.timeout(const Duration(seconds: 3));
      
      setState(() {
        _isSensorAvailable = true;
      });
    } catch (e) {
      setState(() {
        _isSensorAvailable = false;
        _errorMessage = 'Step counter sensor not available on this device';
      });
    }
  }

  // Request activity recognition permission
  Future<void> _requestPermission() async {
    try {
      final status = await Permission.activityRecognition.request();
      
      setState(() {
        _isPermissionGranted = status.isGranted;
        
        if (status.isDenied) {
          _errorMessage = 'Permission denied. Please enable activity recognition in settings.';
        } else if (status.isPermanentlyDenied) {
          _errorMessage = 'Permission permanently denied. Please enable in device settings.';
        }
      });
    } catch (e) {
      setState(() {
        _isPermissionGranted = false;
        _errorMessage = 'Failed to request permission: $e';
      });
    }
  }

  // Start listening to step count stream
  void _startListening() {
    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start step counting: $e';
      });
    }
  }

  // Handle new step count data
  void _onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
      _errorMessage = ''; // Clear any previous errors
    });
  }

  // Handle step counter errors
  void _onStepCountError(error) {
    setState(() {
      _errorMessage = 'Step counter error: $error';
      _isSensorAvailable = false;
    });
  }

  // Open device settings for permission
  Future<void> _openSettings() async {
    await openAppSettings();
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
        title: const Text('Step Counter'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Initializing step counter...'),
            ]
            
            // Error state
            else if (_errorMessage.isNotEmpty) ...[
              _buildErrorCard(),
            ]
            
            // Success state - show step count
            else if (_isPermissionGranted && _isSensorAvailable) ...[
              _buildStepCountCard(),
            ]
            
            // Fallback state
            else ...[
              _buildUnavailableCard(),
            ],
          ],
        ),
      ),
    );
  }

  // Error card with user-friendly message
  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Step Counter Unavailable',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),
            
            // Action buttons based on error type
            if (_errorMessage.contains('Permission')) ...[
              ElevatedButton(
                onPressed: _openSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Settings'),
              ),
              const SizedBox(height: 10),
            ],
            
            ElevatedButton(
              onPressed: _initializeStepCounter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Step count display card
  Widget _buildStepCountCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.directions_walk,
              size: 64,
              color: Colors.green,
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
              '$_steps',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🎉 Step counter is working!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Unavailable state card
  Widget _buildUnavailableCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.sensors_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Step Counter Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your device may not have a step counter sensor, or the feature is not supported.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeStepCounter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}
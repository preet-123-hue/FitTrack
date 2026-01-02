import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class StepCounterApp extends StatelessWidget {
  const StepCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Counter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StepCounterScreen(),
    );
  }
}

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  _StepCounterScreenState createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  // Variable to store current step count
  int _steps = 0;

  // Stream subscription to listen for step updates from pedometer
  StreamSubscription<StepCount>? _stepCountStream;

  @override
  void initState() {
    super.initState();
    // Start step counting when screen loads
    _requestPermissionAndStartCounting();
  }

  // Request activity recognition permission and start step counting
  Future<void> _requestPermissionAndStartCounting() async {
    // Check if activity recognition permission is granted
    PermissionStatus permission =
        await Permission.activityRecognition.request();

    if (permission.isGranted) {
      // Permission granted - start listening to step count stream
      _startListening();
    } else {
      // Permission denied - show error message
      _showPermissionDeniedMessage();
    }
  }

  // Start listening to pedometer step count stream
  void _startListening() {
    // Subscribe to step count stream from pedometer plugin
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount, // Called when new step data arrives
      onError: _onError, // Called when error occurs
    );
  }

  // Handle new step count data from pedometer
  void _onStepCount(StepCount event) {
    // Update UI with new step count
    setState(() {
      _steps = event.steps; // Get total steps from device
    });
  }

  // Handle pedometer errors
  void _onError(error) {
    debugPrint('Pedometer Error: $error');
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error reading step count: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show message when permission is denied
  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permission denied. Cannot count steps.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _requestPermissionAndStartCounting,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel stream subscription to prevent memory leaks
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Step count display
            Text(
              'Steps Today',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Large step number
            Text(
              '$_steps',
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // Walking icon
            const Icon(
              Icons.directions_walk,
              size: 50,
              color: Colors.green,
            ),
            const SizedBox(height: 40),

            // Refresh button
            ElevatedButton(
              onPressed: _requestPermissionAndStartCounting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

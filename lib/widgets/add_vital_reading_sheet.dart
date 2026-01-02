import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vital_reading.dart';
import '../services/vitals_service.dart';
import 'package:intl/intl.dart';

// Bottom sheet for adding new vital readings
class AddVitalReadingSheet extends StatefulWidget {
  final VitalType vitalType;
  final VoidCallback? onSaved;

  const AddVitalReadingSheet({
    super.key,
    required this.vitalType,
    this.onSaved,
  });

  @override
  State<AddVitalReadingSheet> createState() => _AddVitalReadingSheetState();
}

class _AddVitalReadingSheetState extends State<AddVitalReadingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _secondaryValueController = TextEditingController();
  final _notesController = TextEditingController();
  final VitalsService _vitalsService = VitalsService();
  
  DateTime _selectedDateTime = DateTime.now();
  String? _measurementType; // For blood glucose
  String _temperatureUnit = 'celsius'; // For temperature
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default measurement type for blood glucose
    if (widget.vitalType == VitalType.bloodGlucose) {
      _measurementType = 'fasting';
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _secondaryValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.vitalType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add ${widget.vitalType.displayName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Value input
            _buildValueInput(),
            const SizedBox(height: 16),

            // Secondary value input (for blood pressure)
            if (widget.vitalType == VitalType.bloodPressure) ...[
              _buildSecondaryValueInput(),
              const SizedBox(height: 16),
            ],

            // Measurement type (for blood glucose)
            if (widget.vitalType == VitalType.bloodGlucose) ...[
              _buildMeasurementTypeSelector(),
              const SizedBox(height: 16),
            ],

            // Temperature unit (for body temperature)
            if (widget.vitalType == VitalType.bodyTemperature) ...[
              _buildTemperatureUnitSelector(),
              const SizedBox(height: 16),
            ],

            // Date and time picker
            _buildDateTimePicker(),
            const SizedBox(height: 16),

            // Notes input
            _buildNotesInput(),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getVitalColor(widget.vitalType),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Reading',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueInput() {
    return TextFormField(
      controller: _valueController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: _getValueLabel(),
        suffixText: widget.vitalType.unit,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        final numValue = double.tryParse(value);
        if (numValue == null) {
          return 'Please enter a valid number';
        }
        return _validateValueRange(numValue);
      },
    );
  }

  Widget _buildSecondaryValueInput() {
    return TextFormField(
      controller: _secondaryValueController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: 'Diastolic Pressure',
        suffixText: 'mmHg',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter diastolic pressure';
        }
        final numValue = double.tryParse(value);
        if (numValue == null) {
          return 'Please enter a valid number';
        }
        if (numValue < 40 || numValue > 120) {
          return 'Diastolic should be between 40-120 mmHg';
        }
        return null;
      },
    );
  }

  Widget _buildMeasurementTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Measurement Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Fasting'),
                value: 'fasting',
                groupValue: _measurementType,
                onChanged: (value) {
                  setState(() => _measurementType = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Post-meal'),
                value: 'post-meal',
                groupValue: _measurementType,
                onChanged: (value) {
                  setState(() => _measurementType = value);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemperatureUnitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temperature Unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Celsius (°C)'),
                value: 'celsius',
                groupValue: _temperatureUnit,
                onChanged: (value) {
                  setState(() => _temperatureUnit = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Fahrenheit (°F)'),
                value: 'fahrenheit',
                groupValue: _temperatureUnit,
                onChanged: (value) {
                  setState(() => _temperatureUnit = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return InkWell(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy • HH:mm').format(_selectedDateTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Add any additional notes...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  String _getValueLabel() {
    switch (widget.vitalType) {
      case VitalType.heartRate:
      case VitalType.restingHeartRate:
        return 'Heart Rate';
      case VitalType.bloodPressure:
        return 'Systolic Pressure';
      case VitalType.respiratoryRate:
        return 'Breaths per Minute';
      case VitalType.bloodOxygen:
        return 'Oxygen Saturation';
      case VitalType.bloodGlucose:
        return 'Blood Glucose Level';
      case VitalType.bodyTemperature:
        return 'Temperature';
      case VitalType.hrv:
        return 'HRV Value';
    }
  }

  String? _validateValueRange(double value) {
    switch (widget.vitalType) {
      case VitalType.heartRate:
      case VitalType.restingHeartRate:
        if (value < 30 || value > 220) {
          return 'Heart rate should be between 30-220 BPM';
        }
        break;
      case VitalType.bloodPressure:
        if (value < 70 || value > 200) {
          return 'Systolic should be between 70-200 mmHg';
        }
        break;
      case VitalType.respiratoryRate:
        if (value < 8 || value > 40) {
          return 'Respiratory rate should be between 8-40 breaths/min';
        }
        break;
      case VitalType.bloodOxygen:
        if (value < 70 || value > 100) {
          return 'Blood oxygen should be between 70-100%';
        }
        break;
      case VitalType.bloodGlucose:
        if (value < 50 || value > 400) {
          return 'Blood glucose should be between 50-400 mg/dL';
        }
        break;
      case VitalType.bodyTemperature:
        if (_temperatureUnit == 'celsius') {
          if (value < 30 || value > 45) {
            return 'Temperature should be between 30-45°C';
          }
        } else {
          if (value < 86 || value > 113) {
            return 'Temperature should be between 86-113°F';
          }
        }
        break;
      case VitalType.hrv:
        if (value < 10 || value > 200) {
          return 'HRV should be between 10-200 ms';
        }
        break;
    }
    return null;
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final reading = VitalReading(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: widget.vitalType,
        value: double.parse(_valueController.text),
        secondaryValue: widget.vitalType == VitalType.bloodPressure
            ? double.parse(_secondaryValueController.text)
            : null,
        timestamp: _selectedDateTime,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        measurementType: _measurementType,
        unit: widget.vitalType == VitalType.bodyTemperature ? _temperatureUnit : null,
      );

      await _vitalsService.saveReading(reading);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.vitalType.displayName} reading saved!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving reading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
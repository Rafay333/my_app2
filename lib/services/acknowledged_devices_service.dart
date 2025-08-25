import 'package:flutter/foundation.dart';

class AcknowledgedDevicesService {
  AcknowledgedDevicesService._internal();
  static final AcknowledgedDevicesService _instance =
      AcknowledgedDevicesService._internal();
  factory AcknowledgedDevicesService() => _instance;

  // 🔹 Devices acknowledged (Processing state)
  final ValueNotifier<List<Map<String, dynamic>>> acknowledgedDevices =
      ValueNotifier<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]);

  // 🔹 Devices that have been completed
  final ValueNotifier<List<Map<String, dynamic>>> completedDevices =
      ValueNotifier<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]);

  /// Add a device to acknowledged list
  void addAcknowledgedDevice(Map<String, dynamic> device) {
    final List<Map<String, dynamic>> current = List<Map<String, dynamic>>.from(
      acknowledgedDevices.value,
    );

    final String id = (device['deviceId'] ?? '').toString();
    if (id.isEmpty) return;

    // Remove if already exists
    current.removeWhere((d) => (d['deviceId'] ?? '').toString() == id);

    // Add with Processing state
    final Map<String, dynamic> deviceToAdd = Map<String, dynamic>.from(device);
    deviceToAdd['status'] = 'Processing';
    deviceToAdd['isinstalled'] = false;
    deviceToAdd['acknowledgedAt'] = DateTime.now().toIso8601String();

    current.add(deviceToAdd);
    acknowledgedDevices.value = current;
  }

  /// Add a completed installation
  void addCompletedDevice(Map<String, dynamic> device) {
    final List<Map<String, dynamic>> current = List<Map<String, dynamic>>.from(
      completedDevices.value,
    );

    final String id = (device['deviceId'] ?? '').toString();
    if (id.isEmpty) return;

    // Remove if already exists
    current.removeWhere((d) => (d['deviceId'] ?? '').toString() == id);

    // Add with Completed state
    final Map<String, dynamic> deviceToAdd = Map<String, dynamic>.from(device);
    deviceToAdd['status'] = 'Completed';
    deviceToAdd['isinstalled'] = true;
    deviceToAdd['completedAt'] = DateTime.now().toIso8601String();

    current.add(deviceToAdd);
    completedDevices.value = current;

    // Also remove from acknowledged if it exists there
    removeAcknowledgedById(id);
  }

  /// Remove device from acknowledged list
  void removeAcknowledgedById(String deviceId) {
    final current = List<Map<String, dynamic>>.from(acknowledgedDevices.value);
    current.removeWhere((d) => (d['deviceId'] ?? '').toString() == deviceId);
    acknowledgedDevices.value = current;
  }

  /// Remove device from completed list
  void removeCompletedById(String deviceId) {
    final current = List<Map<String, dynamic>>.from(completedDevices.value);
    current.removeWhere((d) => (d['deviceId'] ?? '').toString() == deviceId);
    completedDevices.value = current;
  }

  /// Update device status (works for both acknowledged & completed)
  void updateDeviceStatus(String deviceId, String status) {
    // First update in acknowledged list
    final acknowledged = List<Map<String, dynamic>>.from(
      acknowledgedDevices.value,
    );
    for (int i = 0; i < acknowledged.length; i++) {
      if ((acknowledged[i]['deviceId'] ?? '').toString() == deviceId) {
        acknowledged[i]['status'] = status;
        if (status == 'Completed') {
          acknowledged[i]['completedAt'] = DateTime.now().toIso8601String();
          // move to completedDevices
          addCompletedDevice(acknowledged[i]);
          acknowledged.removeAt(i);
        }
        break;
      }
    }
    acknowledgedDevices.value = acknowledged;

    // Also check if it's in completed list
    final completed = List<Map<String, dynamic>>.from(completedDevices.value);
    for (int i = 0; i < completed.length; i++) {
      if ((completed[i]['deviceId'] ?? '').toString() == deviceId) {
        completed[i]['status'] = status;
        break;
      }
    }
    completedDevices.value = completed;
  }

  /// Get acknowledged device by ID
  Map<String, dynamic>? getAcknowledgedDevice(String deviceId) {
    try {
      return acknowledgedDevices.value.firstWhere(
        (d) => (d['deviceId'] ?? '').toString() == deviceId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get completed device by ID
  Map<String, dynamic>? getCompletedDevice(String deviceId) {
    try {
      return completedDevices.value.firstWhere(
        (d) => (d['deviceId'] ?? '').toString() == deviceId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if device is acknowledged
  bool isDeviceAcknowledged(String deviceId) {
    return acknowledgedDevices.value.any(
      (d) => (d['deviceId'] ?? '').toString() == deviceId,
    );
  }

  /// Check if device is completed
  bool isDeviceCompleted(String deviceId) {
    return completedDevices.value.any(
      (d) => (d['deviceId'] ?? '').toString() == deviceId,
    );
  }

  /// Clear all acknowledged devices
  void clearAcknowledged() {
    acknowledgedDevices.value = <Map<String, dynamic>>[];
  }

  /// Clear all completed devices
  void clearCompleted() {
    completedDevices.value = <Map<String, dynamic>>[];
  }

  /// Get total counts
  int get acknowledgedCount => acknowledgedDevices.value.length;
  int get completedCount => completedDevices.value.length;

  void dispose() {
    acknowledgedDevices.dispose();
    completedDevices.dispose();
  }

  // Alias methods to match the expected method names in other parts of the code
  void addDevice(Map<String, dynamic> device) {
    addAcknowledgedDevice(device);
  }

  void removeByDeviceId(String deviceId) {
    removeAcknowledgedById(deviceId);
  }
}

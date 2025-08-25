class DeviceStatus {
  final double longitude;
  final double latitude;
  final String deviceId;
  final DateTime gpsSent;
  final double speed;
  final bool gpsAvailable;
  final String userName;
  final String phoneNumber;

  DeviceStatus({
    required this.longitude,
    required this.latitude,
    required this.deviceId,
    required this.gpsSent,
    required this.speed,
    required this.gpsAvailable,
    required this.userName,
    required this.phoneNumber,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      deviceId: json['deviceId'] ?? '',
      gpsSent: json['gpsSent'] != null 
          ? DateTime.parse(json['gpsSent'].toString())
          : DateTime.now(),
      speed: (json['speed'] ?? 0.0).toDouble(),
      gpsAvailable: json['gpsAvailable'] ?? false,
      userName: json['userName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
      'deviceId': deviceId,
      'gpsSent': gpsSent.toIso8601String(),
      'speed': speed,
      'gpsAvailable': gpsAvailable,
      'userName': userName,
      'phoneNumber': phoneNumber,
    };
  }

  bool get isConnected => gpsAvailable && gpsSent.isAfter(DateTime.now().subtract(Duration(hours: 1)));
  
  String get connectionStatus {
    if (!gpsAvailable) return 'Offline';
    if (isConnected) return 'Connected';
    return 'Last seen ${_formatLastSeen()}';
  }

  String _formatLastSeen() {
    final now = DateTime.now();
    final difference = now.difference(gpsSent);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Generate Google Maps URL for the device location
  String get googleMapsUrl {
    return 'https://www.google.com/maps?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
  }
}

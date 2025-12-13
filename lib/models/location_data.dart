class LocationData {
  final double latitude;
  final double longitude;
  final String? barangay;
  final String? station;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.barangay,
    this.station,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'barangay': barangay,
      'station': station,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      barangay: json['barangay'] as String?,
      station: json['station'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, barangay: $barangay)';
  }
}
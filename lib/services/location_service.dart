import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_data.dart';
import '../models/prediction_result.dart';
import 'api_service.dart';
import 'notification_service.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  LocationData? _currentLocationData;
  PredictionResult? _currentPrediction;
  bool _isTracking = false;
  bool _isLoading = false;
  String? _error;
  
  // Map of barangay names to approximate coordinates (simplified for demo)
  // In production, use proper geocoding service
  final Map<String, Map<String, dynamic>> _barangayCoordinates = {
    'poblacion': {'lat': 16.0434, 'lng': 120.3328, 'station': 'dagupan'},
    'lucao': {'lat': 16.0468, 'lng': 120.3406, 'station': 'dagupan'},
    'pantal': {'lat': 16.0510, 'lng': 120.3442, 'station': 'dagupan'},
    // Add more barangays as needed
  };

  // Getters
  Position? get currentPosition => _currentPosition;
  LocationData? get currentLocationData => _currentLocationData;
  PredictionResult? get currentPrediction => _currentPrediction;
  bool get isTracking => _isTracking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Request location permissions
  Future<bool> requestPermissions() async {
    try {
      // Request location permission
      final locationStatus = await Permission.location.request();
      
      if (locationStatus.isGranted) {
        // Request background location for Android 10+
        if (await Permission.locationAlways.isDenied) {
          await Permission.locationAlways.request();
        }
        
        // Request notification permission for Android 13+
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
        
        return true;
      } else if (locationStatus.isPermanentlyDenied) {
        _error = 'Location permission permanently denied. Please enable in settings.';
        notifyListeners();
        await openAppSettings();
        return false;
      } else {
        _error = 'Location permission denied';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error requesting permissions: $e';
      notifyListeners();
      return false;
    }
  }

  // Check if location services are enabled
  Future<bool> checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled. Please enable GPS.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (!await checkLocationService()) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      if (!await requestPermissions()) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _updateLocationData();
      
      _isLoading = false;
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _error = 'Error getting location: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Start continuous tracking
  Future<void> startTracking(ApiService apiService, NotificationService notificationService) async {
    if (_isTracking) return;

    if (!await checkLocationService() || !await requestPermissions()) {
      return;
    }

    _isTracking = true;
    _error = null;
    notifyListeners();

    // Configure location settings for continuous tracking
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
    );

    try {
      Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) async {
          _currentPosition = position;
          await _updateLocationData();
          
          // Check if location is accident-prone
          if (_currentLocationData?.barangay != null) {
            await _checkAndNotify(
              apiService,
              notificationService,
              _currentLocationData!.barangay!,
              _currentLocationData!.station ?? 'unknown',
            );
          }
          
          notifyListeners();
        },
        onError: (error) {
          _error = 'Tracking error: $error';
          _isTracking = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Error starting tracking: $e';
      _isTracking = false;
      notifyListeners();
    }
  }

  // Stop tracking
  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  // Update location data based on current position
  Future<void> _updateLocationData() async {
    if (_currentPosition == null) return;

    // Find nearest barangay (simplified - in production use proper geocoding)
    String? nearestBarangay;
    String? nearestStation;
    double minDistance = double.infinity;

    for (var entry in _barangayCoordinates.entries) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        entry.value['lat'],
        entry.value['lng'],
      );

      if (distance < minDistance && distance < 1000) { // Within 1km
        minDistance = distance;
        nearestBarangay = entry.key;
        nearestStation = entry.value['station'];
      }
    }

    _currentLocationData = LocationData(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      barangay: nearestBarangay,
      station: nearestStation,
    );
  }

  // Check location and send notification if accident-prone
  Future<void> _checkAndNotify(
    ApiService apiService,
    NotificationService notificationService,
    String barangay,
    String station,
  ) async {
    try {
      // Only check if it's a new barangay
      if (_currentPrediction?.barangay == barangay) {
        return;
      }

      final prediction = await apiService.checkLocation(barangay, station);
      
      if (prediction != null) {
        _currentPrediction = prediction;
        
        // Send notification if accident-prone
        if (prediction.isAccidentProne) {
          await notificationService.showAccidentAlert(
            barangay: prediction.barangay,
            message: prediction.message,
            riskLevel: prediction.riskLevel,
          );
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Error checking location: $e');
    }
  }

  // Manual check for a specific barangay
  Future<PredictionResult?> checkBarangay(
    ApiService apiService,
    String barangay,
    String station,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final prediction = await apiService.checkLocation(barangay, station);
      
      if (prediction != null) {
        _currentPrediction = prediction;
      } else {
        _error = 'Could not check location. Please try again.';
      }
      
      _isLoading = false;
      notifyListeners();
      return prediction;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset all data
  void reset() {
    _currentPosition = null;
    _currentLocationData = null;
    _currentPrediction = null;
    _isTracking = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
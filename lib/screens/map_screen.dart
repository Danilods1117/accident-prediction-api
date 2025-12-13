import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<Map<String, dynamic>> _accidentProneBarangays = [];
  bool _isLoading = true;

  // Default center: Pangasinan, Philippines
  static const LatLng _center = LatLng(16.0434, 120.3328);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccidentProneAreas();
    });
  }

  Future<void> _loadAccidentProneAreas() async {
    if (!mounted) return;

    final apiService = context.read<ApiService>();

    try {
      final barangays = await apiService.getBarangayList(accidentProneOnly: true);

      if (!mounted) return;

      setState(() {
        _accidentProneBarangays = barangays;
        _isLoading = false;
      });

      // Create markers for accident-prone areas
      _createMarkers();

      print('✅ Loaded ${barangays.length} accident-prone areas');
    } catch (e) {
      print('❌ Error loading accident-prone areas: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load accident-prone areas: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadAccidentProneAreas,
          ),
        ),
      );
    }
  }

  void _createMarkers() {
    // Clear existing markers and circles
    _markers.clear();
    _circles.clear();

    // Sample coordinates for demonstration
    // In production, fetch actual coordinates from a geocoding service
    final sampleCoordinates = {
      'poblacion': LatLng(16.0434, 120.3328),
      'lucao': LatLng(16.0468, 120.3406),
      'pantal': LatLng(16.0510, 120.3442),
      'san vicente': LatLng(16.0380, 120.3280),
      'carmen east': LatLng(16.0500, 120.3350),
      'malued': LatLng(16.0390, 120.3310),
      'lasip': LatLng(16.0520, 120.3400),
      'bonuan': LatLng(16.0600, 120.3450),
    };

    for (var barangay in _accidentProneBarangays) {
      final name = (barangay['name'] as String).toLowerCase();
      final coords = sampleCoordinates[name] ?? _center;

      _markers.add(
        Marker(
          markerId: MarkerId(name),
          position: coords,
          infoWindow: InfoWindow(
            title: barangay['name'],
            snippet: 'Accidents: ${barangay['total_accidents']} | Fatal: ${barangay['fatal_accidents']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Add danger zone circle
      _circles.add(
        Circle(
          circleId: CircleId(name),
          center: coords,
          radius: 500, // 500 meters radius
          fillColor: Colors.red.withOpacity(0.2),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
    }

    // Trigger rebuild to show markers
    if (mounted) {
      setState(() {});
    }

    print('✅ Created ${_markers.length} markers and ${_circles.length} circles');
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _centerOnCurrentLocation();
  }

  Future<void> _centerOnCurrentLocation() async {
    final locationService = context.read<LocationService>();
    
    if (locationService.currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            locationService.currentPosition!.latitude,
            locationService.currentPosition!.longitude,
          ),
          14.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accident-Prone Areas Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnCurrentLocation,
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccidentProneAreas,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: _center,
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: false,
                ),
                
                // Legend
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Legend',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Accident-Prone Zone'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Statistics Card
                Positioned(
                  top: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Statistics',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_accidentProneBarangays.length} High-Risk Areas',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Example API Service showing how to use the ApiConfig
///
/// This is a reference implementation. Adapt this to your existing API service.
class ApiServiceExample {
  /// Check if a location is accident-prone
  ///
  /// Example usage:
  /// ```dart
  /// final result = await ApiServiceExample.checkLocation(
  ///   barangay: 'Poblacion',
  ///   station: 'Dagupan',
  /// );
  /// ```
  static Future<Map<String, dynamic>> checkLocation({
    required String barangay,
    required String station,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.checkLocation),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barangay': barangay,
          'station': station,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking location: $e');
    }
  }

  /// Get list of municipalities
  static Future<List<String>> getMunicipalities() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.municipalities),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['municipalities'] ?? []);
      } else {
        throw Exception('Failed to get municipalities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting municipalities: $e');
    }
  }

  /// Get barangays for a specific municipality
  static Future<List<String>> getBarangays(String municipality) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getBarangaysByMunicipality(municipality)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['barangays'] ?? []);
      } else {
        throw Exception('Failed to get barangays: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting barangays: $e');
    }
  }

  /// Get safety tips based on risk level
  static Future<List<String>> getSafetyTips({String riskLevel = 'HIGH'}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getSafetyTipsByRiskLevel(riskLevel)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['tips'] ?? []);
      } else {
        throw Exception('Failed to get safety tips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting safety tips: $e');
    }
  }

  /// Get alternative routes
  static Future<Map<String, dynamic>> getAlternativeRoutes({
    required String currentBarangay,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.alternativeRoutes),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_barangay': currentBarangay,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get alternative routes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting alternative routes: $e');
    }
  }

  /// Get overall statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.statistics),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting statistics: $e');
    }
  }

  /// Health check - verify API is accessible
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.health),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Get list of all barangays with their risk status
  static Future<List<Map<String, dynamic>>> getAllBarangays({
    bool accidentProneOnly = false,
  }) async {
    try {
      final url = accidentProneOnly
          ? ApiConfig.getAccidentProneBarangays()
          : ApiConfig.barangayList;

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['barangays'] ?? []);
      } else {
        throw Exception('Failed to get barangay list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting barangay list: $e');
    }
  }
}

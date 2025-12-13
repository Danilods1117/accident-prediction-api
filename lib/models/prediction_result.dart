// Import this at the top of the file if needed
import 'package:flutter/material.dart';

class PredictionResult {
  final String barangay;
  final String station;
  final bool isAccidentProne;
  final int accidentCount;
  final int fatalAccidents;
  final String riskLevel;
  final double confidence;
  final String message;
  final String? commonOffense;
  final DateTime timestamp;

  PredictionResult({
    required this.barangay,
    required this.station,
    required this.isAccidentProne,
    required this.accidentCount,
    this.fatalAccidents = 0,
    required this.riskLevel,
    required this.confidence,
    required this.message,
    this.commonOffense,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      barangay: json['barangay'] as String? ?? 'Unknown',
      station: json['station'] as String? ?? 'Unknown',
      isAccidentProne: json['is_accident_prone'] as bool? ?? false,
      accidentCount: json['accident_count'] as int? ?? 0,
      fatalAccidents: json['fatal_accidents'] as int? ?? 0,
      riskLevel: json['risk_level'] as String? ?? 'UNKNOWN',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? 'No data available',
      commonOffense: json['common_offense'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barangay': barangay,
      'station': station,
      'is_accident_prone': isAccidentProne,
      'accident_count': accidentCount,
      'fatal_accidents': fatalAccidents,
      'risk_level': riskLevel,
      'confidence': confidence,
      'message': message,
      'common_offense': commonOffense,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Helper method to get risk color
  Color getRiskColor() {
    switch (riskLevel) {
      case 'CRITICAL':
        return const Color(0xFFD32F2F); // Dark red
      case 'HIGH':
        return const Color(0xFFFF5722); // Red-orange
      case 'MEDIUM':
        return const Color(0xFFFF9800); // Orange
      case 'LOW':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // Helper method to get risk icon
  String getRiskIcon() {
    switch (riskLevel) {
      case 'CRITICAL':
        return '🚨';
      case 'HIGH':
        return '⚠️';
      case 'MEDIUM':
        return '⚡';
      case 'LOW':
        return '✓';
      default:
        return '❓';
    }
  }

  @override
  String toString() {
    return 'PredictionResult(barangay: $barangay, isAccidentProne: $isAccidentProne, riskLevel: $riskLevel)';
  }
}


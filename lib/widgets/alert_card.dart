import 'package:flutter/material.dart';
import '../models/prediction_result.dart';

class AlertCard extends StatelessWidget {
  final PredictionResult prediction;

  const AlertCard({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: prediction.isAccidentProne
          ? prediction.getRiskColor().withOpacity(0.1)
          : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: prediction.isAccidentProne
              ? prediction.getRiskColor()
              : Colors.green,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: prediction.getRiskColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    prediction.getRiskIcon(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.barangay.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (prediction.station.isNotEmpty &&
                          prediction.station.toLowerCase() != 'unknown')
                        Text(
                          prediction.station.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: prediction.getRiskColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    prediction.riskLevel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: prediction.isAccidentProne
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: prediction.isAccidentProne
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Text(
                prediction.message,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: prediction.isAccidentProne
                      ? Colors.red.shade900
                      : Colors.green.shade900,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Total Accidents',
                    value: '${prediction.accidentCount}',
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Fatal',
                    value: '${prediction.fatalAccidents}',
                    icon: Icons.dangerous,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            if (prediction.commonOffense != null &&
                prediction.commonOffense!.isNotEmpty &&
                prediction.commonOffense!.toLowerCase() != 'unknown') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Most Common Offense',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prediction.commonOffense!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Confidence indicator
            Row(
              children: [
                const Text(
                  'Confidence: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: prediction.confidence,
                    backgroundColor: Colors.grey.shade200,
                    color: prediction.getRiskColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
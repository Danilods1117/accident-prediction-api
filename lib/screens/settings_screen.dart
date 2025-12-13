import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  Future<void> _loadStatistics() async {
    final apiService = context.read<ApiService>();
    final stats = await apiService.getStatistics();
    setState(() {
      _statistics = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _testNotification() async {
    final notificationService = context.read<NotificationService>();
    await notificationService.showAccidentAlert(
      barangay: 'Test Barangay',
      message: 'This is a test notification',
      riskLevel: 'HIGH',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _checkApiConnection() async {
    final apiService = context.read<ApiService>();
    final isHealthy = await apiService.healthCheck();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHealthy
                ? 'API connection successful!'
                : 'Cannot connect to API server',
          ),
          backgroundColor: isHealthy ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<LocationService>().reset();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Information'),
      ),
      body: ListView(
        children: [
          // App Information Section
          const ListTile(
            title: Text(
              'App Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accident Alert Pangasinan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0'),
                  const SizedBox(height: 16),
                  const Text(
                    'An AI-powered mobile application that predicts accident-prone areas using historical road accident data.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // Model Statistics
          const ListTile(
            title: Text(
              'Model Statistics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          if (_isLoadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_statistics != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Model Accuracy',
                      value: '${(_statistics!['model_accuracy'] * 100).toStringAsFixed(1)}%',
                      icon: Icons.check_circle,
                    ),
                    const Divider(),
                    _StatRow(
                      label: 'Training Samples',
                      value: '${_statistics!['training_samples']}',
                      icon: Icons.dataset,
                    ),
                    const Divider(),
                    _StatRow(
                      label: 'Total Places',
                      value: '${_statistics!['total_places']}',
                      icon: Icons.location_city,
                    ),
                    const Divider(),
                    _StatRow(
                      label: 'Accident-Prone Areas',
                      value: '${_statistics!['accident_prone_count']}',
                      icon: Icons.warning,
                      valueColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),

          // Actions Section
          const ListTile(
            title: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Test Notification'),
            subtitle: const Text('Send a test alert notification'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _testNotification,
          ),

          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Check API Connection'),
            subtitle: const Text('Verify connection to prediction server'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _checkApiConnection,
          ),

          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Statistics'),
            subtitle: const Text('Reload model statistics'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _isLoadingStats = true;
              });
              _loadStatistics();
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Clear Cached Data'),
            subtitle: const Text('Remove all stored location data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearData,
          ),

          const Divider(),

          // About Section
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This application uses machine learning to identify accident-prone areas in Pangasinan based on historical data. '
              'Always drive carefully and follow traffic rules.',
              style: TextStyle(height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '© 2024 Accident Alert Pangasinan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class HardwareScreen extends StatefulWidget {
  const HardwareScreen({super.key});

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  final String _hardwareId = "esp32_dispenser_01";
  bool _isScanning = false;

  void _startScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isScanning = false);
        _snack('Scan complete. ArogyaSathi Dispenser is already paired.');
      }
    });
  }

  void _triggerInstantDispense() async {
    HapticFeedback.heavyImpact();
    try {
      await FirebaseFirestore.instance.collection('hardware_control').doc(_hardwareId).set({
        'force_dispense': true,
        'dispense_medicine': 'Manual Test Pill',
        'dispense_slot': 1,
        'action_time': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _snack('Instant dispense command sent to hardware! ⚙️');
    } catch (e) {
      _snack('Failed to send command: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.danger : AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connected Hardware'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(kRadius),
                boxShadow: AppColors.floatShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bluetooth_connected, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bluetooth Active', 
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('2 devices paired and ready', 
                          style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            const SectionHeader(
              title: 'My Devices',
            ),
            
            // Live Firebase Data Stream for Hardware
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('hardware_control').doc(_hardwareId).snapshots(),
              builder: (context, snapshot) {
                String devStatus = 'Connecting...';
                bool isActive = false;
                String lastHeartbeat = 'Unknown';
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  devStatus = data['status'] ?? 'Unknown';
                  lastHeartbeat = data['last_heartbeat'] ?? '';
                  isActive = devStatus.toLowerCase() == 'online';
                }

                return Column(
                  children: [
                    _buildDeviceCard(
                      name: 'Arogya Smart Pillbox',
                      status: isActive ? 'Online ($lastHeartbeat)' : devStatus,
                      battery: 100, // Tied to mains power
                      icon: Icons.medication_liquid_outlined,
                      isActive: isActive,
                    ),
                    const SizedBox(height: 16),
                    if (isActive) 
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _triggerInstantDispense,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16)
                          ),
                          icon: const Icon(Icons.bolt),
                          label: Text('Instant Dispense (Test Slot 1)', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                );
              }
            ),
            
            const SizedBox(height: 24),
            
            const SectionHeader(
              title: 'Available Devices',
            ),
            const SizedBox(height: 16),

            // Add New Device Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                    : const Icon(Icons.add, color: AppColors.teal),
                label: Text(_isScanning ? 'Scanning for devices...' : 'Pair New Device',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required String name,
    required String status,
    required int battery,
    required IconData icon,
    required bool isActive,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.tealPale : AppColors.surface,
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            child: Icon(icon, color: isActive ? AppColors.teal : AppColors.textMuted, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, 
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(status, 
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                battery > 20 ? Icons.battery_full : Icons.battery_alert,
                color: battery > 20 ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text('$battery%', 
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}


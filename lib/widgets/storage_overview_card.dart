import 'package:flutter/material.dart';
import '../services/system_storage_service.dart';
import 'custom_donut_chart.dart';

class StorageOverviewCard extends StatelessWidget {
  final SystemStorageData data;

  const StorageOverviewCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final usedPct = ((data.usedGB / data.totalGB) * 100).toStringAsFixed(1);
    final freePct = ((data.freeGB / data.totalGB) * 100).toStringAsFixed(1);
    final usedProgress = (data.usedGB / data.totalGB).clamp(0.0, 1.0);
    final freeProgress = (data.freeGB / data.totalGB).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Drive Info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: Color(0xFF475569),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.driveName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${data.fileSystem} • ${data.totalGB} GB',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Center Row: Donut Chart & Used/Free Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut Chart
              CustomDonutChart(
                categories: const [],
                totalGB: data.totalGB,
                freeGB: data.freeGB,
              ),
              const SizedBox(width: 20),

              // Used & Free Progress Bars
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Used Stat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Used',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${data.usedGB} GB',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$usedPct%',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Used Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: usedProgress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Free Stat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Free',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${data.freeGB} GB',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$freePct%',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Free Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: freeProgress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Metric Boxes Row
          Row(
            children: [
              _buildMetricTile(
                icon: Icons.insert_drive_file_outlined,
                label: 'Total Files',
                value: '271.5K',
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.folder_open_rounded,
                label: 'Total Folders',
                value: '45.2K',
              ),
              const SizedBox(width: 8),
              _buildMetricTile(
                icon: Icons.access_time_rounded,
                label: 'Last Scan',
                value: '${data.scanDurationSec.toStringAsFixed(2)}s',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

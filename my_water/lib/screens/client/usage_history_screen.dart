import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/meter_provider.dart';
import '../../models/meter_reading_model.dart';

class UsageHistoryScreen extends StatefulWidget {
  final String userId;
  const UsageHistoryScreen({super.key, required this.userId});

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<MeterProvider>().loadReadings(widget.userId, year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(3, (i) => DateTime.now().year - i);

    return Column(
      children: [
        // Year filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Water Usage History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) {
                setState(() => _selectedYear = v!);
                _load();
              },
            ),
          ]),
        ),

        Expanded(
          child: Consumer<MeterProvider>(
            builder: (_, provider, __) {
              if (provider.loading) return const Center(child: CircularProgressIndicator());
              if (provider.error != null) return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
              if (provider.readings.isEmpty) {
                return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.speed_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No usage data available', style: TextStyle(color: AppColors.textSecondary)),
                ]));
              }

              // Sort by month ascending for chart
              final sorted = [...provider.readings]..sort((a, b) => a.month.compareTo(b.month));

              return RefreshIndicator(
                onRefresh: () async => _load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    // Bar chart
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 8)]),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (sorted.map((r) => r.unitsConsumed).reduce((a, b) => a > b ? a : b) * 1.3),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: AppColors.primary,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                                '${sorted[groupIndex].unitsConsumed.toStringAsFixed(0)} units',
                                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(AppConstants.monthName(sorted[idx].month).substring(0, 3),
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1),
                            drawVerticalLine: false,
                          ),
                          barGroups: sorted.asMap().entries.map((entry) {
                            return BarChartGroupData(x: entry.key, barRods: [
                              BarChartRodData(
                                toY: entry.value.unitsConsumed,
                                gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary],
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter),
                                width: 18,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List of readings
                    ...provider.readings.map((r) => _ReadingCard(reading: r)),
                    const SizedBox(height: 16),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final MeterReadingModel reading;
  const _ReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
        ),
        title: Text('${AppConstants.monthName(reading.month)} ${reading.year}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Reading: ${reading.reading.toStringAsFixed(0)} | Prev: ${reading.previousReading.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${reading.unitsConsumed.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const Text('units', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ]),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../l10n/app_localizations.dart';
import 'parcel_form_screen.dart';
import 'truck_form_screen.dart';
import 'scanner_screen.dart';
import 'parcel_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final inTransitCount = store.parcels.where((p) => p.status == ParcelStatus.inTransit).length;
    final deliveredTodayCount = store.events.where((e) {
      final now = DateTime.now();
      return e.to == ParcelStatus.delivered &&
          e.timestamp.year == now.year &&
          e.timestamp.month == now.month &&
          e.timestamp.day == now.day;
    }).length;
    final trucksOnRouteCount = store.trucks.where((t) => t.status == TruckStatus.onRoute).length;
    final issuesCount = store.parcels.where((p) => p.status == ParcelStatus.failed || p.status == ParcelStatus.returned).length;

    return ResponsiveScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Glass App Bar / Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.settings.companyName.isNotEmpty
                            ? store.settings.companyName
                            : 'Rayo Tracking',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: RayoColors.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('tagline'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildQuickActionMenu(context),
                ],
              ),
            ),
          ),

          // Stat Cards Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLandscape ? 4 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isLandscape ? 1.4 : 1.35,
              ),
              delegate: SliverChildListDelegate([
                GlassStatCard(
                  title: context.tr('in_transit'),
                  value: '$inTransitCount',
                  icon: CupertinoIcons.bus,
                  color: RayoColors.primaryBlue,
                  onTap: () => onNavigateTab?.call(1),
                ),
                GlassStatCard(
                  title: context.tr('delivered_today'),
                  value: '$deliveredTodayCount',
                  icon: CupertinoIcons.checkmark_seal_fill,
                  color: RayoColors.successGreen,
                  onTap: () => onNavigateTab?.call(1),
                ),
                GlassStatCard(
                  title: context.tr('trucks_on_route'),
                  value: '$trucksOnRouteCount',
                  icon: CupertinoIcons.compass,
                  color: RayoColors.truckCyan,
                  onTap: () => onNavigateTab?.call(2),
                ),
                GlassStatCard(
                  title: context.tr('issues'),
                  value: '$issuesCount',
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                  color: RayoColors.dangerRed,
                  onTap: () => onNavigateTab?.call(1),
                ),
              ]),
            ),
          ),

          // Chart Section: 7-Day Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: GlassCard(
                cornerRadius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('last_7_days'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: RayoColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${store.parcels.length} total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: RayoColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 150,
                      child: _buildBarChart(store),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recent Activity Timeline Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('recent_activity'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (store.events.isNotEmpty)
                    Text(
                      '${store.events.length} logs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Recent Activity List
          if (store.events.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No tracking events recorded yet.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = store.events[index];
                    final parcel = store.parcels.firstWhere(
                      (p) => p.id == event.parcelID,
                      orElse: () => Parcel(id: '', code: 'Unknown'),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        cornerRadius: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        onTap: parcel.id.isNotEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => ParcelDetailScreen(parcelId: parcel.id),
                                  ),
                                );
                              }
                            : null,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: RayoColors.primaryBlue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.arrow_right_arrow_left_circle_fill,
                                color: RayoColors.primaryBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        parcel.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Courier',
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('HH:mm · MMM d').format(event.timestamp),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    event.note.isNotEmpty ? event.note : 'Status updated',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(status: event.to, fontSize: 10),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: store.events.take(6).length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Quick Actions',
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: RayoColors.primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: RayoColors.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) {
        if (value == 'new_parcel') {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const ParcelFormScreen()));
        } else if (value == 'new_truck') {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const TruckFormScreen()));
        } else if (value == 'scan') {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => const ScannerScreen()));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'new_parcel',
          child: Row(
            children: [
              const Icon(CupertinoIcons.cube_box, color: RayoColors.primaryBlue, size: 20),
              const SizedBox(width: 12),
              Text(context.tr('new_parcel')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'new_truck',
          child: Row(
            children: [
              const Icon(CupertinoIcons.bus, color: RayoColors.truckCyan, size: 20),
              const SizedBox(width: 12),
              Text(context.tr('new_truck')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'scan',
          child: Row(
            children: [
              const Icon(CupertinoIcons.barcode_viewfinder, color: RayoColors.successGreen, size: 20),
              const SizedBox(width: 12),
              Text(context.tr('scan_code')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(AppStore store) {
    final now = DateTime.now();
    final dailyCounts = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final count = store.parcels.where((p) {
        return p.createdAt.year == day.year &&
            p.createdAt.month == day.month &&
            p.createdAt.day == day.day;
      }).length;
      return MapEntry(day, count);
    });

    final maxCount = dailyCounts.map((e) => e.value).fold<int>(0, (prev, elem) => elem > prev ? elem : prev);
    final maxY = (maxCount < 5 ? 5 : maxCount + 2).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = dailyCounts[group.x.toInt()].key;
              return BarTooltipItem(
                '${DateFormat('E d').format(day)}\n${rod.toY.toInt()} parcels',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyCounts.length) return const SizedBox.shrink();
                final d = dailyCounts[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('E').format(d).substring(0, 1),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyCounts.length, (i) {
          final count = dailyCounts[i].value;
          final isToday = i == 6;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: isToday ? RayoColors.primaryBlue : RayoColors.primaryBlue.withValues(alpha: 0.45),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.grey.withValues(alpha: 0.08),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

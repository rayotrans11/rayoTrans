import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/services.dart';
import '../l10n/app_localizations.dart';
import 'truck_form_screen.dart';
import 'parcel_detail_screen.dart';

class TruckListScreen extends StatelessWidget {
  const TruckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return ResponsiveScaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('trucks'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const TruckFormScreen()),
                      );
                    },
                    icon: const Icon(CupertinoIcons.plus, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: RayoColors.truckCyan.withValues(alpha: 0.15),
                      foregroundColor: RayoColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trucks List
          if (store.trucks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.bus, size: 54, color: Colors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('no_trucks'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final truck = store.trucks[index];
                    final assignedParcels = store.parcelsForTruck(truck.id);
                    final ratio = store.loadRatioForTruck(truck);
                    final weight = store.currentTruckWeight(truck);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GlassCard(
                        cornerRadius: 22,
                        padding: const EdgeInsets.all(18),
                        onTap: () {
                          _showTruckDetailBottomSheet(context, store, truck);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Name, Plate, Status
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: RayoColors.truckCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(CupertinoIcons.bus, color: RayoColors.primaryBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        truck.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        truck.plate,
                                        style: const TextStyle(
                                          fontFamily: 'Courier',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TruckStatusPill(status: truck.status),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Driver Info
                            if (truck.driverName.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(CupertinoIcons.person_badge_plus_fill, size: 16, color: Colors.grey.withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    truck.driverName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  if (truck.driverPhone.isNotEmpty) ...[
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(CupertinoIcons.phone_fill, size: 16, color: RayoColors.successGreen),
                                      onPressed: () => launchUrl(Uri.parse('tel:${truck.driverPhone}')),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Load Percentage Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${assignedParcels.length} parcels · ${weight.toStringAsFixed(1)} / ${truck.capacityKg.toStringAsFixed(0)} kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                                Text(
                                  '${(ratio * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ratio > 0.9 ? RayoColors.dangerRed : RayoColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ratio > 0.9 ? RayoColors.dangerRed : RayoColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: store.trucks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTruckDetailBottomSheet(BuildContext context, AppStore store, Truck truck) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final assigned = store.parcelsForTruck(truck.id);

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return GlassCard(
              cornerRadius: 28,
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(truck.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Plate: ${truck.plate}', style: const TextStyle(fontFamily: 'Courier', fontSize: 14)),
                        ],
                      ),
                      TruckStatusPill(status: truck.status, fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions: Start Route / End Route & Daily Manifest
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: truck.status == TruckStatus.onRoute
                                ? RayoColors.warningOrange
                                : RayoColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            if (truck.status == TruckStatus.onRoute) {
                              store.endTruckRoute(truck.id);
                            } else {
                              store.startTruckRoute(truck.id);
                            }
                            Navigator.pop(ctx);
                          },
                          icon: Icon(
                            truck.status == TruckStatus.onRoute ? CupertinoIcons.stop_fill : CupertinoIcons.play_arrow_solid,
                            size: 16,
                          ),
                          label: Text(
                            truck.status == TruckStatus.onRoute ? context.tr('end_route') : context.tr('start_route'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: context.tr('daily_manifest'),
                        onPressed: () {
                          RayoServices.printTruckManifestPdf(truck, assigned);
                        },
                        icon: const Icon(CupertinoIcons.doc_text_fill),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Edit Truck',
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (_) => TruckFormScreen(truckToEdit: truck)),
                          );
                        },
                        icon: const Icon(CupertinoIcons.pencil),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Assigned Parcels Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Parcels (${assigned.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${store.currentTruckWeight(truck).toStringAsFixed(1)} kg',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (assigned.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No parcels assigned to this truck.')),
                    )
                  else
                    ...assigned.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          cornerRadius: 16,
                          padding: const EdgeInsets.all(12),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (_) => ParcelDetailScreen(parcelId: p.id)),
                            );
                          },
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.code, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('${p.recipient.name} · ${p.recipient.city}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              StatusPill(status: p.status, fontSize: 10),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

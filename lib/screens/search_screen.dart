import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../l10n/app_localizations.dart';
import 'parcel_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() {
      setState(() => _query = _queryController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    final matchedParcels = _query.isEmpty
        ? <Parcel>[]
        : store.parcels.where((p) {
            return p.code.toLowerCase().contains(_query) ||
                p.recipient.name.toLowerCase().contains(_query) ||
                p.recipient.city.toLowerCase().contains(_query) ||
                p.recipient.phone.toLowerCase().contains(_query) ||
                p.sender.name.toLowerCase().contains(_query) ||
                p.descriptionText.toLowerCase().contains(_query);
          }).toList();

    final matchedTrucks = _query.isEmpty
        ? <Truck>[]
        : store.trucks.where((t) {
            return t.name.toLowerCase().contains(_query) ||
                t.plate.toLowerCase().contains(_query) ||
                t.driverName.toLowerCase().contains(_query) ||
                t.driverPhone.toLowerCase().contains(_query);
          }).toList();

    return ResponsiveScaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                context.tr('search'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: GlassTextField(
                controller: _queryController,
                label: context.tr('search_hint'),
                prefixIcon: CupertinoIcons.search,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                        onPressed: () => _queryController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          if (_query.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.search_circle, size: 54, color: Colors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Type above to search parcels and trucks',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (matchedParcels.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  child: Text(
                    'Parcels (${matchedParcels.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = matchedParcels[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          cornerRadius: 16,
                          padding: const EdgeInsets.all(14),
                          onTap: () {
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
                                  Text(p.code, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                                  Text('${p.recipient.name} · ${p.recipient.city}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              StatusPill(status: p.status, fontSize: 10),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: matchedParcels.length,
                  ),
                ),
              ),
            ],
            if (matchedTrucks.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  child: Text(
                    'Trucks (${matchedTrucks.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final t = matchedTrucks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          cornerRadius: 16,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.bus, color: RayoColors.truckCyan),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${t.plate} · ${t.driverName}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              TruckStatusPill(status: t.status, fontSize: 10),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: matchedTrucks.length,
                  ),
                ),
              ),
            ],
            if (matchedParcels.isEmpty && matchedTrucks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    context.tr('no_results'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

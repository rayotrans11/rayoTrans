import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../l10n/app_localizations.dart';
import 'parcel_detail_screen.dart';
import 'parcel_form_screen.dart';

class ParcelListScreen extends StatefulWidget {
  final ParcelStatus? initialFilter;

  const ParcelListScreen({super.key, this.initialFilter});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  ParcelStatus? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    final filtered = store.parcels.where((p) {
      if (_selectedFilter != null && p.status != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final codeMatches = p.code.toLowerCase().contains(_searchQuery);
        final recipientMatches = p.recipient.name.toLowerCase().contains(_searchQuery);
        final cityMatches = p.recipient.city.toLowerCase().contains(_searchQuery);
        final phoneMatches = p.recipient.phone.toLowerCase().contains(_searchQuery);
        if (!codeMatches && !recipientMatches && !cityMatches && !phoneMatches) {
          return false;
        }
      }
      return true;
    }).toList();

    return ResponsiveScaffold(
      body: CustomScrollView(
        slivers: [
          // Header & Add Action
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('parcels'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (_) => const ParcelFormScreen()),
                      );
                    },
                    icon: const Icon(CupertinoIcons.plus, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: RayoColors.primaryBlue.withValues(alpha: 0.15),
                      foregroundColor: RayoColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: GlassTextField(
                controller: _searchController,
                label: context.tr('search_hint'),
                prefixIcon: CupertinoIcons.search,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          // Horizontal Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _filterChip(context.tr('all'), null),
                  ...ParcelStatus.values.map((s) => _filterChip(context.tr(s.translationKey), s)),
                ],
              ),
            ),
          ),

          // Parcels List
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.cube_box, size: 54, color: Colors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('no_parcels'),
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
                    final parcel = filtered[index];
                    final truck = store.trucks.firstWhere(
                      (t) => t.id == parcel.truckID,
                      orElse: () => Truck(id: '', name: '', plate: ''),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(parcel.id),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Advance status
                            if (parcel.status.next != null) {
                              HapticFeedback.lightImpact();
                              store.setParcelStatus(parcel.id, parcel.status.next!);
                            }
                            return false; // Do not dismiss row
                          } else {
                            // Confirm delete
                            final confirm = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: Text(context.tr('delete')),
                                content: Text(context.tr('confirm_delete')),
                                actions: [
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(context.tr('cancel')),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(context.tr('delete')),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              HapticFeedback.mediumImpact();
                              store.deleteParcel(parcel.id);
                              return true;
                            }
                            return false;
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          decoration: BoxDecoration(
                            color: RayoColors.primaryBlue.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text('Advance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: RayoColors.dangerRed.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(CupertinoIcons.trash_fill, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                        child: GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => ParcelDetailScreen(parcelId: parcel.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    parcel.code,
                                    style: const TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (parcel.priority == Priority.urgent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: RayoColors.dangerRed.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'URGENT',
                                        style: TextStyle(
                                          color: RayoColors.dangerRed,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  StatusPill(status: parcel.status),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.person_alt_circle, size: 18, color: Colors.grey.withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${parcel.recipient.name} · ${parcel.recipient.city}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '${parcel.weightKg} kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (truck.plate.isNotEmpty) ...[
                                    const Text('  •  ', style: TextStyle(color: Colors.grey)),
                                    Icon(CupertinoIcons.bus, size: 14, color: RayoColors.primaryBlue.withValues(alpha: 0.8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      truck.plate,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  if (parcel.codAmount != null && parcel.codAmount! > 0) ...[
                                    const Spacer(),
                                    Text(
                                      '${parcel.codAmount} ${store.settings.currencySymbol}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: RayoColors.successGreen,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String title, ParcelStatus? status) {
    final isSelected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilter = status);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? RayoColors.primaryBlue
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? RayoColors.primaryBlue
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}

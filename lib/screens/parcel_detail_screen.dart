import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/services.dart';
import '../l10n/app_localizations.dart';
import 'parcel_form_screen.dart';

class ParcelDetailScreen extends StatelessWidget {
  final String parcelId;

  const ParcelDetailScreen({super.key, required this.parcelId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final parcel = store.parcels.firstWhere(
      (p) => p.id == parcelId,
      orElse: () => Parcel(id: '', code: 'Not Found'),
    );

    if (parcel.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parcel')),
        body: const Center(child: Text('Parcel not found')),
      );
    }

    final truck = store.trucks.firstWhere(
      (t) => t.id == parcel.truckID,
      orElse: () => Truck(id: '', name: 'Unassigned', plate: 'None'),
    );
    final timeline = store.timelineForParcel(parcel.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RayoBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(CupertinoIcons.printer_fill),
                      tooltip: context.tr('export_pdf'),
                      onPressed: () {
                        RayoServices.printParcelPdf(parcel, parcel.truckID != null ? truck : null);
                      },
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.pencil),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => ParcelFormScreen(parcelToEdit: parcel),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash, color: RayoColors.dangerRed),
                      onPressed: () => _confirmDelete(context, store, parcel.id),
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card with QR Code
                      GlassCard(
                        cornerRadius: 24,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        parcel.code,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Courier',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: parcel.code));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(context.tr('copied')), duration: const Duration(seconds: 1)),
                                          );
                                        },
                                        child: const Icon(CupertinoIcons.doc_on_doc, size: 16, color: RayoColors.primaryBlue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  StatusPill(status: parcel.status, fontSize: 13),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Created: ${DateFormat('yyyy-MM-dd HH:mm').format(parcel.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: QrImageView(
                                data: parcel.code,
                                version: QrVersions.auto,
                                size: 80.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fast Status Stepper Action Row
                      GlassCard(
                        cornerRadius: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (parcel.status.next != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: RayoColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    store.setParcelStatus(parcel.id, parcel.status.next!);
                                  },
                                  icon: const Icon(CupertinoIcons.arrow_right_circle, size: 18),
                                  label: Text(
                                    '${context.tr('advance')} (${context.tr(parcel.status.next!.translationKey)})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            PopupMenuButton<ParcelStatus>(
                              tooltip: 'Change Status Manually',
                              icon: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(CupertinoIcons.ellipsis, size: 20),
                              ),
                              onSelected: (newStatus) {
                                store.setParcelStatus(parcel.id, newStatus);
                              },
                              itemBuilder: (context) => ParcelStatus.values.map((s) {
                                return PopupMenuItem(
                                  value: s,
                                  child: Row(
                                    children: [
                                      StatusPill(status: s, fontSize: 10),
                                      const SizedBox(width: 8),
                                      Text(context.tr(s.translationKey)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recipient & Sender Cards
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _personCard(
                              context,
                              title: context.tr('recipient'),
                              person: parcel.recipient,
                              isRecipient: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _personCard(
                              context,
                              title: context.tr('sender'),
                              person: parcel.sender,
                              isRecipient: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Package Specs & Assigned Truck
                      GlassCard(
                        cornerRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shipment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 12),
                            _detailRow('Weight', '${parcel.weightKg} ${store.settings.weightUnit}'),
                            _detailRow('Priority', parcel.priority.name.toUpperCase()),
                            if (parcel.codAmount != null && parcel.codAmount! > 0)
                              _detailRow('COD Cash Due', '${parcel.codAmount} ${store.settings.currencySymbol}'),
                            if (parcel.descriptionText.isNotEmpty)
                              _detailRow('Description', parcel.descriptionText),
                            if (parcel.notes.isNotEmpty)
                              _detailRow('Notes', parcel.notes),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Assigned Truck', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      parcel.truckID != null ? '${truck.name} (${truck.plate})' : 'Not Assigned',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => _showAssignTruckDialog(context, store, parcel),
                                  child: Text(context.tr('assign_truck')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Timeline / History Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('timeline'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(CupertinoIcons.plus_bubble, size: 20, color: RayoColors.primaryBlue),
                            tooltip: 'Add Note Log',
                            onPressed: () => _showAddNoteDialog(context, store, parcel.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (timeline.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No tracking events for this parcel yet.'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: timeline.length,
                          itemBuilder: (context, index) {
                            final event = timeline[index];
                            final isFirst = index == 0;
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isFirst ? RayoColors.primaryBlue : Colors.grey.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      if (index < timeline.length - 1)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: Colors.grey.withValues(alpha: 0.3),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              StatusPill(status: event.to, fontSize: 10),
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
                                          const SizedBox(height: 4),
                                          Text(
                                            event.note.isNotEmpty ? event.note : 'Status changed',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                          if (event.operatorName.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'By: ${event.operatorName}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personCard(BuildContext context, {required String title, required Person person, required bool isRecipient}) {
    return GlassCard(
      cornerRadius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRecipient ? CupertinoIcons.arrow_down_left_circle_fill : CupertinoIcons.arrow_up_right_circle_fill,
                size: 16,
                color: isRecipient ? RayoColors.successGreen : RayoColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(person.name.isNotEmpty ? person.name : 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          if (person.phone.isNotEmpty)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${person.phone}')),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.phone, size: 12, color: RayoColors.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    person.phone,
                    style: const TextStyle(fontSize: 12, color: RayoColors.primaryBlue, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          if (person.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${person.city} · ${person.address}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppStore store, String parcelId) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(context.tr('delete')),
        content: Text(context.tr('confirm_delete')),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              store.deleteParcel(parcelId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _showAssignTruckDialog(BuildContext context, AppStore store, Parcel parcel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassCard(
          cornerRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('assign_truck'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('None (Unassign)'),
                trailing: parcel.truckID == null ? const Icon(CupertinoIcons.checkmark, color: RayoColors.primaryBlue) : null,
                onTap: () {
                  store.assignParcelToTruck(parcel.id, null);
                  Navigator.pop(ctx);
                },
              ),
              ...store.trucks.map((t) {
                final isCurrent = parcel.truckID == t.id;
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.plate} · ${t.driverName}'),
                  trailing: isCurrent ? const Icon(CupertinoIcons.checkmark, color: RayoColors.primaryBlue) : null,
                  onTap: () {
                    store.assignParcelToTruck(parcel.id, t.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, AppStore store, String parcelId) {
    final noteController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Add Timeline Note'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: noteController,
            placeholder: 'e.g. Recipient requested delivery tomorrow morning',
            maxLines: 3,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                final parcel = store.parcels.firstWhere((p) => p.id == parcelId);
                store.setParcelStatus(parcelId, parcel.status, note: noteController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }
}

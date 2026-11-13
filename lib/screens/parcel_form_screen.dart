import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../l10n/app_localizations.dart';
import 'scanner_screen.dart';

class ParcelFormScreen extends StatefulWidget {
  final Parcel? parcelToEdit;

  const ParcelFormScreen({super.key, this.parcelToEdit});

  @override
  State<ParcelFormScreen> createState() => _ParcelFormScreenState();
}

class _ParcelFormScreenState extends State<ParcelFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _senderNameController;
  late TextEditingController _senderPhoneController;
  late TextEditingController _senderAddressController;
  late TextEditingController _senderCityController;

  late TextEditingController _recipientNameController;
  late TextEditingController _recipientPhoneController;
  late TextEditingController _recipientAddressController;
  late TextEditingController _recipientCityController;

  late TextEditingController _weightController;
  late TextEditingController _codController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  Priority _priority = Priority.normal;
  ParcelStatus _status = ParcelStatus.registered;
  String? _selectedTruckId;

  @override
  void initState() {
    super.initState();
    final p = widget.parcelToEdit;

    _codeController = TextEditingController(text: p?.code ?? '');
    _senderNameController = TextEditingController(text: p?.sender.name ?? '');
    _senderPhoneController = TextEditingController(text: p?.sender.phone ?? '');
    _senderAddressController = TextEditingController(text: p?.sender.address ?? '');
    _senderCityController = TextEditingController(text: p?.sender.city ?? '');

    _recipientNameController = TextEditingController(text: p?.recipient.name ?? '');
    _recipientPhoneController = TextEditingController(text: p?.recipient.phone ?? '');
    _recipientAddressController = TextEditingController(text: p?.recipient.address ?? '');
    _recipientCityController = TextEditingController(text: p?.recipient.city ?? '');

    _weightController = TextEditingController(text: p != null && p.weightKg > 0 ? p.weightKg.toString() : '');
    _codController = TextEditingController(text: p?.codAmount != null ? p!.codAmount.toString() : '');
    _descriptionController = TextEditingController(text: p?.descriptionText ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    _priority = p?.priority ?? Priority.normal;
    _status = p?.status ?? ParcelStatus.registered;
    _selectedTruckId = p?.truckID;

    // Auto generate code if creating new
    if (widget.parcelToEdit == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final store = context.read<AppStore>();
        _codeController.text = store.nextCode();
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    _senderCityController.dispose();

    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _recipientAddressController.dispose();
    _recipientCityController.dispose();

    _weightController.dispose();
    _codController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<AppStore>();
    final isNew = widget.parcelToEdit == null;

    final newParcel = Parcel(
      id: widget.parcelToEdit?.id ?? const Uuid().v4(),
      code: _codeController.text.trim(),
      sender: Person(
        name: _senderNameController.text.trim(),
        phone: _senderPhoneController.text.trim(),
        address: _senderAddressController.text.trim(),
        city: _senderCityController.text.trim(),
      ),
      recipient: Person(
        name: _recipientNameController.text.trim(),
        phone: _recipientPhoneController.text.trim(),
        address: _recipientAddressController.text.trim(),
        city: _recipientCityController.text.trim(),
      ),
      weightKg: double.tryParse(_weightController.text.trim()) ?? 0.0,
      codAmount: double.tryParse(_codController.text.trim()),
      descriptionText: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
      priority: _priority,
      status: _status,
      truckID: _selectedTruckId,
      createdAt: widget.parcelToEdit?.createdAt,
    );

    if (isNew) {
      store.addParcel(newParcel);
    } else {
      store.updateParcel(newParcel);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isEditing = widget.parcelToEdit != null;

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
                    Text(
                      isEditing ? 'Edit Parcel' : context.tr('new_parcel'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RayoColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _save,
                      child: Text(context.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Form Scroll
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tracking Code Card
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _codeController,
                                  decoration: InputDecoration(
                                    labelText: context.tr('tracking_code'),
                                    prefixIcon: const Icon(CupertinoIcons.barcode),
                                    border: InputBorder.none,
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: RayoColors.primaryBlue),
                                tooltip: 'Scan Barcode',
                                onPressed: () async {
                                  final scanned = await Navigator.push<String>(
                                    context,
                                    CupertinoPageRoute(builder: (_) => const ScannerScreen(returnCodeOnly: true)),
                                  );
                                  if (scanned != null && scanned.isNotEmpty) {
                                    setState(() => _codeController.text = scanned);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recipient Info Section
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.arrow_down_left_circle_fill, color: RayoColors.successGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Text(context.tr('recipient'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              GlassTextField(
                                controller: _recipientNameController,
                                label: 'Full Name *',
                                prefixIcon: CupertinoIcons.person,
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 10),
                              GlassTextField(
                                controller: _recipientPhoneController,
                                label: 'Phone Number',
                                prefixIcon: CupertinoIcons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: GlassTextField(
                                      controller: _recipientCityController,
                                      label: 'City',
                                      prefixIcon: CupertinoIcons.location,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: GlassTextField(
                                      controller: _recipientAddressController,
                                      label: 'Address Details',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sender Info Section
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.arrow_up_right_circle_fill, color: RayoColors.primaryBlue, size: 18),
                                  const SizedBox(width: 8),
                                  Text(context.tr('sender'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              GlassTextField(
                                controller: _senderNameController,
                                label: 'Sender Name / Company',
                                prefixIcon: CupertinoIcons.building_2_fill,
                              ),
                              const SizedBox(height: 10),
                              GlassTextField(
                                controller: _senderPhoneController,
                                label: 'Sender Phone',
                                prefixIcon: CupertinoIcons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: GlassTextField(
                                      controller: _senderCityController,
                                      label: 'City',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GlassTextField(
                                      controller: _senderAddressController,
                                      label: 'Address',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Package Details & Financials
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Package & Cargo Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: GlassTextField(
                                      controller: _weightController,
                                      label: 'Weight (${store.settings.weightUnit})',
                                      prefixIcon: CupertinoIcons.gauge,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GlassTextField(
                                      controller: _codController,
                                      label: 'COD (${store.settings.currencySymbol})',
                                      prefixIcon: CupertinoIcons.money_dollar,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Priority Segmented
                              const Text('Priority Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: Priority.values.map((pr) {
                                  final sel = _priority == pr;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _priority = pr),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: sel ? RayoColors.primaryBlue : Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          context.tr(pr.translationKey),
                                          style: TextStyle(
                                            color: sel ? Colors.white : null,
                                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              // Assigned Truck Dropdown
                              DropdownButtonFormField<String?>(
                                initialValue: _selectedTruckId,
                                decoration: InputDecoration(
                                  labelText: 'Assign to Truck',
                                  prefixIcon: const Icon(CupertinoIcons.bus),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('None (Unassigned)')),
                                  ...store.trucks.map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text('${t.name} (${t.plate})'),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _selectedTruckId = val),
                              ),
                              const SizedBox(height: 12),
                              GlassTextField(
                                controller: _descriptionController,
                                label: 'Contents Description',
                                maxLines: 2,
                              ),
                              const SizedBox(height: 10),
                              GlassTextField(
                                controller: _notesController,
                                label: 'Special Instructions / Notes',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

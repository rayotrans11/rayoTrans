import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../widgets/glass_widgets.dart';
import '../l10n/app_localizations.dart';

class TruckFormScreen extends StatefulWidget {
  final Truck? truckToEdit;

  const TruckFormScreen({super.key, this.truckToEdit});

  @override
  State<TruckFormScreen> createState() => _TruckFormScreenState();
}

class _TruckFormScreenState extends State<TruckFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _plateController;
  late TextEditingController _driverNameController;
  late TextEditingController _driverPhoneController;
  late TextEditingController _capacityController;
  late TextEditingController _notesController;

  TruckStatus _status = TruckStatus.available;

  @override
  void initState() {
    super.initState();
    final t = widget.truckToEdit;

    _nameController = TextEditingController(text: t?.name ?? '');
    _plateController = TextEditingController(text: t?.plate ?? '');
    _driverNameController = TextEditingController(text: t?.driverName ?? '');
    _driverPhoneController = TextEditingController(text: t?.driverPhone ?? '');
    _capacityController = TextEditingController(
      text: t != null && t.capacityKg > 0 ? t.capacityKg.toString() : '3500',
    );
    _notesController = TextEditingController(text: t?.notes ?? '');
    _status = t?.status ?? TruckStatus.available;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<AppStore>();
    final isNew = widget.truckToEdit == null;

    final newTruck = Truck(
      id: widget.truckToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      plate: _plateController.text.trim(),
      driverName: _driverNameController.text.trim(),
      driverPhone: _driverPhoneController.text.trim(),
      capacityKg: double.tryParse(_capacityController.text.trim()) ?? 0.0,
      notes: _notesController.text.trim(),
      status: _status,
      createdAt: widget.truckToEdit?.createdAt,
    );

    if (isNew) {
      store.addTruck(newTruck);
    } else {
      store.updateTruck(newTruck);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isEditing = widget.truckToEdit != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RayoBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      isEditing ? 'Edit Truck' : context.tr('new_truck'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RayoColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _save,
                      child: Text(
                        context.tr('save'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Scroll
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Truck Info
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vehicle Identification',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 14),
                              GlassTextField(
                                controller: _nameController,
                                label: 'Vehicle Name / Model *',
                                prefixIcon: CupertinoIcons.bus,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              GlassTextField(
                                controller: _plateController,
                                label: 'License Plate *',
                                prefixIcon: CupertinoIcons.tag,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              GlassTextField(
                                controller: _capacityController,
                                label:
                                    'Payload Capacity (${store.settings.weightUnit})',
                                prefixIcon: CupertinoIcons.gauge,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Driver Details
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Driver Assignment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 14),
                              GlassTextField(
                                controller: _driverNameController,
                                label: 'Driver Full Name',
                                prefixIcon: CupertinoIcons.person,
                              ),
                              const SizedBox(height: 10),
                              GlassTextField(
                                controller: _driverPhoneController,
                                label: 'Driver Phone Number',
                                prefixIcon: CupertinoIcons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status & Notes
                        GlassCard(
                          cornerRadius: 20,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: TruckStatus.values.map((s) {
                                  final isSel = _status == s;
                                  return ChoiceChip(
                                    label: Text(context.tr(s.translationKey)),
                                    selected: isSel,
                                    selectedColor: RayoColors.primaryBlue
                                        .withValues(alpha: 0.25),
                                    onSelected: (val) {
                                      if (val) setState(() => _status = s);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),
                              GlassTextField(
                                controller: _notesController,
                                label: 'Notes / Maintenance Records',
                                maxLines: 3,
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

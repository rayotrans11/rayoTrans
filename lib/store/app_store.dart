import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AppStore extends ChangeNotifier {
  List<Truck> _trucks = [];
  List<Parcel> _parcels = [];
  List<TrackingEvent> _events = [];
  AppSettings _settings = const AppSettings();

  bool _isLoading = true;
  Timer? _debounceTimer;
  Directory? _storageDir;

  List<Truck> get trucks => _trucks;
  List<Parcel> get parcels => _parcels;
  List<TrackingEvent> get events => _events;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  AppStore() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    try {
      final appSupport = await getApplicationSupportDirectory();
      _storageDir = Directory('${appSupport.path}/RayoTracking');
      if (!await _storageDir!.exists()) {
        await _storageDir!.create(recursive: true);
      }
      await _loadData();
    } catch (e) {
      debugPrint('Error init storage: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  File _getFile(String filename) {
    return File('${_storageDir!.path}/$filename');
  }

  Future<void> _loadData() async {
    try {
      final trucksFile = _getFile('trucks.json');
      if (await trucksFile.exists()) {
        final content = await trucksFile.readAsString();
        final List list = jsonDecode(content);
        _trucks = list
            .map((e) => Truck.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final parcelsFile = _getFile('parcels.json');
      if (await parcelsFile.exists()) {
        final content = await parcelsFile.readAsString();
        final List list = jsonDecode(content);
        _parcels = list
            .map((e) => Parcel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final eventsFile = _getFile('events.json');
      if (await eventsFile.exists()) {
        final content = await eventsFile.readAsString();
        final List list = jsonDecode(content);
        _events = list
            .map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final settingsFile = _getFile('settings.json');
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        _settings = AppSettings.fromJson(
          jsonDecode(content) as Map<String, dynamic>,
        );
      }

      // Add demo data on very first launch if completely empty
      if (_trucks.isEmpty && _parcels.isEmpty && !_settings.hasOnboarded) {
        _populateInitialDemoData();
      }
    } catch (e) {
      debugPrint('Failed to load JSON sandbox data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateInitialDemoData() {
    final uuid = const Uuid();
    final now = DateTime.now();

    final truck1 = Truck(
      id: uuid.v4(),
      name: 'Atlas Cargo 01',
      plate: '12345-A-26',
      driverName: 'Karim Bennani',
      driverPhone: '+212612345678',
      capacityKg: 3500,
      status: TruckStatus.onRoute,
      notes: 'Mercedes Sprinter - Route Casablanca/Rabat',
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final truck2 = Truck(
      id: uuid.v4(),
      name: 'Sahara Express 02',
      plate: '67890-B-26',
      driverName: 'Omar Idrissi',
      driverPhone: '+212698765432',
      capacityKg: 5000,
      status: TruckStatus.available,
      notes: 'Renault Master - Clean and inspected',
      createdAt: now.subtract(const Duration(days: 5)),
    );

    _trucks = [truck1, truck2];

    final parcel1 = Parcel(
      id: uuid.v4(),
      code: 'RAYO-${DateFormat('yyyyMMdd').format(now)}-0001',
      sender: const Person(
        name: 'ElectroTech Maroc',
        phone: '+212522112233',
        address: 'Bd Zerktouni 45',
        city: 'Casablanca',
      ),
      recipient: const Person(
        name: 'Amine Alaoui',
        phone: '+212677889900',
        address: 'Avenue Mohammed V, Appt 12',
        city: 'Rabat',
      ),
      weightKg: 12.5,
      descriptionText: 'Solar inverters & precision sensors',
      codAmount: 1450.0,
      priority: Priority.high,
      status: ParcelStatus.inTransit,
      truckID: truck1.id,
      notes: 'Handle with care. Fragile electronic equipment.',
      createdAt: now.subtract(const Duration(hours: 4)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    );

    final parcel2 = Parcel(
      id: uuid.v4(),
      code: 'RAYO-${DateFormat('yyyyMMdd').format(now)}-0002',
      sender: const Person(
        name: 'Artisanat du Sud',
        phone: '+212524334455',
        address: 'Medina Rue 14',
        city: 'Marrakech',
      ),
      recipient: const Person(
        name: 'Fatima Zahra',
        phone: '+212655443322',
        address: 'Hay Riad Villa 8',
        city: 'Rabat',
      ),
      weightKg: 8.0,
      descriptionText: 'Handcrafted leather goods',
      codAmount: 600.0,
      priority: Priority.normal,
      status: ParcelStatus.outForDelivery,
      truckID: truck1.id,
      notes: 'Call 15 min prior to arrival.',
      createdAt: now.subtract(const Duration(hours: 6)),
      updatedAt: now.subtract(const Duration(minutes: 30)),
    );

    final parcel3 = Parcel(
      id: uuid.v4(),
      code: 'RAYO-${DateFormat('yyyyMMdd').format(now)}-0003',
      sender: const Person(
        name: 'Pharma Nord',
        phone: '+212539001122',
        address: 'Zone Franche',
        city: 'Tanger',
      ),
      recipient: const Person(
        name: 'Clinique de l’Espoir',
        phone: '+212522998877',
        address: 'Oasis 23',
        city: 'Casablanca',
      ),
      weightKg: 4.2,
      descriptionText: 'Laboratory reagents (cold chain)',
      priority: Priority.urgent,
      status: ParcelStatus.delivered,
      truckID: truck1.id,
      notes: 'Delivered and signed by Dr. Tazi',
      createdAt: now.subtract(const Duration(hours: 8)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    );

    _parcels = [parcel1, parcel2, parcel3];

    _events = [
      TrackingEvent(
        id: uuid.v4(),
        parcelID: parcel1.id,
        timestamp: now.subtract(const Duration(hours: 4)),
        from: null,
        to: ParcelStatus.registered,
        note: 'Parcel registered in central hub',
        operatorName: 'System Hub',
      ),
      TrackingEvent(
        id: uuid.v4(),
        parcelID: parcel1.id,
        timestamp: now.subtract(const Duration(hours: 3)),
        from: ParcelStatus.registered,
        to: ParcelStatus.loaded,
        note: 'Loaded on truck 12345-A-26',
        operatorName: 'Karim Bennani',
      ),
      TrackingEvent(
        id: uuid.v4(),
        parcelID: parcel1.id,
        timestamp: now.subtract(const Duration(hours: 1)),
        from: ParcelStatus.loaded,
        to: ParcelStatus.inTransit,
        note: 'Departed Casablanca terminal',
        operatorName: 'Karim Bennani',
      ),
      TrackingEvent(
        id: uuid.v4(),
        parcelID: parcel3.id,
        timestamp: now.subtract(const Duration(hours: 2)),
        from: ParcelStatus.outForDelivery,
        to: ParcelStatus.delivered,
        note: 'Delivered directly to reception desk',
        operatorName: 'Karim Bennani',
      ),
    ];

    scheduleSave();
  }

  void scheduleSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _writeFiles();
    });
  }

  Future<void> _writeFiles() async {
    if (_storageDir == null) return;
    try {
      final encoder = const JsonEncoder.withIndent('  ');

      final trucksJson = encoder.convert(
        _trucks.map((e) => e.toJson()).toList(),
      );
      await _atomicWrite('trucks.json', trucksJson);

      final parcelsJson = encoder.convert(
        _parcels.map((e) => e.toJson()).toList(),
      );
      await _atomicWrite('parcels.json', parcelsJson);

      final eventsJson = encoder.convert(
        _events.map((e) => e.toJson()).toList(),
      );
      await _atomicWrite('events.json', eventsJson);

      final settingsJson = encoder.convert(_settings.toJson());
      await _atomicWrite('settings.json', settingsJson);
    } catch (e) {
      debugPrint('Error writing storage files: $e');
    }
  }

  Future<void> _atomicWrite(String filename, String content) async {
    final tempFile = File('${_storageDir!.path}/$filename.tmp');
    final targetFile = _getFile(filename);
    await tempFile.writeAsString(content, flush: true);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
  }

  // --- Parcel Operations ---

  String nextCode() {
    final todayStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final todayCount =
        _parcels.where((p) {
          final now = DateTime.now();
          return p.createdAt.year == now.year &&
              p.createdAt.month == now.month &&
              p.createdAt.day == now.day;
        }).length +
        1;

    final seq = todayCount.toString().padLeft(4, '0');
    final prefix = _settings.codePrefix.isNotEmpty
        ? _settings.codePrefix
        : 'RAYO';
    return '$prefix-$todayStr-$seq';
  }

  void addParcel(Parcel parcel) {
    _parcels.insert(0, parcel);
    _logEvent(
      parcelID: parcel.id,
      from: null,
      to: parcel.status,
      note: 'Registered',
    );
    notifyListeners();
    scheduleSave();
  }

  void updateParcel(Parcel parcel) {
    final index = _parcels.indexWhere((p) => p.id == parcel.id);
    if (index != -1) {
      _parcels[index] = parcel.copyWith(updatedAt: DateTime.now());
      notifyListeners();
      scheduleSave();
    }
  }

  void setParcelStatus(
    String parcelId,
    ParcelStatus newStatus, {
    String note = '',
    double? lat,
    double? lng,
  }) {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index != -1) {
      final old = _parcels[index].status;
      _parcels[index] = _parcels[index].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _logEvent(
        parcelID: parcelId,
        from: old,
        to: newStatus,
        note: note.isNotEmpty ? note : 'Status changed to ${newStatus.name}',
        lat: lat,
        lng: lng,
      );
      notifyListeners();
      scheduleSave();
    }
  }

  void assignParcelToTruck(String parcelId, String? truckId) {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index != -1) {
      _parcels[index] = _parcels[index].copyWith(truckID: truckId);
      if (truckId != null &&
          _parcels[index].status == ParcelStatus.registered) {
        setParcelStatus(
          parcelId,
          ParcelStatus.loaded,
          note: 'Assigned to truck',
        );
      } else {
        notifyListeners();
        scheduleSave();
      }
    }
  }

  void deleteParcel(String parcelId) {
    _parcels.removeWhere((p) => p.id == parcelId);
    _events.removeWhere((e) => e.parcelID == parcelId);
    notifyListeners();
    scheduleSave();
  }

  // --- Truck Operations ---

  void addTruck(Truck truck) {
    _trucks.insert(0, truck);
    notifyListeners();
    scheduleSave();
  }

  void updateTruck(Truck truck) {
    final index = _trucks.indexWhere((t) => t.id == truck.id);
    if (index != -1) {
      _trucks[index] = truck;
      notifyListeners();
      scheduleSave();
    }
  }

  void deleteTruck(String truckId) {
    _trucks.removeWhere((t) => t.id == truckId);
    // Unassign parcels
    for (int i = 0; i < _parcels.length; i++) {
      if (_parcels[i].truckID == truckId) {
        _parcels[i] = _parcels[i].copyWith(truckID: null);
      }
    }
    notifyListeners();
    scheduleSave();
  }

  void setTruckStatus(String truckId, TruckStatus status) {
    final index = _trucks.indexWhere((t) => t.id == truckId);
    if (index != -1) {
      _trucks[index] = _trucks[index].copyWith(status: status);
      notifyListeners();
      scheduleSave();
    }
  }

  void startTruckRoute(String truckId) {
    final index = _trucks.indexWhere((t) => t.id == truckId);
    if (index != -1) {
      _trucks[index] = _trucks[index].copyWith(status: TruckStatus.onRoute);
      // Advance loaded parcels to inTransit
      for (final p in _parcels.where(
        (p) => p.truckID == truckId && p.status == ParcelStatus.loaded,
      )) {
        setParcelStatus(p.id, ParcelStatus.inTransit, note: 'Route started');
      }
      notifyListeners();
      scheduleSave();
    }
  }

  void endTruckRoute(String truckId) {
    final index = _trucks.indexWhere((t) => t.id == truckId);
    if (index != -1) {
      _trucks[index] = _trucks[index].copyWith(status: TruckStatus.available);
      notifyListeners();
      scheduleSave();
    }
  }

  // --- Helpers & Queries ---

  void _logEvent({
    required String parcelID,
    required ParcelStatus? from,
    required ParcelStatus to,
    required String note,
    double? lat,
    double? lng,
  }) {
    _events.insert(
      0,
      TrackingEvent(
        id: const Uuid().v4(),
        parcelID: parcelID,
        timestamp: DateTime.now(),
        from: from,
        to: to,
        note: note,
        operatorName: _settings.operatorName.isNotEmpty
            ? _settings.operatorName
            : 'Dispatcher',
        latitude: lat,
        longitude: lng,
      ),
    );
  }

  List<Parcel> parcelsForTruck(String truckId) {
    return _parcels.where((p) => p.truckID == truckId).toList();
  }

  double loadRatioForTruck(Truck truck) {
    if (truck.capacityKg <= 0) return 0.0;
    final activeParcels = _parcels.where(
      (p) =>
          p.truckID == truck.id &&
          p.status != ParcelStatus.delivered &&
          p.status != ParcelStatus.returned,
    );
    final totalWeight = activeParcels.fold<double>(
      0.0,
      (sum, p) => sum + p.weightKg,
    );
    return (totalWeight / truck.capacityKg).clamp(0.0, 1.0);
  }

  double currentTruckWeight(Truck truck) {
    final activeParcels = _parcels.where(
      (p) =>
          p.truckID == truck.id &&
          p.status != ParcelStatus.delivered &&
          p.status != ParcelStatus.returned,
    );
    return activeParcels.fold<double>(0.0, (sum, p) => sum + p.weightKg);
  }

  List<TrackingEvent> timelineForParcel(String parcelId) {
    return _events.where((e) => e.parcelID == parcelId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // --- Settings ---

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
    scheduleSave();
  }

  // --- Backup / Export / Import ---

  String exportBackupJson() {
    final backup = RayoBackup(
      version: 1,
      exportedAt: DateTime.now(),
      trucks: _trucks,
      parcels: _parcels,
      events: _events,
      settings: _settings,
    );
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  Future<void> restoreBackupJson(String jsonString) async {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final backup = RayoBackup.fromJson(map);
    _trucks = backup.trucks;
    _parcels = backup.parcels;
    _events = backup.events;
    _settings = backup.settings;
    notifyListeners();
    scheduleSave();
  }

  String exportParcelsCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
      'code,status,priority,recipient_name,recipient_phone,recipient_city,recipient_address,weight_kg,cod_amount,truck_plate,created_at',
    );
    final iso = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final p in _parcels) {
      final truck = _trucks.firstWhere(
        (t) => t.id == p.truckID,
        orElse: () => Truck(id: '', name: '', plate: 'Unassigned'),
      );
      final fields = [
        p.code,
        p.status.name,
        p.priority.name,
        p.recipient.name,
        p.recipient.phone,
        p.recipient.city,
        p.recipient.address,
        p.weightKg.toString(),
        p.codAmount?.toString() ?? '0',
        truck.plate,
        iso.format(p.createdAt),
      ];
      final line = fields.map((f) => '"${f.replaceAll('"', '""')}"').join(',');
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  void eraseAllData() {
    _trucks.clear();
    _parcels.clear();
    _events.clear();
    notifyListeners();
    scheduleSave();
  }
}

enum ParcelStatus {
  registered,
  loaded,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  returned,
}

extension ParcelStatusX on ParcelStatus {
  String get rawValue => name;

  String get translationKey {
    switch (this) {
      case ParcelStatus.registered:
        return 'status_registered';
      case ParcelStatus.loaded:
        return 'status_loaded';
      case ParcelStatus.inTransit:
        return 'status_in_transit';
      case ParcelStatus.outForDelivery:
        return 'status_out_for_delivery';
      case ParcelStatus.delivered:
        return 'status_delivered';
      case ParcelStatus.failed:
        return 'status_failed';
      case ParcelStatus.returned:
        return 'status_returned';
    }
  }

  ParcelStatus? get next {
    switch (this) {
      case ParcelStatus.registered:
        return ParcelStatus.loaded;
      case ParcelStatus.loaded:
        return ParcelStatus.inTransit;
      case ParcelStatus.inTransit:
        return ParcelStatus.outForDelivery;
      case ParcelStatus.outForDelivery:
        return ParcelStatus.delivered;
      default:
        return null;
    }
  }

  static ParcelStatus fromString(String val) {
    return ParcelStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ParcelStatus.registered,
    );
  }
}

enum TruckStatus { available, onRoute, maintenance, offline }

extension TruckStatusX on TruckStatus {
  String get rawValue => name;

  String get translationKey {
    switch (this) {
      case TruckStatus.available:
        return 'truck_status_available';
      case TruckStatus.onRoute:
        return 'truck_status_on_route';
      case TruckStatus.maintenance:
        return 'truck_status_maintenance';
      case TruckStatus.offline:
        return 'truck_status_offline';
    }
  }

  static TruckStatus fromString(String val) {
    return TruckStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TruckStatus.available,
    );
  }
}

enum Priority { normal, high, urgent }

extension PriorityX on Priority {
  String get rawValue => name;

  String get translationKey {
    switch (this) {
      case Priority.normal:
        return 'priority_normal';
      case Priority.high:
        return 'priority_high';
      case Priority.urgent:
        return 'priority_urgent';
    }
  }

  static Priority fromString(String val) {
    return Priority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => Priority.normal,
    );
  }
}

class Person {
  final String name;
  final String phone;
  final String address;
  final String city;

  const Person({
    this.name = '',
    this.phone = '',
    this.address = '',
    this.city = '',
  });

  Person copyWith({
    String? name,
    String? phone,
    String? address,
    String? city,
  }) {
    return Person(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'address': address,
    'city': city,
  };

  factory Person.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Person();
    return Person(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }
}

class Truck {
  final String id;
  final String name;
  final String plate;
  final String driverName;
  final String driverPhone;
  final double capacityKg;
  final TruckStatus status;
  final String notes;
  final String? photoFileName;
  final bool isArchived;
  final DateTime createdAt;

  Truck({
    required this.id,
    required this.name,
    required this.plate,
    this.driverName = '',
    this.driverPhone = '',
    this.capacityKg = 0,
    this.status = TruckStatus.available,
    this.notes = '',
    this.photoFileName,
    this.isArchived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Truck copyWith({
    String? id,
    String? name,
    String? plate,
    String? driverName,
    String? driverPhone,
    double? capacityKg,
    TruckStatus? status,
    String? notes,
    String? photoFileName,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Truck(
      id: id ?? this.id,
      name: name ?? this.name,
      plate: plate ?? this.plate,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      capacityKg: capacityKg ?? this.capacityKg,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photoFileName: photoFileName ?? this.photoFileName,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'plate': plate,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'capacityKg': capacityKg,
    'status': status.rawValue,
    'notes': notes,
    'photoFileName': photoFileName,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      driverPhone: json['driverPhone'] as String? ?? '',
      capacityKg: (json['capacityKg'] as num?)?.toDouble() ?? 0.0,
      status: TruckStatusX.fromString(json['status'] as String? ?? ''),
      notes: json['notes'] as String? ?? '',
      photoFileName: json['photoFileName'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Parcel {
  final String id;
  final String code;
  final Person sender;
  final Person recipient;
  final double weightKg;
  final String descriptionText;
  final double? codAmount;
  final Priority priority;
  final ParcelStatus status;
  final String? truckID;
  final String notes;
  final List<String> photoFileNames;
  final DateTime createdAt;
  final DateTime updatedAt;

  Parcel({
    required this.id,
    required this.code,
    this.sender = const Person(),
    this.recipient = const Person(),
    this.weightKg = 0,
    this.descriptionText = '',
    this.codAmount,
    this.priority = Priority.normal,
    this.status = ParcelStatus.registered,
    this.truckID,
    this.notes = '',
    this.photoFileNames = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Parcel copyWith({
    String? id,
    String? code,
    Person? sender,
    Person? recipient,
    double? weightKg,
    String? descriptionText,
    double? codAmount,
    Priority? priority,
    ParcelStatus? status,
    String? truckID,
    String? notes,
    List<String>? photoFileNames,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Parcel(
      id: id ?? this.id,
      code: code ?? this.code,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      weightKg: weightKg ?? this.weightKg,
      descriptionText: descriptionText ?? this.descriptionText,
      codAmount: codAmount ?? this.codAmount,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      truckID: truckID ?? this.truckID,
      notes: notes ?? this.notes,
      photoFileNames: photoFileNames ?? this.photoFileNames,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'sender': sender.toJson(),
    'recipient': recipient.toJson(),
    'weightKg': weightKg,
    'descriptionText': descriptionText,
    'codAmount': codAmount,
    'priority': priority.rawValue,
    'status': status.rawValue,
    'truckID': truckID,
    'notes': notes,
    'photoFileNames': photoFileNames,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      sender: Person.fromJson(json['sender'] as Map<String, dynamic>?),
      recipient: Person.fromJson(json['recipient'] as Map<String, dynamic>?),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      descriptionText: json['descriptionText'] as String? ?? '',
      codAmount: (json['codAmount'] as num?)?.toDouble(),
      priority: PriorityX.fromString(json['priority'] as String? ?? ''),
      status: ParcelStatusX.fromString(json['status'] as String? ?? ''),
      truckID: json['truckID'] as String?,
      notes: json['notes'] as String? ?? '',
      photoFileNames:
          (json['photoFileNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class TrackingEvent {
  final String id;
  final String parcelID;
  final DateTime timestamp;
  final ParcelStatus? from;
  final ParcelStatus to;
  final String note;
  final String operatorName;
  final double? latitude;
  final double? longitude;

  TrackingEvent({
    required this.id,
    required this.parcelID,
    DateTime? timestamp,
    this.from,
    required this.to,
    this.note = '',
    this.operatorName = '',
    this.latitude,
    this.longitude,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelID': parcelID,
    'timestamp': timestamp.toIso8601String(),
    'from': from?.rawValue,
    'to': to.rawValue,
    'note': note,
    'operatorName': operatorName,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      id: json['id'] as String,
      parcelID: json['parcelID'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      from: json['from'] != null
          ? ParcelStatusX.fromString(json['from'] as String)
          : null,
      to: ParcelStatusX.fromString(json['to'] as String? ?? ''),
      note: json['note'] as String? ?? '',
      operatorName: json['operatorName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class AppSettings {
  final String companyName;
  final String operatorName;
  final String language; // 'system', 'en', 'fr', 'ar'
  final String weightUnit; // 'kg', 'lb'
  final String currencySymbol;
  final String codePrefix;
  final String theme; // 'system', 'light', 'dark'
  final String accentHex;
  final String glassStyle; // 'clear', 'regular', 'tinted'
  final bool haptics;
  final bool appLockEnabled;
  final int autoLockSeconds;
  final bool hideInSwitcher;
  final bool remindersEnabled;
  final int reminderHours;
  final String attachLocation; // 'off', 'ask', 'whenInUse'
  final bool hasOnboarded;

  const AppSettings({
    this.companyName = '',
    this.operatorName = '',
    this.language = 'system',
    this.weightUnit = 'kg',
    this.currencySymbol = 'MAD',
    this.codePrefix = 'RAYO',
    this.theme = 'system',
    this.accentHex = '#0A84FF',
    this.glassStyle = 'regular',
    this.haptics = true,
    this.appLockEnabled = false,
    this.autoLockSeconds = 60,
    this.hideInSwitcher = true,
    this.remindersEnabled = false,
    this.reminderHours = 24,
    this.attachLocation = 'off',
    this.hasOnboarded = false,
  });

  AppSettings copyWith({
    String? companyName,
    String? operatorName,
    String? language,
    String? weightUnit,
    String? currencySymbol,
    String? codePrefix,
    String? theme,
    String? accentHex,
    String? glassStyle,
    bool? haptics,
    bool? appLockEnabled,
    int? autoLockSeconds,
    bool? hideInSwitcher,
    bool? remindersEnabled,
    int? reminderHours,
    String? attachLocation,
    bool? hasOnboarded,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      operatorName: operatorName ?? this.operatorName,
      language: language ?? this.language,
      weightUnit: weightUnit ?? this.weightUnit,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      codePrefix: codePrefix ?? this.codePrefix,
      theme: theme ?? this.theme,
      accentHex: accentHex ?? this.accentHex,
      glassStyle: glassStyle ?? this.glassStyle,
      haptics: haptics ?? this.haptics,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      hideInSwitcher: hideInSwitcher ?? this.hideInSwitcher,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderHours: reminderHours ?? this.reminderHours,
      attachLocation: attachLocation ?? this.attachLocation,
      hasOnboarded: hasOnboarded ?? this.hasOnboarded,
    );
  }

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'operatorName': operatorName,
    'language': language,
    'weightUnit': weightUnit,
    'currencySymbol': currencySymbol,
    'codePrefix': codePrefix,
    'theme': theme,
    'accentHex': accentHex,
    'glassStyle': glassStyle,
    'haptics': haptics,
    'appLockEnabled': appLockEnabled,
    'autoLockSeconds': autoLockSeconds,
    'hideInSwitcher': hideInSwitcher,
    'remindersEnabled': remindersEnabled,
    'reminderHours': reminderHours,
    'attachLocation': attachLocation,
    'hasOnboarded': hasOnboarded,
  };

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    return AppSettings(
      companyName: json['companyName'] as String? ?? '',
      operatorName: json['operatorName'] as String? ?? '',
      language: json['language'] as String? ?? 'system',
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      currencySymbol: json['currencySymbol'] as String? ?? 'MAD',
      codePrefix: json['codePrefix'] as String? ?? 'RAYO',
      theme: json['theme'] as String? ?? 'system',
      accentHex: json['accentHex'] as String? ?? '#0A84FF',
      glassStyle: json['glassStyle'] as String? ?? 'regular',
      haptics: json['haptics'] as bool? ?? true,
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      autoLockSeconds: json['autoLockSeconds'] as int? ?? 60,
      hideInSwitcher: json['hideInSwitcher'] as bool? ?? true,
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      reminderHours: json['reminderHours'] as int? ?? 24,
      attachLocation: json['attachLocation'] as String? ?? 'off',
      hasOnboarded: json['hasOnboarded'] as bool? ?? false,
    );
  }
}

class RayoBackup {
  final int version;
  final DateTime exportedAt;
  final List<Truck> trucks;
  final List<Parcel> parcels;
  final List<TrackingEvent> events;
  final AppSettings settings;

  RayoBackup({
    this.version = 1,
    DateTime? exportedAt,
    required this.trucks,
    required this.parcels,
    required this.events,
    required this.settings,
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'trucks': trucks.map((e) => e.toJson()).toList(),
    'parcels': parcels.map((e) => e.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'settings': settings.toJson(),
  };

  factory RayoBackup.fromJson(Map<String, dynamic> json) {
    return RayoBackup(
      version: json['version'] as int? ?? 1,
      exportedAt: json['exportedAt'] != null
          ? DateTime.tryParse(json['exportedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      trucks:
          (json['trucks'] as List<dynamic>?)
              ?.map((e) => Truck.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      parcels:
          (json['parcels'] as List<dynamic>?)
              ?.map((e) => Parcel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>?),
    );
  }
}

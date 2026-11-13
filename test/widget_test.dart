import 'package:flutter_test/flutter_test.dart';
import 'package:rayo_tracking/models/models.dart';

void main() {
  test('Parcel and Truck model JSON serialization', () {
    final truck = Truck(
      id: 'truck-123',
      name: 'Atlas Cargo',
      plate: '12345-A-26',
      capacityKg: 3500,
      status: TruckStatus.onRoute,
    );

    final truckJson = truck.toJson();
    final restoredTruck = Truck.fromJson(truckJson);

    expect(restoredTruck.id, 'truck-123');
    expect(restoredTruck.name, 'Atlas Cargo');
    expect(restoredTruck.plate, '12345-A-26');
    expect(restoredTruck.status, TruckStatus.onRoute);

    final parcel = Parcel(
      id: 'parcel-456',
      code: 'RAYO-20261113-0001',
      recipient: const Person(name: 'Amine Alaoui', city: 'Rabat'),
      weightKg: 15.0,
      status: ParcelStatus.inTransit,
    );

    final parcelJson = parcel.toJson();
    final restoredParcel = Parcel.fromJson(parcelJson);

    expect(restoredParcel.code, 'RAYO-20261113-0001');
    expect(restoredParcel.recipient.name, 'Amine Alaoui');
    expect(restoredParcel.weightKg, 15.0);
    expect(restoredParcel.status, ParcelStatus.inTransit);
  });
}

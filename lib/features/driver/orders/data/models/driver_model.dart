import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  const DriverModel({
    required super.id,
    required super.isAvailable,
    super.latitude,
    super.longitude,
    super.currentOrderId,
    required super.name,
    required super.phone,
    required super.photo,
    required super.vehicle,
    required super.updatedAt,
  });

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint?;

    return DriverModel(
      id: doc.id,
      isAvailable: data['isAvailable'] ?? false,
      latitude: geoPoint?.latitude,
      longitude: geoPoint?.longitude,
      currentOrderId: data['currentOrderId'],
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      photo: data['photo'] ?? '',
      vehicle: data['vehicle'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAvailable': isAvailable,
      'location': (latitude != null && longitude != null) ? GeoPoint(latitude!, longitude!) : null,
      'currentOrderId': currentOrderId,
      'name': name,
      'phone': phone,
      'photo': photo,
      'vehicle': vehicle,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

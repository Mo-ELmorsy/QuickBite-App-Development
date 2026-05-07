import 'package:equatable/equatable.dart';

class DriverEntity extends Equatable {
  final String id;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final String? currentOrderId;
  final String name;
  final String phone;
  final String photo;
  final String vehicle;
  final DateTime updatedAt;

  const DriverEntity({
    required this.id,
    required this.isAvailable,
    this.latitude,
    this.longitude,
    this.currentOrderId,
    required this.name,
    required this.phone,
    required this.photo,
    required this.vehicle,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        isAvailable,
        latitude,
        longitude,
        currentOrderId,
        name,
        phone,
        photo,
        vehicle,
        updatedAt,
      ];
}

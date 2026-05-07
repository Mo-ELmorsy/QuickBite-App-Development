import 'package:equatable/equatable.dart';

class AppUserEntity extends Equatable {
  final String uid;
  final String role; // 'customer', 'restaurant', 'driver'
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? profilePhoto;
  final String? restaurantId;
  final String? driverId;

  const AppUserEntity({
    required this.uid,
    required this.role,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.profilePhoto,
    this.restaurantId,
    this.driverId,
  });

  @override
  List<Object?> get props => [
        uid,
        role,
        name,
        phone,
        email,
        address,
        profilePhoto,
        restaurantId,
        driverId,
      ];
}

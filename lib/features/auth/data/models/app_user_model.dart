import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/app_user_entity.dart';

class AppUserModel extends AppUserEntity {
  const AppUserModel({
    required super.uid,
    required super.role,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.profilePhoto,
    super.restaurantId,
    super.driverId,
  });

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel(
      uid: doc.id,
      role: data['role'] ?? 'customer',
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
      address: data['address'],
      profilePhoto: data['profilePhoto'],
      restaurantId: data['restaurantId'],
      driverId: data['driverId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'profilePhoto': profilePhoto,
      'restaurantId': restaurantId,
      'driverId': driverId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

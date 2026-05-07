import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../customer/checkout/domain/entities/order_entity.dart';
import '../../../../customer/checkout/data/models/order_model.dart';
import '../../domain/entities/driver_entity.dart';
import '../../domain/repositories/driver_order_repository.dart';
import '../models/driver_model.dart';

class FirebaseDriverOrderRepository implements DriverOrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseDriverOrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<bool> _hasConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  Stream<List<OrderEntity>> streamAvailableOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'readyForPickup')
        .where('driverId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Stream<DriverEntity?> streamCurrentDriver(String driverId) {
    return _firestore.collection('drivers').doc(driverId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DriverModel.fromFirestore(doc);
    });
  }

  @override
  Stream<OrderEntity?> streamCurrentDriverOrder(String driverId) {
    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['readyForPickup', 'onTheWay'])
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Ideally there's only one active order per driver at a time
      return OrderModel.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Future<void> acceptDelivery(String orderId, String driverId) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    final batch = _firestore.batch();
    
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'driverId': driverId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.set(driverRef, {
      'currentOrderId': orderId,
      'isAvailable': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Future<void> markPickedUp(String orderId) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    await _firestore.collection('orders').doc(orderId).update({
      'status': 'onTheWay',
      'timestamps.onTheWay': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markDelivered(String orderId, String driverId) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    final batch = _firestore.batch();
    
    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'status': 'delivered',
      'timestamps.delivered': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final driverRef = _firestore.collection('drivers').doc(driverId);
    batch.update(driverRef, {
      'currentOrderId': null,
      'isAvailable': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> toggleDriverAvailability(String driverId, bool isAvailable) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    await _firestore.collection('drivers').doc(driverId).set({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateDriverLocation(String driverId, double latitude, double longitude) async {
    if (!await _hasConnectivity()) return; // Fail silently for frequent location updates

    await _firestore.collection('drivers').doc(driverId).set({
      'location': GeoPoint(latitude, longitude),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<double> getTodayEarnings(String driverId) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .snapshots()
        .map((snapshot) {
      double earnings = 0;
      for (var doc in snapshot.docs) {
        earnings += (doc.data()['deliveryFee'] ?? 0).toDouble();
      }
      return earnings;
    });
  }
}

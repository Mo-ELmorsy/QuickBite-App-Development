import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../customer/checkout/domain/entities/order_entity.dart';
import '../../../../customer/checkout/data/models/order_model.dart';
import '../../domain/repositories/restaurant_order_repository.dart';

class FirebaseRestaurantOrderRepository implements RestaurantOrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseRestaurantOrderRepository({FirebaseFirestore? firestore})
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
  Stream<List<OrderEntity>> streamIncomingOrders(String restaurantId) {
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'preparing') {
      updates['timestamps.preparing'] = DateTime.now().toIso8601String();
    } else if (status == 'onTheWay') {
      updates['timestamps.onTheWay'] = DateTime.now().toIso8601String();
    } else if (status == 'delivered') {
      updates['timestamps.delivered'] = DateTime.now().toIso8601String();
    }

    await _firestore.collection('orders').doc(orderId).update(updates);
  }

  @override
  Future<void> rejectOrder(String orderId) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    await _firestore.collection('orders').doc(orderId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markReadyForPickup(String orderId) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    await _firestore.collection('orders').doc(orderId).update({
      'status': 'readyForPickup',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<double> getTodayRevenue(String restaurantId) {
    // Get start of today
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', whereIn: ['delivered', 'readyForPickup', 'onTheWay', 'preparing', 'confirmed'])
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['total'] ?? 0).toDouble();
      }
      return total;
    });
  }

  @override
  Future<void> toggleRestaurantOpenStatus(String restaurantId, bool isOpen) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');
    
    // Create the document if it doesn't exist
    await _firestore.collection('restaurants').doc(restaurantId).set({
      'isOpen': isOpen,
    }, SetOptions(merge: true));
  }

  @override
  Stream<bool> streamRestaurantOpenStatus(String restaurantId) {
    return _firestore.collection('restaurants').doc(restaurantId).snapshots().map((snapshot) {
      if (!snapshot.exists) return false;
      return snapshot.data()?['isOpen'] ?? false;
    });
  }
}

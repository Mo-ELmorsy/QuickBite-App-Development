import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrderRepository({FirebaseFirestore? firestore})
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
  Future<String> placeOrder(OrderEntity order) async {
    final hasInternet = await _hasConnectivity();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final orderModel = OrderModel.fromEntity(order);
    
    // We add to the 'orders' collection. If ID is empty, let Firestore generate one.
    DocumentReference docRef;
    if (order.id.isEmpty) {
      docRef = await _firestore.collection('orders').add(orderModel.toMap());
    } else {
      docRef = _firestore.collection('orders').doc(order.id);
      await docRef.set(orderModel.toMap());
    }
    
    return docRef.id;
  }

  @override
  Stream<OrderEntity> getOrderStream(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Order not found');
      }
      return OrderModel.fromFirestore(snapshot);
    });
  }
}

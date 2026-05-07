import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/repositories/menu_repository.dart';
import '../models/menu_item_model.dart';

class FirebaseMenuRepository implements MenuRepository {
  final FirebaseFirestore _firestore;

  FirebaseMenuRepository({FirebaseFirestore? firestore})
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
  Stream<List<MenuItemEntity>> streamMenuItems(String restaurantId) {
    return _firestore
        .collection('menus')
        .doc(restaurantId)
        .collection('items')
        .orderBy('category')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> addMenuItem(String restaurantId, MenuItemEntity item) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    final model = MenuItemModel.fromEntity(item);
    await _firestore
        .collection('menus')
        .doc(restaurantId)
        .collection('items')
        .add(model.toFirestore());
  }

  @override
  Future<void> updateMenuItem(String restaurantId, MenuItemEntity item) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    final model = MenuItemModel.fromEntity(item);
    await _firestore
        .collection('menus')
        .doc(restaurantId)
        .collection('items')
        .doc(item.id)
        .update(model.toFirestore());
  }

  @override
  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    await _firestore
        .collection('menus')
        .doc(restaurantId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  @override
  Future<void> toggleItemAvailability(String restaurantId, String itemId, bool isAvailable) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    await _firestore
        .collection('menus')
        .doc(restaurantId)
        .collection('items')
        .doc(itemId)
        .update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

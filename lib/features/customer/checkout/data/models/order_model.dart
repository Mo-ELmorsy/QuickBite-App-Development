import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/order_entity.dart';
import '../../../cart/presentation/bloc/cart_state.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.restaurantId,
    super.driverId,
    required super.items,
    required super.status,
    required super.subtotal,
    required super.deliveryFee,
    required super.discount,
    required super.total,
    required super.paymentMethod,
    required super.deliveryAddress,
    required super.createdAt,
    required super.updatedAt,
    required super.timestamps,
  });

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      userId: entity.userId,
      restaurantId: entity.restaurantId,
      driverId: entity.driverId,
      items: entity.items,
      status: entity.status,
      subtotal: entity.subtotal,
      deliveryFee: entity.deliveryFee,
      discount: entity.discount,
      total: entity.total,
      paymentMethod: entity.paymentMethod,
      deliveryAddress: entity.deliveryAddress,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      timestamps: entity.timestamps,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse items
    List<CartItem> parsedItems = [];
    if (data['items'] != null) {
      parsedItems = (data['items'] as List).map((i) => CartItem(
        id: i['id'] ?? '',
        name: i['name'] ?? '',
        price: (i['price'] ?? 0).toDouble(),
        quantity: i['quantity'] ?? 1,
        specialInstructions: i['specialInstructions'] ?? '',
      )).toList();
    }

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      driverId: data['driverId'],
      items: parsedItems,
      status: data['status'] ?? 'confirmed',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timestamps: data['timestamps'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'driverId': driverId,
      'items': items.map((i) => {
        'id': i.id,
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity,
        'specialInstructions': i.specialInstructions,
      }).toList(),
      'status': status,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'timestamps': timestamps,
    };
  }
}

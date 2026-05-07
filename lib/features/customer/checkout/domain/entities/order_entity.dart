import 'package:equatable/equatable.dart';
import '../../../cart/presentation/bloc/cart_state.dart';

class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String restaurantId;
  final String? driverId;
  final List<CartItem> items;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> timestamps;

  const OrderEntity({
    required this.id,
    required this.userId,
    required this.restaurantId,
    this.driverId,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.createdAt,
    required this.updatedAt,
    required this.timestamps,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        restaurantId,
        driverId,
        items,
        status,
        subtotal,
        deliveryFee,
        discount,
        total,
        paymentMethod,
        deliveryAddress,
        createdAt,
        updatedAt,
        timestamps,
      ];
}

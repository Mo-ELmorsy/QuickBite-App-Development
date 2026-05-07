import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String specialInstructions;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.specialInstructions = '',
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  @override
  List<Object?> get props => [id, name, price, quantity, specialInstructions];
}

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartUpdated extends CartState {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;

  const CartUpdated({
    required this.items,
    required this.subtotal,
    this.deliveryFee = 5.0,
    this.discount = 0.0,
  });

  double get total => subtotal + deliveryFee - discount;

  @override
  List<Object?> get props => [items, subtotal, deliveryFee, discount];
}

import 'package:equatable/equatable.dart';
import 'cart_state.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddItemToCart extends CartEvent {
  final CartItem item;

  const AddItemToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class RemoveItemFromCart extends CartEvent {
  final String itemId;

  const RemoveItemFromCart(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class UpdateItemQuantity extends CartEvent {
  final String itemId;
  final int newQuantity;

  const UpdateItemQuantity(this.itemId, this.newQuantity);

  @override
  List<Object?> get props => [itemId, newQuantity];
}

class ApplyPromoCode extends CartEvent {
  final String code;

  const ApplyPromoCode(this.code);

  @override
  List<Object?> get props => [code];
}

class ClearCart extends CartEvent {}

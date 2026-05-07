import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<AddItemToCart>(_onAddItemToCart);
    on<RemoveItemFromCart>(_onRemoveItemFromCart);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
    on<ApplyPromoCode>(_onApplyPromoCode);
    on<ClearCart>(_onClearCart);
  }

  void _onAddItemToCart(AddItemToCart event, Emitter<CartState> emit) {
    if (state is CartInitial) {
      emit(CartUpdated(
        items: [event.item],
        subtotal: event.item.price * event.item.quantity,
      ));
      return;
    }

    if (state is CartUpdated) {
      final currentState = state as CartUpdated;
      final existingIndex = currentState.items.indexWhere((i) => i.id == event.item.id);
      
      List<CartItem> newItems = List.from(currentState.items);
      
      if (existingIndex >= 0) {
        final existingItem = newItems[existingIndex];
        newItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + event.item.quantity,
        );
      } else {
        newItems.add(event.item);
      }

      emit(CartUpdated(
        items: newItems,
        subtotal: _calculateSubtotal(newItems),
        deliveryFee: currentState.deliveryFee,
        discount: currentState.discount,
      ));
    }
  }

  void _onRemoveItemFromCart(RemoveItemFromCart event, Emitter<CartState> emit) {
    if (state is CartUpdated) {
      final currentState = state as CartUpdated;
      final newItems = currentState.items.where((i) => i.id != event.itemId).toList();
      
      if (newItems.isEmpty) {
        emit(CartInitial());
      } else {
        emit(CartUpdated(
          items: newItems,
          subtotal: _calculateSubtotal(newItems),
          deliveryFee: currentState.deliveryFee,
          discount: currentState.discount,
        ));
      }
    }
  }

  void _onUpdateItemQuantity(UpdateItemQuantity event, Emitter<CartState> emit) {
    if (state is CartUpdated) {
      final currentState = state as CartUpdated;
      
      if (event.newQuantity <= 0) {
        add(RemoveItemFromCart(event.itemId));
        return;
      }

      final newItems = currentState.items.map((i) {
        if (i.id == event.itemId) {
          return i.copyWith(quantity: event.newQuantity);
        }
        return i;
      }).toList();

      emit(CartUpdated(
        items: newItems,
        subtotal: _calculateSubtotal(newItems),
        deliveryFee: currentState.deliveryFee,
        discount: currentState.discount,
      ));
    }
  }

  void _onApplyPromoCode(ApplyPromoCode event, Emitter<CartState> emit) {
    if (state is CartUpdated) {
      final currentState = state as CartUpdated;
      // Mock promo logic: if code is 'DISCOUNT10', apply $10 off
      double discount = event.code == 'DISCOUNT10' ? 10.0 : 0.0;
      
      emit(CartUpdated(
        items: currentState.items,
        subtotal: currentState.subtotal,
        deliveryFee: currentState.deliveryFee,
        discount: discount,
      ));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartInitial());
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (total, item) => total + (item.price * item.quantity));
  }
}

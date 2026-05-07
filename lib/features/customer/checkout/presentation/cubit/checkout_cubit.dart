import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final OrderRepository _orderRepository;

  CheckoutCubit(this._orderRepository) : super(CheckoutInitial());

  Future<void> placeOrder(OrderEntity order) async {
    emit(CheckoutLoading());
    try {
      final orderId = await _orderRepository.placeOrder(order);
      emit(CheckoutSuccess(orderId));
    } catch (e) {
      emit(CheckoutFailure(e.toString()));
    }
  }
}

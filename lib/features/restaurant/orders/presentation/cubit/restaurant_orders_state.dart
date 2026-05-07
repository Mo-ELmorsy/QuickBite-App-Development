import 'package:equatable/equatable.dart';
import '../../../../customer/checkout/domain/entities/order_entity.dart';

abstract class RestaurantOrdersState extends Equatable {
  const RestaurantOrdersState();

  @override
  List<Object?> get props => [];
}

class RestaurantOrdersLoading extends RestaurantOrdersState {}

class RestaurantOrdersLoaded extends RestaurantOrdersState {
  final List<OrderEntity> orders;
  final double todayRevenue;
  final bool isOpen;

  const RestaurantOrdersLoaded({
    required this.orders,
    required this.todayRevenue,
    required this.isOpen,
  });

  @override
  List<Object?> get props => [orders, todayRevenue, isOpen];
}

class RestaurantOrdersError extends RestaurantOrdersState {
  final String message;

  const RestaurantOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

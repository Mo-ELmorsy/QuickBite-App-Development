import 'package:equatable/equatable.dart';
import '../../../../customer/checkout/domain/entities/order_entity.dart';
import '../../domain/entities/driver_entity.dart';

abstract class DriverOrdersState extends Equatable {
  const DriverOrdersState();

  @override
  List<Object?> get props => [];
}

class DriverOrdersLoading extends DriverOrdersState {}

class DriverOrdersLoaded extends DriverOrdersState {
  final List<OrderEntity> availableOrders;
  final OrderEntity? currentOrder;
  final DriverEntity? driver;
  final double todayEarnings;

  const DriverOrdersLoaded({
    required this.availableOrders,
    this.currentOrder,
    this.driver,
    required this.todayEarnings,
  });

  @override
  List<Object?> get props => [availableOrders, currentOrder, driver, todayEarnings];
}

class DriverOrdersError extends DriverOrdersState {
  final String message;

  const DriverOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

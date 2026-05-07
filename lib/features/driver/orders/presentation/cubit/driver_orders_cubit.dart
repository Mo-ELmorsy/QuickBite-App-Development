import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/driver_order_repository.dart';
import 'driver_orders_state.dart';

class DriverOrdersCubit extends Cubit<DriverOrdersState> {
  final DriverOrderRepository _repository;
  final String driverId;

  StreamSubscription? _availableOrdersSub;
  StreamSubscription? _driverSub;
  StreamSubscription? _currentOrderSub;
  StreamSubscription? _earningsSub;

  DriverOrdersCubit({
    required DriverOrderRepository repository,
    required this.driverId,
  })  : _repository = repository,
        super(DriverOrdersLoading()) {
    _init();
  }

  void _init() {
    List<dynamic> available = [];
    dynamic currentDriver;
    dynamic currentOrder;
    double earnings = 0.0;

    void emitState() {
      if (state is! DriverOrdersError) {
        emit(DriverOrdersLoaded(
          availableOrders: available.cast(),
          driver: currentDriver,
          currentOrder: currentOrder,
          todayEarnings: earnings,
        ));
      }
    }

    _availableOrdersSub = _repository.streamAvailableOrders().listen((orders) {
      available = orders;
      emitState();
    }, onError: (e) => emit(DriverOrdersError(e.toString())));

    _driverSub = _repository.streamCurrentDriver(driverId).listen((driver) {
      currentDriver = driver;
      emitState();
    }, onError: (e) {});

    _currentOrderSub = _repository.streamCurrentDriverOrder(driverId).listen((order) {
      currentOrder = order;
      emitState();
    }, onError: (e) {});

    _earningsSub = _repository.getTodayEarnings(driverId).listen((e) {
      earnings = e;
      emitState();
    }, onError: (e) {});
  }

  Future<void> toggleAvailability(bool isAvailable) async {
    try {
      await _repository.toggleDriverAvailability(driverId, isAvailable);
    } catch (e) {
      emit(DriverOrdersError(e.toString()));
      _init();
    }
  }

  Future<void> acceptDelivery(String orderId) async {
    try {
      await _repository.acceptDelivery(orderId, driverId);
    } catch (e) {
      emit(DriverOrdersError(e.toString()));
      _init();
    }
  }

  Future<void> markPickedUp(String orderId) async {
    try {
      await _repository.markPickedUp(orderId);
    } catch (e) {
      emit(DriverOrdersError(e.toString()));
      _init();
    }
  }

  Future<void> markDelivered(String orderId) async {
    try {
      await _repository.markDelivered(orderId, driverId);
    } catch (e) {
      emit(DriverOrdersError(e.toString()));
      _init();
    }
  }

  @override
  Future<void> close() {
    _availableOrdersSub?.cancel();
    _driverSub?.cancel();
    _currentOrderSub?.cancel();
    _earningsSub?.cancel();
    return super.close();
  }
}

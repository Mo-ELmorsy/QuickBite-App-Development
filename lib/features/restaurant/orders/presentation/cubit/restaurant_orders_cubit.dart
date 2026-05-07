import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/restaurant_order_repository.dart';
import 'restaurant_orders_state.dart';

class RestaurantOrdersCubit extends Cubit<RestaurantOrdersState> {
  final RestaurantOrderRepository _repository;
  final String restaurantId;

  StreamSubscription? _ordersSubscription;
  StreamSubscription? _revenueSubscription;
  StreamSubscription? _openStatusSubscription;

  RestaurantOrdersCubit({
    required RestaurantOrderRepository repository,
    required this.restaurantId,
  })  : _repository = repository,
        super(RestaurantOrdersLoading()) {
    _init();
  }

  void _init() {
    // We combine the three streams or just listen and update state
    // Since stream updates can be frequent, a better approach is to keep internal state variables
    // and emit a new state whenever any of them changes.
    
    List<dynamic> currentOrders = [];
    double currentRevenue = 0.0;
    bool currentIsOpen = false;
    
    _ordersSubscription = _repository.streamIncomingOrders(restaurantId).listen((orders) {
      currentOrders = orders;
      if (state is! RestaurantOrdersError) {
        emit(RestaurantOrdersLoaded(orders: orders, todayRevenue: currentRevenue, isOpen: currentIsOpen));
      }
    }, onError: (error) {
      emit(RestaurantOrdersError(error.toString()));
    });

    _revenueSubscription = _repository.getTodayRevenue(restaurantId).listen((revenue) {
      currentRevenue = revenue;
      if (state is RestaurantOrdersLoaded) {
        emit(RestaurantOrdersLoaded(orders: currentOrders.cast(), todayRevenue: currentRevenue, isOpen: currentIsOpen));
      }
    }, onError: (error) {
      // Non-fatal, perhaps just log
    });

    _openStatusSubscription = _repository.streamRestaurantOpenStatus(restaurantId).listen((isOpen) {
      currentIsOpen = isOpen;
      if (state is RestaurantOrdersLoaded) {
        emit(RestaurantOrdersLoaded(orders: currentOrders.cast(), todayRevenue: currentRevenue, isOpen: currentIsOpen));
      }
    }, onError: (error) {
      // Non-fatal
    });
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      await _repository.updateOrderStatus(orderId, 'preparing');
    } catch (e) {
      emit(RestaurantOrdersError(e.toString()));
      _init(); // reload streams
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      await _repository.rejectOrder(orderId);
    } catch (e) {
      emit(RestaurantOrdersError(e.toString()));
      _init();
    }
  }

  Future<void> markReadyForPickup(String orderId) async {
    try {
      await _repository.markReadyForPickup(orderId);
    } catch (e) {
      emit(RestaurantOrdersError(e.toString()));
      _init();
    }
  }

  Future<void> toggleOpenStatus(bool isOpen) async {
    try {
      await _repository.toggleRestaurantOpenStatus(restaurantId, isOpen);
    } catch (e) {
      emit(RestaurantOrdersError(e.toString()));
      _init();
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    _revenueSubscription?.cancel();
    _openStatusSubscription?.cancel();
    return super.close();
  }
}

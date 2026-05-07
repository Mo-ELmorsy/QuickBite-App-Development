import '../../../../customer/checkout/domain/entities/order_entity.dart';
import '../entities/driver_entity.dart';

abstract class DriverOrderRepository {
  Stream<List<OrderEntity>> streamAvailableOrders();
  Stream<DriverEntity?> streamCurrentDriver(String driverId);
  Stream<OrderEntity?> streamCurrentDriverOrder(String driverId);
  Future<void> acceptDelivery(String orderId, String driverId);
  Future<void> markPickedUp(String orderId);
  Future<void> markDelivered(String orderId, String driverId);
  Future<void> toggleDriverAvailability(String driverId, bool isAvailable);
  Future<void> updateDriverLocation(String driverId, double latitude, double longitude);
  Stream<double> getTodayEarnings(String driverId);
}

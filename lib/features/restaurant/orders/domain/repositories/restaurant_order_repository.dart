import '../../../../customer/checkout/domain/entities/order_entity.dart';

abstract class RestaurantOrderRepository {
  Stream<List<OrderEntity>> streamIncomingOrders(String restaurantId);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> rejectOrder(String orderId);
  Future<void> markReadyForPickup(String orderId);
  Stream<double> getTodayRevenue(String restaurantId);
  Future<void> toggleRestaurantOpenStatus(String restaurantId, bool isOpen);
  Stream<bool> streamRestaurantOpenStatus(String restaurantId);
}

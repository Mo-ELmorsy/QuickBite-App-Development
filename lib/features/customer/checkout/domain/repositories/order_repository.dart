import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<String> placeOrder(OrderEntity order);
  Stream<OrderEntity> getOrderStream(String orderId);
}

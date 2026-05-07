import '../entities/menu_item_entity.dart';

abstract class MenuRepository {
  Stream<List<MenuItemEntity>> streamMenuItems(String restaurantId);
  Future<void> addMenuItem(String restaurantId, MenuItemEntity item);
  Future<void> updateMenuItem(String restaurantId, MenuItemEntity item);
  Future<void> deleteMenuItem(String restaurantId, String itemId);
  Future<void> toggleItemAvailability(String restaurantId, String itemId, bool isAvailable);
}

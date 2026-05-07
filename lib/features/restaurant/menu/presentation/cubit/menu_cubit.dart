import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/repositories/menu_repository.dart';
import 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  final MenuRepository _repository;
  final String restaurantId;
  StreamSubscription? _menuSubscription;

  MenuCubit({
    required MenuRepository repository,
    required this.restaurantId,
  })  : _repository = repository,
        super(MenuInitial());

  void loadMenu() {
    emit(MenuLoading());
    _menuSubscription?.cancel();
    _menuSubscription = _repository.streamMenuItems(restaurantId).listen(
      (items) {
        final grouped = <String, List<MenuItemEntity>>{};
        for (var item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }
        emit(MenuLoaded(items: items, groupedItems: grouped));
      },
      onError: (error) => emit(MenuError(error.toString())),
    );
  }

  Future<void> addItem(MenuItemEntity item) async {
    try {
      await _repository.addMenuItem(restaurantId, item);
      emit(const MenuOperationSuccess('Item added successfully'));
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  Future<void> updateItem(MenuItemEntity item) async {
    try {
      await _repository.updateMenuItem(restaurantId, item);
      emit(const MenuOperationSuccess('Item updated successfully'));
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _repository.deleteMenuItem(restaurantId, itemId);
      emit(const MenuOperationSuccess('Item deleted successfully'));
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  Future<void> toggleAvailability(String itemId, bool isAvailable) async {
    try {
      await _repository.toggleItemAvailability(restaurantId, itemId, isAvailable);
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _menuSubscription?.cancel();
    return super.close();
  }
}

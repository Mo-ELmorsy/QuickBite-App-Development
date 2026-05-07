import 'package:equatable/equatable.dart';
import '../../domain/entities/menu_item_entity.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItemEntity> items;
  final Map<String, List<MenuItemEntity>> groupedItems;

  const MenuLoaded({required this.items, required this.groupedItems});

  @override
  List<Object?> get props => [items, groupedItems];
}

class MenuError extends MenuState {
  final String message;
  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}

class MenuOperationSuccess extends MenuState {
  final String message;
  const MenuOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

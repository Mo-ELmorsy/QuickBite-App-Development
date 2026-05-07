import 'package:equatable/equatable.dart';

class MenuItemEntity extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String? photo;
  final String category;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuItemEntity({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.photo,
    required this.category,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  MenuItemEntity copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? photo,
    String? category,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemEntity(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      photo: photo ?? this.photo,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        description,
        price,
        photo,
        category,
        isAvailable,
        createdAt,
        updatedAt,
      ];
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../../restaurant/menu/presentation/cubit/menu_cubit.dart';
import '../../../../restaurant/menu/presentation/cubit/menu_state.dart';
import '../../../../restaurant/menu/data/repositories/firebase_menu_repository.dart';

class RestaurantMenuPage extends StatelessWidget {
  final String restaurantId;

  const RestaurantMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MenuCubit(
        repository: FirebaseMenuRepository(),
        restaurantId: restaurantId,
      )..loadMenu(),
      child: _RestaurantMenuView(restaurantId: restaurantId),
    );
  }
}

class _RestaurantMenuView extends StatelessWidget {
  final String restaurantId;
  const _RestaurantMenuView({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, menuState) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text('Restaurant Menu', style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                  background: Container(
                    color: Colors.grey.shade400,
                    child: const Center(child: Icon(Icons.restaurant, size: 80, color: Colors.white)),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {},
                  )
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange),
                          Text(' 4.5 (100+ ratings) • Burger • American'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey),
                          Text(' 20-30 min  •  Free delivery', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Currently very busy. Expect slight delays.', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (menuState is MenuLoaded && menuState.groupedItems.isNotEmpty) ...[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      labelColor: Colors.orange,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.orange,
                      isScrollable: true,
                      tabs: menuState.groupedItems.keys.map((cat) => Tab(text: cat)).toList(),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final allItems = menuState.items.where((i) => i.isAvailable).toList();
                      if (index >= allItems.length) return null;
                      final item = allItems[index];
                      return MenuItemCard(
                        id: item.id,
                        name: item.name,
                        description: item.description,
                        price: item.price,
                      );
                    },
                    childCount: menuState.items.where((i) => i.isAvailable).length,
                  ),
                ),
              ] else if (menuState is MenuLoading) ...[
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              ] else ...[
                const SliverFillRemaining(
                  child: Center(child: Text('No items available in this menu yet.', style: TextStyle(color: Colors.grey))),
                )
              ],
            ],
          ),
          bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartUpdated && state.items.isNotEmpty) {
                final cartState = state;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.push('/cart'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                          child: Text('${cartState.items.fold<int>(0, (p, c) => p + c.quantity)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Text('View Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('\$${cartState.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final double price;

  const MenuItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showItemDetails(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const Center(child: Icon(Icons.fastfood, color: Colors.grey)),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.orange, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        context.read<CartBloc>().add(AddItemToCart(CartItem(
                          id: id,
                          name: name,
                          price: price,
                        )));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added to cart'), duration: const Duration(seconds: 1)));
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 200, color: Colors.grey.shade300, child: const Center(child: Icon(Icons.fastfood, size: 80, color: Colors.white))),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                              Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(description, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 24),
                          const Text('Special Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'e.g. No pickles, extra sauce...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 32),
                                onPressed: () {
                                  if (quantity > 1) setState(() => quantity--);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text('$quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 32),
                                onPressed: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                context.read<CartBloc>().add(AddItemToCart(CartItem(
                                  id: id,
                                  name: name,
                                  price: price,
                                  quantity: quantity,
                                )));
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${quantity}x $name added to cart'), duration: const Duration(seconds: 1)));
                              },
                              child: Text('Add to Cart - \$${(price * quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

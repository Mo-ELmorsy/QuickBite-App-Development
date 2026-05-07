import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/firebase_menu_repository.dart';
import '../cubit/menu_cubit.dart';
import '../cubit/menu_state.dart';

class RestaurantMenuManagementPage extends StatelessWidget {
  const RestaurantMenuManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Get restaurantId from authenticated user profile in real app
    // For demo/fallback purposes
    final restaurantId = FirebaseAuth.instance.currentUser?.uid ?? 'restaurant_demo_1';

    return BlocProvider(
      create: (context) => MenuCubit(
        repository: FirebaseMenuRepository(),
        restaurantId: restaurantId,
      )..loadMenu(),
      child: const _MenuManagementView(),
    );
  }
}

class _MenuManagementView extends StatelessWidget {
  const _MenuManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
      ),
      body: BlocConsumer<MenuCubit, MenuState>(
        listener: (context, state) {
          if (state is MenuError) {
            Fluttertoast.showToast(msg: state.message, backgroundColor: Colors.red);
          } else if (state is MenuOperationSuccess) {
            Fluttertoast.showToast(msg: state.message, backgroundColor: Colors.green);
          }
        },
        builder: (context, state) {
          if (state is MenuLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MenuLoaded) {
            if (state.items.isEmpty) {
              return const Center(child: Text('No menu items yet. Add your first dish!'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<MenuCubit>().loadMenu();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.groupedItems.length,
                itemBuilder: (context, index) {
                  final category = state.groupedItems.keys.elementAt(index);
                  final items = state.groupedItems[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...items.map((item) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(item.description, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: item.isAvailable,
                                        onChanged: (val) {
                                          context.read<MenuCubit>().toggleAvailability(item.id, val);
                                        },
                                        activeThumbColor: Colors.green,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            onPressed: () {
                                              context.push('/restaurant/menu/edit/${item.id}', extra: item);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            onPressed: () {
                                              _showDeleteDialog(context, item.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  );
                },
              ),
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/restaurant/menu/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to remove this item from your menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<MenuCubit>().deleteItem(itemId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

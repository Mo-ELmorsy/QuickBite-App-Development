import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../data/repositories/firebase_menu_repository.dart';
import '../cubit/menu_cubit.dart';
import '../cubit/menu_state.dart';

class AddEditMenuItemPage extends StatefulWidget {
  final MenuItemEntity? item;
  const AddEditMenuItemPage({super.key, this.item});

  @override
  State<AddEditMenuItemPage> createState() => _AddEditMenuItemPageState();
}

class _AddEditMenuItemPageState extends State<AddEditMenuItemPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _photoController;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _photoController = TextEditingController(text: widget.item?.photo ?? '');
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = FirebaseAuth.instance.currentUser?.uid ?? 'restaurant_demo_1';

    return BlocProvider(
      create: (context) => MenuCubit(
        repository: FirebaseMenuRepository(),
        restaurantId: restaurantId,
      ),
      child: BlocListener<MenuCubit, MenuState>(
        listener: (context, state) {
          if (state is MenuOperationSuccess) {
            context.pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price (\$)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final price = double.tryParse(val);
                      if (price == null || price <= 0) return 'Enter a valid price';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category (e.g., Pizza, Burgers)', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _photoController,
                    decoration: const InputDecoration(labelText: 'Photo URL (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Available'),
                    value: _isAvailable,
                    onChanged: (val) => setState(() => _isAvailable = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<MenuCubit, MenuState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is MenuLoading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    final newItem = MenuItemEntity(
                                      id: widget.item?.id ?? '',
                                      restaurantId: restaurantId,
                                      name: _nameController.text,
                                      description: _descController.text,
                                      price: double.parse(_priceController.text),
                                      category: _categoryController.text,
                                      photo: _photoController.text.isEmpty ? null : _photoController.text,
                                      isAvailable: _isAvailable,
                                    );

                                    if (widget.item == null) {
                                      context.read<MenuCubit>().addItem(newItem);
                                    } else {
                                      context.read<MenuCubit>().updateItem(newItem);
                                    }
                                  }
                                },
                          child: state is MenuLoading ? const CircularProgressIndicator() : const Text('Save Item'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// screens/product_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'product_screen.dart';

class ProductListScreen extends StatefulWidget {
  final int? warehouseId;

  const ProductListScreen({super.key, this.warehouseId});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool _isLoading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterProducts);
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => _isLoading = true);

    if (widget.warehouseId != null) {
      products = await DatabaseHelper.instance
          .getProductsByWarehouse(widget.warehouseId!);
    } else {
      products = await DatabaseHelper.instance.getProducts();
    }

    filteredProducts = List.from(products);

    if (mounted) setState(() => _isLoading = false);
  }

  void _filterProducts() {
    final q = searchController.text.toLowerCase();

    filteredProducts = products.where((p) {
      return p['name'].toString().toLowerCase().contains(q) ||
          (p['category_name'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    setState(() {});
  }

  Widget _stockChip(int qty) {
    if (qty <= 0) {
      return Chip(
        label: const Text("Out of Stock"),
        backgroundColor: Colors.red[100],
      );
    } else if (qty <= 10) {
      return Chip(
        label: Text("Low ($qty)"),
        backgroundColor: Colors.orange[100],
      );
    } else {
      return Chip(
        label: Text("$qty"),
        backgroundColor: Colors.green[100],
      );
    }
  }

  Future<void> _deleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed ?? false) {
      await DatabaseHelper.instance.deleteProduct(id);
      await loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted successfully")),
      );
    }
  }

  Widget _productImage(String? path) {
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return CircleAvatar(
          backgroundImage: FileImage(file),
        );
      }
    }
    return const CircleAvatar(
      backgroundColor: Colors.blueGrey,
      child: Icon(Icons.inventory, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductScreen()),
          ).then((_) => loadProducts());
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(child: Text("No products found"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredProducts.length,
                        itemBuilder: (_, i) {
                          final p = filteredProducts[i];
                          final qty = p['quantity'] as int;

                          return Card(
                            child: ListTile(
                              leading: _productImage(p['image_path']), // Fixed column
                              title: Text(p['name']),
                              subtitle: Text(
                                  "Category: ${p['category_name'] ?? 'N/A'}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _stockChip(qty),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductScreen(product: p),
                                          ),
                                        ).then((_) => loadProducts());
                                      } else if (value == 'delete') {
                                        _deleteProduct(p['id'] as int);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Edit"),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

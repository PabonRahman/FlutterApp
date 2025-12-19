// screens/product_list_screen.dart
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
    try {
      if (widget.warehouseId != null) {
        products = await DatabaseHelper.instance.getProductsByWarehouse(widget.warehouseId!);
      } else {
        products = await DatabaseHelper.instance.getProducts();
      }
      filteredProducts = List.from(products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading products: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts() {
    final query = searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) {
        final name = product['name'].toString().toLowerCase();
        final category = product['category_name']?.toString().toLowerCase() ?? '';
        final warehouse = product['warehouse_name']?.toString().toLowerCase() ?? '';
        return name.contains(query) || 
               category.contains(query) || 
               warehouse.contains(query);
      }).toList();
    }
    
    setState(() {});
  }

  Future<void> deleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.deleteProduct(id);
      await loadProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product deleted successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStockIndicator(int quantity) {
    if (quantity <= 0) {
      return Chip(
        label: const Text("Out"),
        backgroundColor: Colors.red[100],
        labelStyle: TextStyle(
          color: Colors.red[800],
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    } else if (quantity <= 10) {
      return Chip(
        label: Text("Low: $quantity"),
        backgroundColor: Colors.orange[100],
        labelStyle: TextStyle(
          color: Colors.orange[800],
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    } else if (quantity <= 50) {
      return Chip(
        label: Text("$quantity"),
        backgroundColor: Colors.blue[100],
        labelStyle: TextStyle(
          color: Colors.blue[800],
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    } else {
      return Chip(
        label: Text("$quantity"),
        backgroundColor: Colors.green[100],
        labelStyle: TextStyle(
          color: Colors.green[800],
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.warehouseId != null 
            ? const Text("Warehouse Products")
            : const Text("All Products"),
        actions: [
          IconButton(
            onPressed: loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductScreen(),
            ),
          ).then((_) => loadProducts());
        },
        tooltip: "Add Product",
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search products",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterProducts();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _filterProducts(),
            ),
          ),
          
          // Product List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.warehouseId != null
                                  ? "No products in this warehouse"
                                  : "No products found",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Tap + to add a product",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (_, index) {
                          final product = filteredProducts[index];
                          final quantity = product['quantity'] as int;
                          
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductScreen(product: product),
                                  ),
                                ).then((_) => loadProducts());
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              title: Text(
                                product['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text("Category: ${product['category_name'] ?? 'Uncategorized'}"),
                                  if (product['warehouse_name'] != null)
                                    Text("Warehouse: ${product['warehouse_name']}"),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStockIndicator(quantity),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => deleteProduct(product['id']),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
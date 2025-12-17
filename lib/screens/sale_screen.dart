import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  List<Map<String, dynamic>> products = [];
  int? selectedProductId;
  final quantityController = TextEditingController();
  bool _isLoading = false;
  
  // Focus node for keyboard control
  final quantityFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    quantityController.dispose();
    quantityFocus.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() => _isLoading = true);
    try {
      products = List<Map<String, dynamic>>.from(await DatabaseHelper.instance.getProducts());
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

  Future<void> addSale() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    if (selectedProductId == null || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select product and enter quantity")),
      );
      return;
    }

    int qty = int.tryParse(quantityController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid quantity")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await DatabaseHelper.instance.addSale(selectedProductId!, qty);
      
      quantityController.clear();
      selectedProductId = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sale added successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Refresh product list
      loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? get selectedProduct {
    if (selectedProductId == null) return null;
    try {
      return products.firstWhere((p) => p['id'] == selectedProductId);
    } catch (e) {
      return null;
    }
  }

  double get calculatedTotal {
    if (selectedProduct == null || quantityController.text.isEmpty) return 0.0;
    
    final price = selectedProduct!['price'];
    final quantity = int.tryParse(quantityController.text) ?? 0;
    
    if (price is num && quantity > 0) {
      return (price as num).toDouble() * quantity;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Add Sale"),
          actions: [
            IconButton(
              onPressed: loadProducts,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Sale Form Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sale Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Product Selection
                            DropdownButtonFormField<int>(
                              value: selectedProductId,
                              decoration: const InputDecoration(
                                labelText: "Product *",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.shopping_bag),
                              ),
                              hint: const Text("Select Product"),
                              items: products
                                  .map<DropdownMenuItem<int>>((p) {
                                    final qty = p['quantity'] as int;
                                    return DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(
                                        "${p['name']} (Stock: $qty)",
                                        style: TextStyle(
                                          color: qty <= 0 
                                              ? Colors.red 
                                              : qty <= 10 
                                                ? Colors.orange 
                                                : Colors.black,
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => selectedProductId = v),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Product Info Card
                            if (selectedProduct != null) ...[
                              Card(
                                color: Colors.green[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Product: ${selectedProduct!['name']}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Category: ${selectedProduct!['category_name'] ?? 'Uncategorized'}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Stock: ${selectedProduct!['quantity']}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: (selectedProduct!['quantity'] as int) <= 0 
                                                      ? Colors.red 
                                                      : (selectedProduct!['quantity'] as int) <= 10 
                                                        ? Colors.orange 
                                                        : Colors.green,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Price: ৳${selectedProduct!['price']}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Divider(color: Colors.grey[300]),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Total:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "৳${calculatedTotal.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Quantity Input
                            TextField(
                              controller: quantityController,
                              focusNode: quantityFocus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: "Quantity *",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                                hintText: "Enter quantity",
                              ),
                              onChanged: (value) => setState(() {}),
                              onSubmitted: (_) => addSale(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Add Sale Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: addSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.sell, color: Colors.white),
                        label: const Text(
                          "Add Sale",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Products List Header
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            "Available Products",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Products List
                    Expanded(
                      child: products.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No products available",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (_, index) {
                                final product = products[index];
                                final quantity = product['quantity'] as int;
                                final price = product['price'];
                                final category = product['category_name'] ?? 'Uncategorized';
                                
                                Color statusColor;
                                String statusText;
                                Color textColor;
                                
                                if (quantity <= 0) {
                                  statusColor = Colors.red[100]!;
                                  statusText = "Out of Stock";
                                  textColor = Colors.red;
                                } else if (quantity <= 10) {
                                  statusColor = Colors.orange[100]!;
                                  statusText = "Low Stock";
                                  textColor = Colors.orange[800]!;
                                } else {
                                  statusColor = Colors.green[100]!;
                                  statusText = "In Stock";
                                  textColor = Colors.green;
                                }
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 1,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: statusColor,
                                      child: Text(
                                        quantity.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      product['name'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          "৳${price is num ? price.toStringAsFixed(2) : price} • $category",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      backgroundColor: statusColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedProductId = product['id'] as int;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
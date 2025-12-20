import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Map<String, dynamic>> products = [];
  int? selectedProductId;
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void loadProducts() async {
    setState(() => _isLoading = true);
    try {
      products = List<Map<String, dynamic>>.from(await DatabaseHelper.instance.getProducts());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading products: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void addPurchase() async {
    if (selectedProductId == null || quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    int qty = int.tryParse(quantityController.text) ?? 0;
    double price = double.tryParse(priceController.text) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid quantity")),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid price")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DatabaseHelper.instance.addPurchase(selectedProductId!, qty, price);

      quantityController.clear();
      priceController.clear();
      selectedProductId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Purchase added successfully"),
          backgroundColor: Colors.green,
        ),
      );

      loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    int qty = product['quantity'] as int;
    Color stockColor = qty <= 0
        ? Colors.red
        : qty <= 10
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor,
          child: Text(
            qty.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(product['name']),
        subtitle: Text(
          "৳${product['price']} • ${product['category_name'] ?? 'Uncategorized'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: qty <= 10
            ? Chip(
                label: Text(qty <= 0 ? "Out of Stock" : "Low Stock"),
                backgroundColor: qty <= 0 ? Colors.red[100] : Colors.orange[100],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Purchase"),
        actions: [
          IconButton(
            onPressed: loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Purchase Details",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: selectedProductId,
                            decoration: InputDecoration(
                              labelText: "Product",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.shopping_bag),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            hint: const Text("Select Product"),
                            items: products
                                .map(
                                  (p) => DropdownMenuItem<int>(
                                    value: p['id'] as int,
                                    child: Text(
                                      "${p['name']} (Stock: ${p['quantity']})",
                                      style: TextStyle(
                                        color: (p['quantity'] as int) <= 10 ? Colors.red : Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => selectedProductId = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity",
                              prefixIcon: const Icon(Icons.numbers),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Unit Price (৳)",
                              prefixIcon: const Icon(Icons.attach_money),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: addPurchase,
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text("Add Purchase", style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Available Products",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...products.map(_buildProductCard),
                ],
              ),
            ),
    );
  }
}

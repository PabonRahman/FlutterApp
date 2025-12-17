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
    if (selectedProductId == null || 
        quantityController.text.isEmpty || 
        priceController.text.isEmpty) {
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
      
      // Refresh product list
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
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Purchase Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: selectedProductId,
                            decoration: const InputDecoration(
                              labelText: "Product",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.shopping_bag),
                            ),
                            hint: const Text("Select Product"),
                            items: products
                                .map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(
                                        "${p['name']} (Stock: ${p['quantity']})",
                                        style: TextStyle(
                                          color: (p['quantity'] as int) <= 10 
                                              ? Colors.red 
                                              : Colors.black,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedProductId = v),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Quantity",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Unit Price (৳)",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: addPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text(
                        "Add Purchase",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Available Products",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...products.map((product) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (product['quantity'] as int) <= 10 
                                ? Colors.red 
                                : Colors.green,
                            child: Text(
                              (product['quantity'] as int).toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(product['name'].toString()),
                          subtitle: Text(
                            "৳${product['price']} • ${product['category_name'] ?? 'Uncategorized'}",
                          ),
                          trailing: (product['quantity'] as int) <= 10
                              ? const Chip(
                                  label: Text("Low Stock"),
                                  backgroundColor: Colors.orange,
                                )
                              : null,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
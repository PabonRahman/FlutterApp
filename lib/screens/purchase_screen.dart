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

  Future<void> loadProducts() async {
    setState(() => _isLoading = true);
    try {
      products = List<Map<String, dynamic>>.from(
        await DatabaseHelper.instance.getProducts(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading products: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addPurchase() async {
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

    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid quantity & price")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DatabaseHelper.instance.addPurchase(
        selectedProductId!,
        qty,
        price,
      );

      quantityController.clear();
      priceController.clear();
      selectedProductId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Purchase saved successfully"),
          backgroundColor: Colors.green,
        ),
      );

      loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    int qty = product['quantity'];
    Color stockColor =
        qty <= 0 ? Colors.red : qty <= 10 ? Colors.orange : Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor,
          child: Text(
            qty.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(product['name']),
        subtitle: Text(
          "${product['category_name'] ?? 'Uncategorized'}",
          style: const TextStyle(fontSize: 12),
        ),
        trailing: qty <= 10
            ? Chip(
                label: Text(qty <= 0 ? "Out" : "Low"),
                backgroundColor:
                    qty <= 0 ? Colors.red[100] : Colors.orange[100],
              )
            : null,
      ),
    );
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
            icon: const Icon(Icons.refresh),
            onPressed: loadProducts,
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
                  // Purchase Form Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: selectedProductId,
                            hint: const Text("Select Product"),
                            decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.shopping_bag_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: products
                                .map(
                                  (p) => DropdownMenuItem<int>(
                                    value: p['id'],
                                    child: Text(
                                      "${p['name']} (Stock: ${p['quantity']})",
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedProductId = v),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: priceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Unit Price (৳)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          
                          // ADD PURCHASE BUTTON - MOVED HERE
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 55,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : addPurchase,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                "SAVE PURCHASE",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Available Products Section
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
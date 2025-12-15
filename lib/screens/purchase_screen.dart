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

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void loadProducts() async {
    products = List<Map<String, dynamic>>.from(await DatabaseHelper.instance.getProducts());
    setState(() {});
  }

  void addPurchase() async {
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

    String date = DateTime.now().toIso8601String();

    await DatabaseHelper.instance.addPurchase(selectedProductId!, qty, date);

    // Update product quantity
    final product = products.firstWhere((p) => p['id'] == selectedProductId);
    int newQty = (product['quantity'] as int) + qty;
    await DatabaseHelper.instance.addProduct(
      product['name'].toString(),
      product['price'] as double,
      newQty,
      product['category_id'] as int,
    );

    quantityController.clear();
    selectedProductId = null;
    loadProducts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Purchase added successfully")),
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Purchase")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: selectedProductId,
              hint: const Text("Select Product"),
              items: products
                  .map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                        value: p['id'] as int,
                        child: Text(p['name'].toString()),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedProductId = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addPurchase,
                child: const Text("Add Purchase"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

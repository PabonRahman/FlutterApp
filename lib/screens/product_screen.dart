import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final name = TextEditingController();
  final price = TextEditingController();
  final qty = TextEditingController();

  List categories = [];
  int? categoryId;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories = await DatabaseHelper.instance.getCategories();
    if (categories.isNotEmpty) categoryId = categories.first['id'];
    setState(() {});
  }

  void addProduct() async {
    if (name.text.isEmpty || price.text.isEmpty || qty.text.isEmpty) return;

    await DatabaseHelper.instance.addProduct(
      name.text,
      double.parse(price.text),
      int.parse(qty.text),
      categoryId!,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
            TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantity")),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: categoryId,
              items: categories.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem(value: c['id'], child: Text(c['name']));
              }).toList(),
              onChanged: (v) => categoryId = v,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: addProduct, child: const Text("Save")),
            )
          ],
        ),
      ),
    );
  }
}

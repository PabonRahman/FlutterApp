import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'category_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final name = TextEditingController();
  final price = TextEditingController();
  final qty = TextEditingController();

  List products = [];
  List categories = [];
  int? categoryId;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    products = await DatabaseHelper.instance.getProducts();
    categories = await DatabaseHelper.instance.getCategories();

    if (categories.isNotEmpty && categoryId == null) {
      categoryId = categories.first['id'];
    }

    setState(() {});
  }

  void add() async {
    if (name.text.isEmpty ||
        price.text.isEmpty ||
        qty.text.isEmpty ||
        categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields required")));
      return;
    }

    await DatabaseHelper.instance.addProduct(
      name.text,
      double.parse(price.text),
      int.parse(qty.text),
      categoryId!,
    );

    name.clear();
    price.clear();
    qty.clear();
    categoryId = null;

    load();
  }

  void deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              ).then((_) => load()); // reload after returning
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Quantity"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: categoryId,
                  hint: const Text("Category"),
                  items: categories.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'],
                      child: Text(c['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: add,
                    child: const Text("Add Product"),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text("No products added"))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        title: Text(products[i]['name']),
                        subtitle: Text(
                          "${products[i]['category']} | \$${products[i]['price']} | Qty ${products[i]['quantity']}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteProduct(products[i]['id']),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

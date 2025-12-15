import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'product_screen.dart';
import 'category_screen.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalProducts = 0, totalCategories = 0, totalQuantity = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  void loadStats() async {
    final products = await DatabaseHelper.instance.getProducts();
    final categories = await DatabaseHelper.instance.getCategories();
    int qty = products.fold(0, (sum, p) => sum + (p['quantity'] as int));
    setState(() {
      totalProducts = products.length;
      totalCategories = categories.length;
      totalQuantity = qty;
    });
  }

  Widget buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ])
          ],
        ),
      ),
    );
  }

  Widget buildDashboardButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 150,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            buildCard("Total Products", totalProducts.toString(), Icons.shopping_bag, Colors.blue),
            buildCard("Total Categories", totalCategories.toString(), Icons.category, Colors.orange),
            buildCard("Total Quantity", totalQuantity.toString(), Icons.storage, Colors.green),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                buildDashboardButton(
                  "Products",
                  Icons.shopping_bag,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductScreen())).then((_) => loadStats()),
                ),
                buildDashboardButton(
                  "Categories",
                  Icons.category,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen())).then((_) => loadStats()),
                ),
                buildDashboardButton(
                  "Purchase",
                  Icons.add_box,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseScreen())).then((_) => loadStats()),
                ),
                buildDashboardButton(
                  "Sale",
                  Icons.sell,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleScreen())).then((_) => loadStats()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

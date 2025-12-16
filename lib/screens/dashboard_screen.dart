import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'category_screen.dart';
import 'purchase_screen.dart';
import 'sale_screen.dart';
import '../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalProducts = 0;
  int totalCategories = 0;
  int totalQuantity = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    final products = await DatabaseHelper.instance.getProducts();
    final categories = await DatabaseHelper.instance.getCategories();
    int qty = products.fold(0, (sum, p) => sum + (p['quantity'] as int));

    setState(() {
      totalProducts = products.length;
      totalCategories = categories.length;
      totalQuantity = qty;
    });
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ])
          ],
        ),
      ),
    );
  }

  Widget dashboardButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 160,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
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
            statCard("Total Products", totalProducts.toString(), Icons.shopping_bag, Colors.blue),
            statCard("Total Categories", totalCategories.toString(), Icons.category, Colors.orange),
            statCard("Total Quantity", totalQuantity.toString(), Icons.storage, Colors.green),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Products → Product List
                dashboardButton(
                  "Products",
                  Icons.shopping_bag,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductListScreen()),
                  ).then((_) => loadStats()),
                ),
                // Categories → Category Screen (Add + List)
                dashboardButton(
                  "Categories",
                  Icons.category,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryScreen()),
                  ).then((_) => loadStats()),
                ),
                // Purchase
                dashboardButton(
                  "Purchase",
                  Icons.add_box,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PurchaseScreen()),
                  ).then((_) => loadStats()),
                ),
                // Sale
                dashboardButton(
                  "Sale",
                  Icons.sell,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SaleScreen()),
                  ).then((_) => loadStats()),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

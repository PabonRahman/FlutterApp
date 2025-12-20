import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  List<Map<String, dynamic>> purchases = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      purchases = await DatabaseHelper.instance.getPurchases();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading purchases: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔥 DELETE ALL PURCHASE HISTORY
  Future<void> _deleteAllPurchases() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete All Purchases"),
        content: const Text(
          "This will permanently delete all purchase history.\n\nAre you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete All",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.deleteAllPurchases();
      await loadPurchases();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All purchase history deleted"),
          backgroundColor: Colors.green,
        ),
      );
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

  /// DELETE SINGLE PURCHASE
  Future<void> _deletePurchase(int id) async {
    await DatabaseHelper.instance.deletePurchase(id);
    loadPurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Delete All",
            onPressed: purchases.isEmpty ? null : _deleteAllPurchases,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadPurchases,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchases.isEmpty
              ? const Center(
                  child: Text(
                    "No purchase history",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: purchases.length,
                  itemBuilder: (_, i) {
                    final p = purchases[i];
                    final date = DateTime.parse(p['date']);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Dismissible(
                        key: Key(p['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child:
                              const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deletePurchase(p['id']),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.shopping_cart),
                          ),
                          title: Text(
                            p['product_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Qty: ${p['quantity']} × ৳${p['unit_price']}\n"
                            "Date: ${date.day}/${date.month}/${date.year}",
                          ),
                          trailing: Text(
                            "৳${p['total_price'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'product_list_screen.dart';

class WarehouseDetailScreen extends StatefulWidget {
  final int warehouseId;

  const WarehouseDetailScreen({super.key, required this.warehouseId});

  @override
  State<WarehouseDetailScreen> createState() => _WarehouseDetailScreenState();
}

class _WarehouseDetailScreenState extends State<WarehouseDetailScreen> {
  Map<String, dynamic>? warehouse;
  Map<String, dynamic> stats = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    loadWarehouseData();
  }

  Future<void> loadWarehouseData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      warehouse = await DatabaseHelper.instance.getWarehouse(widget.warehouseId);
      stats = await DatabaseHelper.instance.getWarehouseStats(widget.warehouseId);
      products = await DatabaseHelper.instance.getProductsByWarehouse(widget.warehouseId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Warehouse Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (warehouse == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Warehouse Details")),
        body: const Center(child: Text("Warehouse not found")),
      );
    }

    final capacity = stats['capacity'] as int? ?? 0;
    final totalQuantity = stats['totalQuantity'] as int? ?? 0;
    final occupancy = stats['occupancy'] as double? ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(warehouse!['name']),
        actions: [
          IconButton(
            onPressed: loadWarehouseData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadWarehouseData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warehouse Info Card
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warehouse,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              warehouse!['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (warehouse!['location'] != null && warehouse!['location'].toString().isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              warehouse!['location'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (warehouse!['manager'] != null && warehouse!['manager'].toString().isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              warehouse!['manager'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (warehouse!['phone'] != null && warehouse!['phone'].toString().isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              warehouse!['phone'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (warehouse!['email'] != null && warehouse!['email'].toString().isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.email,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              warehouse!['email'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats Section
              const Text(
                "Statistics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _statCard(
                    "Total Products",
                    stats['totalProducts'].toString(),
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                  _statCard(
                    "Total Stock",
                    totalQuantity.toString(),
                    Icons.inventory,
                    Colors.green,
                  ),
                  _statCard(
                    "Capacity",
                    capacity.toString(),
                    Icons.storage,
                    Colors.orange,
                  ),
                  _statCard(
                    "Space Used",
                    "${occupancy.toStringAsFixed(1)}%",
                    Icons.pie_chart,
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Utilization Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Space Utilization",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${occupancy.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: occupancy >= 90
                                  ? Colors.red
                                  : occupancy >= 70
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: occupancy / 100,
                        backgroundColor: Colors.grey[200],
                        color: occupancy >= 90
                            ? Colors.red
                            : occupancy >= 70
                            ? Colors.orange
                            : Colors.green,
                        minHeight: 10,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Used: $totalQuantity",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            "Available: ${capacity - totalQuantity}",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Products Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Products in Warehouse",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListScreen(
                            warehouseId: widget.warehouseId,
                          ),
                        ),
                      ).then((_) => loadWarehouseData());
                    },
                    child: const Text("View All"),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              products.isEmpty
                  ? const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            "No products in this warehouse",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length > 5 ? 5 : products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[50],
                              child: Text(
                                product['quantity'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            title: Text(
                              product['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${product['category_name'] ?? 'Uncategorized'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              "Qty: ${product['quantity']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
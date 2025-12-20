import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'category_list_screen.dart';
import 'purchase_screen.dart';
import 'purchase_list_screen.dart';
import 'sale_screen.dart';
import 'sale_list_screen.dart';
import 'warehouse_list_screen.dart';
import 'login_screen.dart';
import '../database/database_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> stats = {
    'totalProducts': 0,
    'totalCategories': 0,
    'totalWarehouses': 0,
    'totalQuantity': 0,
    'totalPurchaseValue': 0.0,
    'totalSaleValue': 0.0,
    'profit': 0.0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getDashboardStats();
      if (!mounted) return;
      setState(() => stats = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic value) {
    final num v =
        value is num ? value : double.tryParse(value.toString()) ?? 0;
    return '৳${v.toStringAsFixed(2)}';
  }

  dynamic _safe(String key) => stats[key] ?? 0;

  /// ✅ FIXED STAT CARD (NO TEXT BREAKING)
  Widget _statCard(
      String title, dynamic value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profit = _safe('profit') as num;
    final profitColor = profit >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Statistics",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _statCard("Products", _safe('totalProducts'),
                          Icons.shopping_bag, Colors.blue),
                      _statCard("Stock", _safe('totalQuantity'),
                          Icons.inventory, Colors.green),
                      _statCard("Warehouses", _safe('totalWarehouses'),
                          Icons.warehouse, Colors.orange),
                      _statCard("Categories", _safe('totalCategories'),
                          Icons.category, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _statCard(
                        "Purchases",
                        _formatCurrency(_safe('totalPurchaseValue')),
                        Icons.shopping_cart,
                        Colors.orange,
                      ),
                      _statCard(
                        "Sales",
                        _formatCurrency(_safe('totalSaleValue')),
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Card(
                    color:
                        profit >= 0 ? Colors.green[50] : Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            profit >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: profitColor,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profit >= 0 ? "Net Profit" : "Net Loss",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                _formatCurrency(profit),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: profitColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Quick Actions",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _dashboardButton("Products", Icons.shopping_bag,
                          Colors.blue, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProductListScreen(warehouseId: null),
                          ),
                        ).then((_) => _loadStats());
                      }),
                      _dashboardButton("Categories", Icons.category,
                          Colors.orange, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CategoryListScreen()),
                        ).then((_) => _loadStats());
                      }),
                      _dashboardButton("Warehouses", Icons.warehouse,
                          Colors.blue, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WarehouseListScreen()),
                        ).then((_) => _loadStats());
                      }),
                      _dashboardButton("Add Purchase",
                          Icons.add_shopping_cart, Colors.green, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PurchaseScreen()),
                        ).then((_) => _loadStats());
                      }),
                      _dashboardButton("Purchase History", Icons.history,
                          Colors.blue, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PurchaseListScreen()),
                        );
                      }),
                      _dashboardButton("Add Sale", Icons.sell,
                          Colors.purple, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SaleScreen()),
                        ).then((_) => _loadStats());
                      }),
                      _dashboardButton("Sales History", Icons.receipt,
                          Colors.purple, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SaleListScreen()),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

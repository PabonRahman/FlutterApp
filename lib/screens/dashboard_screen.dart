// screens/dashboard_screen.dart
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading stats: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '৳0.00';
    final numValue = value is String
        ? double.tryParse(value) ?? 0.0
        : (value is num ? value.toDouble() : 0.0);
    return '৳${numValue.toStringAsFixed(2)}';
  }

  dynamic _getSafeValue(String key) {
    final value = stats[key];
    if (value == null) {
      switch (key) {
        case 'totalProducts':
        case 'totalCategories':
        case 'totalWarehouses':
        case 'totalQuantity':
          return 0;
        case 'totalPurchaseValue':
        case 'totalSaleValue':
        case 'profit':
          return 0.0;
        default:
          return 0;
      }
    }
    return value;
  }

  Widget _statCard(
    String title,
    dynamic value,
    IconData icon,
    Color color, {
    String? suffix,
  }) {
    final displayValue = value.toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$displayValue${suffix ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
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
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
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
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeProfit = _getSafeValue('profit') as num;
    final profitColor = safeProfit >= 0 ? Colors.green : Colors.red;
    final profitIcon =
        safeProfit >= 0 ? Icons.trending_up : Icons.trending_down;
    final profitLabel = safeProfit >= 0 ? "Net Profit" : "Net Loss";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                          "Total Products",
                          _getSafeValue('totalProducts'),
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        _statCard(
                          "Total Stock",
                          _getSafeValue('totalQuantity'),
                          Icons.inventory,
                          Colors.green,
                        ),
                        _statCard(
                          "Warehouses",
                          _getSafeValue('totalWarehouses'),
                          Icons.warehouse,
                          Colors.orange,
                        ),
                        _statCard(
                          "Categories",
                          _getSafeValue('totalCategories'),
                          Icons.category,
                          Colors.purple,
                        ),
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
                          "Total Purchase",
                          _formatCurrency(_getSafeValue('totalPurchaseValue')),
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                        _statCard(
                          "Total Sales",
                          _formatCurrency(_getSafeValue('totalSaleValue')),
                          Icons.attach_money,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      color: safeProfit >= 0 ? Colors.green[50] : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(profitIcon, color: profitColor, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profitLabel,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(safeProfit),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: profitColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _dashboardButton(
                          "Products",
                          Icons.shopping_bag,
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProductListScreen(warehouseId: null),
                            ),
                          ).then((_) => _loadStats()),
                        ),
                        _dashboardButton(
                          "Categories",
                          Icons.category,
                          Colors.orange,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryListScreen(),
                            ),
                          ).then((_) => _loadStats()),
                        ),
                        _dashboardButton(
                          "Warehouses",
                          Icons.warehouse,
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WarehouseListScreen(),
                            ),
                          ).then((_) => _loadStats()),
                        ),
                        _dashboardButton(
                          "Add Purchase",
                          Icons.add_shopping_cart,
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PurchaseScreen(),
                            ),
                          ).then((_) => _loadStats()),
                        ),
                        _dashboardButton(
                          "Purchase History",
                          Icons.history,
                          Colors.blue,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PurchaseListScreen(),
                            ),
                          ),
                        ),
                        _dashboardButton(
                          "Add Sale",
                          Icons.sell,
                          Colors.purple,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SaleScreen(),
                            ),
                          ).then((_) => _loadStats()),
                        ),
                        _dashboardButton(
                          "Sales History",
                          Icons.receipt,
                          Colors.purple,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SaleListScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

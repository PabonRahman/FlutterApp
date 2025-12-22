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
  Map<String, dynamic> _stats = {
    'totalProducts': 0,
    'totalCategories': 0,
    'totalWarehouses': 0,
    'totalQuantity': 0,
    'totalPurchaseValue': 0.0,
    'totalSaleValue': 0.0,
    'grossProfit': 0.0,
    'totalCOGS': 0.0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final data = await DatabaseHelper.instance.getDashboardStats();
      if (!mounted) return;
      
      setState(() => _stats = data);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading dashboard: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(dynamic value) {
    try {
      final num v = value is num ? value : double.tryParse(value.toString()) ?? 0;
      return '৳${v.toStringAsFixed(2)}';
    } catch (_) {
      return '৳0.00';
    }
  }

  dynamic _safe(String key) => _stats[key] ?? 0;

  /// Stat Card Widget
  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value.toString(),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  /// Dashboard Button Widget
  Widget _buildDashboardButton(
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
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrossProfitCard() {
    final grossProfit = _safe('grossProfit') as num;
    final totalCOGS = _safe('totalCOGS') as num;
    final totalSales = _safe('totalSaleValue') as num;
    final totalPurchases = _safe('totalPurchaseValue') as num;
    
    final profitColor = grossProfit >= 0 ? Colors.green : Colors.red;
    final icon = grossProfit >= 0 ? Icons.trending_up : Icons.trending_down;
    final bgColor = grossProfit >= 0 ? Colors.green[50] : Colors.red[50];
    
    // Calculate gross profit margin percentage
    double marginPercent = totalSales > 0 
        ? (grossProfit / totalSales) * 100 
        : 0.0;

    return Card(
      color: bgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: profitColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: profitColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gross Profit",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatCurrency(grossProfit),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: profitColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Margin: ${marginPercent.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 12,
                          color: profitColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Additional financial metrics
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinancialMetricRow(
                    "Sales Revenue",
                    _formatCurrency(totalSales),
                    Colors.purple,
                  ),
                  const SizedBox(height: 6),
                  _buildFinancialMetricRow(
                    "Cost of Goods Sold",
                    _formatCurrency(totalCOGS),
                    Colors.orange,
                  ),
                  const SizedBox(height: 6),
                  _buildFinancialMetricRow(
                    "Total Purchases",
                    _formatCurrency(totalPurchases),
                    Colors.blue,
                    showBorder: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetricRow(
    String label, 
    String value, 
    Color color, {
    bool showBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
                    // Statistics Section
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        "Statistics",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // First Grid - Basic Stats
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      padding: EdgeInsets.zero,
                      children: [
                        _buildStatCard(
                          "Products",
                          _safe('totalProducts'),
                          Icons.shopping_bag,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          "Stock",
                          _safe('totalQuantity'),
                          Icons.inventory,
                          Colors.green,
                        ),
                        _buildStatCard(
                          "Warehouses",
                          _safe('totalWarehouses'),
                          Icons.warehouse,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          "Categories",
                          _safe('totalCategories'),
                          Icons.category,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Second Grid - Financial Stats
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      padding: EdgeInsets.zero,
                      children: [
                        _buildStatCard(
                          "Total Purchases",
                          _formatCurrency(_safe('totalPurchaseValue')),
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          "Total Sales",
                          _formatCurrency(_safe('totalSaleValue')),
                          Icons.attach_money,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Gross Profit Card (with detailed breakdown)
                    _buildGrossProfitCard(),

                    const SizedBox(height: 24),

                    // Quick Actions Section
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.start,
                      children: [
                        _buildDashboardButton(
                          "Products",
                          Icons.shopping_bag,
                          Colors.blue,
                          () => _navigateTo(const ProductListScreen(warehouseId: null)),
                        ),
                        _buildDashboardButton(
                          "Categories",
                          Icons.category,
                          Colors.orange,
                          () => _navigateTo(const CategoryListScreen()),
                        ),
                        _buildDashboardButton(
                          "Warehouses",
                          Icons.warehouse,
                          Colors.blue,
                          () => _navigateTo(const WarehouseListScreen()),
                        ),
                        _buildDashboardButton(
                          "Add Purchase",
                          Icons.add_shopping_cart,
                          Colors.green,
                          () => _navigateTo(const PurchaseScreen()),
                        ),
                        _buildDashboardButton(
                          "Purchase History",
                          Icons.history,
                          Colors.blue,
                          () => _navigateTo(const PurchaseListScreen()),
                        ),
                        _buildDashboardButton(
                          "Add Sale",
                          Icons.sell,
                          Colors.purple,
                          () => _navigateTo(const SaleScreen()),
                        ),
                        _buildDashboardButton(
                          "Sales History",
                          Icons.receipt,
                          Colors.purple,
                          () => _navigateTo(const SaleListScreen()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadStats());
  }
}
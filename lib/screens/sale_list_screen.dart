import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../database/database_helper.dart';
import '../utils/sale_pdf.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  List<Map<String, dynamic>> sales = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {
    setState(() => _isLoading = true);
    sales = await DatabaseHelper.instance.getSales();
    setState(() => _isLoading = false);
  }

  /// PRINT SINGLE SALE INVOICE (PDF)
  Future<void> _printSaleInvoice(Map<String, dynamic> sale) async {
    final pdf = await SalePdf.generateSalePdf(sale);

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// DELETE SALE
  Future<void> _deleteSale(int id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this sale?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmDelete) {
      await DatabaseHelper.instance.deleteSale(id);
      if (mounted) loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : sales.isEmpty
              ? const Center(
                  child: Text(
                    "No sales found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final totalPrice = sale['total_price']?.toStringAsFixed(2) ?? '0.00';
                    final unitPrice = sale['unit_price']?.toStringAsFixed(2) ?? '0.00';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Leading Icon
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                radius: 22,
                                child: Icon(
                                  Icons.sell,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                              ),
                            ),
                            
                            // Product Details - Expanded to take available space
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale['product_name']?.toString() ?? 'Unknown Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Category: ${sale['category_name']?.toString() ?? '-'}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Qty: ${sale['quantity']} × ৳$unitPrice",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Date: ${sale['date']}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Trailing - Price and Actions
                            Container(
                              width: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Total Price
                                  Text(
                                    "৳$totalPrice",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Action Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Print button
                                      IconButton(
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: const Icon(
                                          Icons.print,
                                          size: 18,
                                        ),
                                        tooltip: "Print Invoice",
                                        onPressed: () => _printSaleInvoice(sale),
                                      ),
                                      // Delete button
                                      IconButton(
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        tooltip: "Delete",
                                        onPressed: () => _deleteSale(sale['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
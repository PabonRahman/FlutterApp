import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'warehouse_detail_screen.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  List<Map<String, dynamic>> warehouses = [];
  bool _isLoading = true;
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredWarehouses = [];

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      warehouses = await DatabaseHelper.instance.getWarehouses();
      filteredWarehouses = List.from(warehouses);
    } catch (e) {
      _showErrorSnackbar("Error loading warehouses: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterWarehouses(String query) {
    if (query.isEmpty) {
      filteredWarehouses = List.from(warehouses);
    } else {
      filteredWarehouses = warehouses.where((warehouse) {
        final name = warehouse['name'].toString().toLowerCase();
        final location = warehouse['location']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) || location.contains(query.toLowerCase());
      }).toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteWarehouse(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Warehouse"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseHelper.instance.deleteWarehouse(id);
      if (mounted) {
        _loadWarehouses();
        _showSuccessSnackbar("Warehouse deleted successfully");
      }
    } catch (e) {
      _showErrorSnackbar("Cannot delete: ${e.toString()}");
    }
  }

  void _showWarehouseDialog({Map<String, dynamic>? warehouse}) {
    final nameController = TextEditingController(text: warehouse?['name'] ?? '');
    final locationController = TextEditingController(text: warehouse?['location'] ?? '');
    final capacityController = TextEditingController(text: warehouse?['capacity']?.toString() ?? '');
    final managerController = TextEditingController(text: warehouse?['manager'] ?? '');
    final phoneController = TextEditingController(text: warehouse?['phone'] ?? '');
    final emailController = TextEditingController(text: warehouse?['email'] ?? '');

    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(warehouse == null ? "Add New Warehouse" : "Edit Warehouse"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Warehouse Name *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Capacity (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: managerController,
                    decoration: const InputDecoration(
                      labelText: "Manager Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(content: Text("Warehouse name is required")),
                    );
                    return;
                  }

                  final newWarehouse = {
                    'name': nameController.text.trim(),
                    'location': locationController.text.trim(),
                    'capacity': int.tryParse(capacityController.text) ?? 0,
                    'manager': managerController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'email': emailController.text.trim(),
                  };

                  try {
                    if (warehouse == null) {
                      await DatabaseHelper.instance.addWarehouse(newWarehouse);
                      _showSuccessSnackbar("Warehouse added successfully");
                    } else {
                      await DatabaseHelper.instance.updateWarehouse(warehouse['id'], newWarehouse);
                      _showSuccessSnackbar("Warehouse updated successfully");
                    }
                    Navigator.pop(context);
                    if (mounted) _loadWarehouses();
                  } catch (e) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Text("Error: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Warehouses"),
        actions: [
          IconButton(
            onPressed: _loadWarehouses,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWarehouseDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    onChanged: _filterWarehouses,
                    decoration: InputDecoration(
                      labelText: "Search warehouses",
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                _filterWarehouses('');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                // Warehouse List
                Expanded(
                  child: filteredWarehouses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warehouse,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No warehouses found",
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tap + to add your first warehouse",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredWarehouses.length,
                          itemBuilder: (context, index) {
                            final warehouse = filteredWarehouses[index];
                            final capacity = warehouse['capacity'] as int? ?? 0;

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WarehouseDetailScreen(
                                        warehouseId: warehouse['id'],
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Icon(
                                      Icons.warehouse,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  title: Text(
                                    warehouse['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        warehouse['location'] ?? 'No location',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Capacity: $capacity",
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      if (warehouse['manager'] != null)
                                        Text(
                                          "Manager: ${warehouse['manager']}",
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () => _showWarehouseDialog(warehouse: warehouse),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteWarehouse(warehouse['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
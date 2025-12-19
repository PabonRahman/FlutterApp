// screens/product_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  
  const ProductScreen({super.key, this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> warehouses = [];
  int? selectedCategoryId;
  int? selectedWarehouseId;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;
    if (_isEditing) {
      nameController.text = widget.product!['name'];
      quantityController.text = widget.product!['quantity'].toString();
      selectedCategoryId = widget.product!['category_id'];
      selectedWarehouseId = widget.product!['warehouse_id'];
    }
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _isLoading = true);
    try {
      categories = await DatabaseHelper.instance.getCategories();
      warehouses = await DatabaseHelper.instance.getWarehouses();
      
      if (categories.isNotEmpty && selectedCategoryId == null) {
        selectedCategoryId = categories.first['id'];
      }
      if (warehouses.isNotEmpty && selectedWarehouseId == null && !_isEditing) {
        selectedWarehouseId = warehouses.first['id'];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Enter a valid number';
    }
    if (quantity < 0) {
      return 'Quantity cannot be negative';
    }
    return null;
  }

  String? _validateCategory(int? value) {
    if (value == null) {
      return 'Please select a category';
    }
    return null;
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.tryParse(quantityController.text) ?? 0;

    setState(() => _isLoading = true);
    
    try {
      if (_isEditing) {
        await DatabaseHelper.instance.updateProduct(
          widget.product!['id'],
          nameController.text.trim(),
          quantity,
          selectedCategoryId!,
          selectedWarehouseId,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Product updated successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await DatabaseHelper.instance.addProduct(
          nameController.text.trim(),
          quantity,
          selectedCategoryId!,
          selectedWarehouseId,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Product added successfully"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Product" : "Add Product"),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Product Name
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Product Name *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                          hintText: "Enter product name",
                        ),
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),
                      
                      // Initial Quantity
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Initial Stock Quantity *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                          helperText: "Set initial stock quantity",
                          suffixText: "units",
                        ),
                        validator: _validateQuantity,
                        textInputAction: TextInputAction.next,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),
                      
                      // Category Dropdown
                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: "Category *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category['id'],
                            child: Text(category['name']),
                          );
                        }).toList(),
                        validator: _validateCategory,
                        onChanged: (value) => setState(() => selectedCategoryId = value),
                      ),
                      const SizedBox(height: 16),
                      
                      // Warehouse Dropdown (Optional)
                      DropdownButtonFormField<int?>(
                        initialValue: selectedWarehouseId,
                        decoration: const InputDecoration(
                          labelText: "Warehouse (Optional)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse),
                          helperText: "Leave empty if not stored in warehouse",
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text("No Warehouse"),
                          ),
                          ...warehouses.map((warehouse) {
                            return DropdownMenuItem<int?>(
                              value: warehouse['id'],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(warehouse['name']),
                                  Text(
                                    warehouse['location'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => selectedWarehouseId = value),
                      ),
                      const SizedBox(height: 32),
                      
                      // Info Card
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isEditing
                                      ? "Updating product details will not affect existing sales/purchases."
                                      : "Product price will be set during purchase/sale transactions.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_isEditing ? Icons.save : Icons.add),
                          label: _isLoading
                              ? const Text("Processing...")
                              : Text(_isEditing ? "Update Product" : "Add Product"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
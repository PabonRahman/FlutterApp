// // screens/product_screen.dart
// import 'package:flutter/material.dart';
// import '../database/database_helper.dart';

// class ProductScreen extends StatefulWidget {
//   final Map<String, dynamic>? product;

//   const ProductScreen({super.key, this.product});

//   @override
//   State<ProductScreen> createState() => _ProductScreenState();
// }

// class _ProductScreenState extends State<ProductScreen> {
//   final TextEditingController nameController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   List<Map<String, dynamic>> categories = [];
//   List<Map<String, dynamic>> warehouses = [];

//   int? selectedCategoryId;
//   int? selectedWarehouseId;

//   bool _isLoading = true;
//   bool _isEditing = false;

//   @override
//   void initState() {
//     super.initState();
//     _isEditing = widget.product != null;

//     if (_isEditing) {
//       nameController.text = widget.product!['name'];
//       selectedCategoryId = widget.product!['category_id'];
//       selectedWarehouseId = widget.product!['warehouse_id'];
//     }

//     loadData();
//   }

//   Future<void> loadData() async {
//     setState(() => _isLoading = true);

//     try {
//       categories = await DatabaseHelper.instance.getCategories();
//       warehouses = await DatabaseHelper.instance.getWarehouses();

//       if (categories.isNotEmpty && selectedCategoryId == null) {
//         selectedCategoryId = categories.first['id'];
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   String? _validateName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Product name is required';
//     }
//     return null;
//   }

//   Future<void> saveProduct() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       if (_isEditing) {
//         await DatabaseHelper.instance.updateProduct(
//           widget.product!['id'],
//           nameController.text.trim(),
//           widget.product!['quantity'], // ❗ keep existing stock
//           selectedCategoryId!,
//           selectedWarehouseId,
//         );
//       } else {
//         await DatabaseHelper.instance.addProduct(
//           nameController.text.trim(),
//           0, // ✅ always start with 0 stock
//           selectedCategoryId!,
//           selectedWarehouseId,
//         );
//       }

//       if (mounted) {
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Error: $e"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isEditing ? "Edit Product" : "Add Product"),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Form(
//               key: _formKey,
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: nameController,
//                       decoration: const InputDecoration(
//                         labelText: "Product Name *",
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.shopping_bag),
//                       ),
//                       validator: _validateName,
//                     ),
//                     const SizedBox(height: 16),

//                     DropdownButtonFormField<int>(
//                       initialValue: selectedCategoryId,
//                       decoration: const InputDecoration(
//                         labelText: "Category *",
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.category),
//                       ),
//                       items: categories
//                           .map(
//                             (c) => DropdownMenuItem<int>(
//                               value: c['id'],
//                               child: Text(c['name']),
//                             ),
//                           )
//                           .toList(),
//                       onChanged: (v) => setState(() => selectedCategoryId = v),
//                     ),
//                     const SizedBox(height: 16),

//                     DropdownButtonFormField<int?>(
//                       initialValue: selectedWarehouseId,
//                       decoration: const InputDecoration(
//                         labelText: "Warehouse (Optional)",
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.warehouse),
//                       ),
//                       items: [
//                         const DropdownMenuItem(
//                           value: null,
//                           child: Text("No Warehouse"),
//                         ),
//                         ...warehouses.map(
//                           (w) => DropdownMenuItem<int?>(
//                             value: w['id'],
//                             child: Text(w['name']),
//                           ),
//                         ),
//                       ],
//                       onChanged: (v) =>
//                           setState(() => selectedWarehouseId = v),
//                     ),

//                     const SizedBox(height: 24),

//                     Card(
//                       color: Colors.blue[50],
//                       child: const Padding(
//                         padding: EdgeInsets.all(12),
//                         child: Text(
//                           "Stock quantity is managed through purchase and sale transactions.",
//                           style: TextStyle(fontSize: 13),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton.icon(
//                         onPressed: saveProduct,
//                         icon: Icon(_isEditing ? Icons.save : Icons.add),
//                         label: Text(
//                             _isEditing ? "Update Product" : "Add Product"),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }



// screens/product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';

class ProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductScreen({super.key, this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> warehouses = [];

  int? selectedCategoryId;
  int? selectedWarehouseId;

  bool _isLoading = true;
  bool _isEditing = false;

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    if (_isEditing) {
      nameController.text = widget.product!['name'];
      selectedCategoryId = widget.product!['category_id'];
      selectedWarehouseId = widget.product!['warehouse_id'];
      _imagePath = widget.product!['image_path'];
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    return null;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagePath = image.path);
    }
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await DatabaseHelper.instance.updateProduct(
          widget.product!['id'],
          nameController.text.trim(),
          widget.product!['quantity'],
          selectedCategoryId!,
          selectedWarehouseId,
          _imagePath, // pass image path
        );
      } else {
        await DatabaseHelper.instance.addProduct(
          nameController.text.trim(),
          0,
          selectedCategoryId!,
          selectedWarehouseId,
          _imagePath, // pass image path
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Product" : "Add Product"),
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
                      // Image Picker Section
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                            image: _imagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(_imagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _imagePath == null
                              ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Product Name *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: "Category *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedCategoryId = v),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int?>(
                        initialValue: selectedWarehouseId,
                        decoration: const InputDecoration(
                          labelText: "Warehouse (Optional)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("No Warehouse")),
                          ...warehouses.map(
                            (w) => DropdownMenuItem<int?>(
                              value: w['id'],
                              child: Text(w['name']),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => selectedWarehouseId = v),
                      ),

                      const SizedBox(height: 24),

                      Card(
                        color: Colors.blue[50],
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Stock quantity is managed through purchase and sale transactions.",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: saveProduct,
                          icon: Icon(_isEditing ? Icons.save : Icons.add),
                          label: Text(_isEditing ? "Update Product" : "Add Product"),
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


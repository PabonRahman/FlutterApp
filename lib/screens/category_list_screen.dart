import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<Map<String, dynamic>> categories = [];
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories = List<Map<String, dynamic>>.from(
      await DatabaseHelper.instance.getCategories(),
    );
    setState(() {});
  }

  void addCategory() async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category name required")),
      );
      return;
    }

    await DatabaseHelper.instance.addCategory(controller.text.trim());
    controller.clear();
    loadCategories();
  }

  void deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    loadCategories();
  }

  // ✅ Edit Category Dialog
  void editCategory(int id, String oldName) {
    final TextEditingController editController =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;

              await DatabaseHelper.instance.updateCategory(
                id,
                editController.text.trim(),
              );

              Navigator.pop(context);
              loadCategories();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Column(
        children: [
          // Add Category
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: addCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Icon(Icons.add, size: 28),
                ),
              ],
            ),
          ),

          // Category List
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text('No categories added'))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            c['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () =>
                                    editCategory(c['id'], c['name']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => deleteCategory(c['id']),
                              ),
                            ],
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

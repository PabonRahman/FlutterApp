import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController controller = TextEditingController();
  List categories = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    categories = await DatabaseHelper.instance.getCategories();
    setState(() {});
  }

  void add() async {
    if (controller.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Category name required")));
      return;
    }
    await DatabaseHelper.instance.addCategory(controller.text);
    controller.clear();
    load();
  }

  void deleteCategory(int id) async {
    await DatabaseHelper.instance.deleteCategory(id);
    load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "Category name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: add,
                  icon: const Icon(Icons.add, size: 30),
                ),
              ],
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? const Center(child: Text("No categories added"))
                : ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        title: Text(categories[i]['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteCategory(categories[i]['id']),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

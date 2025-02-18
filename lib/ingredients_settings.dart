import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IngredientsListPage extends StatefulWidget {
  const IngredientsListPage({super.key});

  @override
  State<IngredientsListPage> createState() => _IngredientsListPageState();
}

class _IngredientsListPageState extends State<IngredientsListPage> {
  final TextEditingController _ingredientController = TextEditingController();
  String _selectedCategory = "Base Ingredients";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Ingredients List",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddIngredientDialog(),
          )
        ],
      ),
      body: Column(
        children: [
          _buildIngredientsSection("Base Ingredients", "base_ingredients"),
          _buildIngredientsSection(
              "Removable Ingredients", "removable_ingredients"),
          _buildIngredientsSection("Add-ons", "addons"),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(String title, String collectionName) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            width: double.infinity,
            color: Colors.deepPurple.shade100,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(collectionName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No ingredients added yet."));
                }

                final ingredients = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: ingredients.length,
                  itemBuilder: (context, index) {
                    var ingredient = ingredients[index];
                    return ListTile(
                      title: Text(ingredient['name']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteIngredient(collectionName, ingredient.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddIngredientDialog() async {
    _ingredientController.clear();
    _selectedCategory = "Base Ingredients";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Ingredient"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ingredientController,
                decoration: const InputDecoration(labelText: "Ingredient Name"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Category: "),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(
                            value: "Base Ingredients",
                            child: Text("Base Ingredients")),
                        DropdownMenuItem(
                            value: "Removable Ingredients",
                            child: Text("Removable Ingredients")),
                        DropdownMenuItem(
                            value: "Add-ons", child: Text("Add-ons")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _addIngredient(),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addIngredient() async {
    String name = _ingredientController.text.trim();
    if (name.isEmpty) return;

    String collection;
    if (_selectedCategory == "Base Ingredients") {
      collection = "base_ingredients";
    } else if (_selectedCategory == "Removable Ingredients") {
      collection = "removable_ingredients";
    } else {
      collection = "addons";
    }

    await FirebaseFirestore.instance.collection(collection).add({"name": name});

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  Future<void> _deleteIngredient(String collection, String docId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IngredientsListPage extends StatefulWidget {
  const IngredientsListPage({super.key});

  @override
  State<IngredientsListPage> createState() => _IngredientsListPageState();
}

class _IngredientsListPageState extends State<IngredientsListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedCategory = "Base Ingredients";
  String searchQuery = "";

  final Color backgroundColor = const Color(0xFF1E1E2E);
  final Color cardColor = const Color(0xFF2A2D3E);
  final Color textColor = const Color(0xFFEAEAEA);
  final Color borderColor = const Color(0xFF3B3F54);
  final Color inputFieldColor = const Color(0xFF303446);
  final Color buttonColor = const Color(0xFF8B5CF6);
  final Color deleteColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ingredientController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: textColor),
          title: Text("Ingredients", style: TextStyle(color: textColor)),
          backgroundColor: cardColor,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: buttonColor,
            labelColor: buttonColor,
            unselectedLabelColor: textColor.withValues(alpha: 0.6),
            tabs: const [
              Tab(text: "Base"),
              Tab(text: "Removable"),
              Tab(text: "Add-ons"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: _showAddIngredientDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFieldColor,
                  labelText: "Search Ingredient",
                  labelStyle:
                      TextStyle(color: textColor.withValues(alpha: 0.8)),
                  prefixIcon: Icon(Icons.search, color: textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                ),
                onChanged: _updateSearchQuery,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIngredientsList("base_ingredients"),
                  _buildIngredientsList("removable_ingredients"),
                  _buildIngredientsList("addons"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsList(String collectionName) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection(collectionName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No ingredients added yet.",
                style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
            );
          }

          final ingredients = snapshot.data!.docs.where((doc) {
            String ingredientName = (doc['name'] as String).toLowerCase();
            return ingredientName.contains(searchQuery);
          }).toList();

          return ListView.builder(
            itemCount: ingredients.length,
            itemBuilder: (context, index) {
              var ingredient = ingredients[index];
              return Card(
                color: cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                child: ListTile(
                  title: Text(
                    ingredient['name'],
                    style: TextStyle(color: textColor),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: deleteColor),
                    onPressed: () =>
                        _deleteIngredient(collectionName, ingredient.id),
                  ),
                ),
              );
            },
          );
        },
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
          backgroundColor: cardColor,
          title: Text(
            "Add Ingredient",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ingredientController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFieldColor,
                  labelText: "Ingredient Name",
                  labelStyle:
                      TextStyle(color: textColor.withValues(alpha: 0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                dropdownColor: cardColor,
                style: TextStyle(color: textColor),
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle:
                      TextStyle(color: textColor.withValues(alpha: 0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ["Base Ingredients", "Removable Ingredients", "Add-ons"]
                    .map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: textColor)),
            ),
            ElevatedButton(
              onPressed: _addIngredient,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
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

    var existingDocs = await FirebaseFirestore.instance
        .collection(collection)
        .where('name', isEqualTo: name)
        .get();

    if (existingDocs.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This ingredient already exists!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection(collection).add({"name": name});
    Navigator.pop(context);
  }

  Future<void> _deleteIngredient(String collection, String docId) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
  }
}

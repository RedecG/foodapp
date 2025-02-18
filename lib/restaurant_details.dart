// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodorder/Widgets/menu_card.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantDetailsPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color appBarColor = const Color(0xFF2C2F48);
  final Color backgroundColor = const Color(0xFF1E1E2E);
  final Color cardColor = const Color(0xFF25273D);
  final Color accentColor = const Color(0xFFC59B76);
  final Color textColor = const Color(0xFFEAEAEA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.restaurantName,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: appBarColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.grey.shade500,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Food"),
            Tab(text: "Beverages"),
            Tab(text: "Dessert"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: textColor),
            tooltip: "Add Menu Item",
            onPressed: () {
              _showAddMenuItemDialog(context);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuList("All"),
          _buildMenuList("Food"),
          _buildMenuList("Beverages"),
          _buildMenuList("Dessert"),
        ],
      ),
    );
  }

  Widget _buildMenuList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No menu items found."));
        }

        final menuItems = snapshot.data!.docs.where((menuItem) {
          if (category == "All") return true;
          return menuItem['category'] == category;
        }).toList();

        if (menuItems.isEmpty) {
          return Center(child: Text("No $category items found."));
        }

        return ListView.builder(
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            return MenuCard(
              menuItem: menuItems[index],
              restaurantId: widget.restaurantId,
            );
          },
        );
      },
    );
  }

  void _showAddMenuItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = "Food";
    String selectedCurrency = "USD";

    String? selectedBaseIngredient;
    Set<String> selectedRemovableIngredients = {};
    Set<String> selectedAddons = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add New Menu Item"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Price",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: const [
                        DropdownMenuItem(value: "Food", child: Text("Food")),
                        DropdownMenuItem(
                            value: "Beverages", child: Text("Beverages")),
                        DropdownMenuItem(
                            value: "Dessert", child: Text("Dessert")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      items: const [
                        DropdownMenuItem(value: "USD", child: Text("USD")),
                        DropdownMenuItem(value: "LBP", child: Text("LBP")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCurrency = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Currency",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("base_ingredients")
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        var baseIngredients = snapshot.data!.docs
                            .map((doc) => doc['name'] as String)
                            .toList();

                        return DropdownButtonFormField<String>(
                          value: selectedBaseIngredient,
                          items: baseIngredients.map((ingredient) {
                            return DropdownMenuItem(
                                value: ingredient, child: Text(ingredient));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedBaseIngredient = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: "Base Ingredient",
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection("removable_ingredients")
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        var removableIngredients = snapshot.data!.docs
                            .map((doc) => doc['name'] as String)
                            .toList();

                        return Wrap(
                          spacing: 8,
                          children: removableIngredients.map((ingredient) {
                            bool isSelected = selectedRemovableIngredients
                                .contains(ingredient);
                            return ChoiceChip(
                              label: Text(ingredient),
                              selected: isSelected,
                              selectedColor: Colors.deepPurple.shade100,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (isSelected) {
                                    selectedRemovableIngredients
                                        .remove(ingredient);
                                  } else {
                                    selectedRemovableIngredients
                                        .add(ingredient);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<QuerySnapshot>(
                      future:
                          FirebaseFirestore.instance.collection("addons").get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        var addons = snapshot.data!.docs
                            .map((doc) => doc['name'] as String)
                            .toList();

                        return Wrap(
                          spacing: 8,
                          children: addons.map((addon) {
                            bool isSelected = selectedAddons.contains(addon);
                            return ChoiceChip(
                              label: Text(addon),
                              selected: isSelected,
                              selectedColor: Colors.orange.shade100,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (isSelected) {
                                    selectedAddons.remove(addon);
                                  } else {
                                    selectedAddons.add(addon);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        priceController.text.isEmpty ||
                        selectedBaseIngredient == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please fill all fields!")),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('restaurants')
                        .doc(widget.restaurantId)
                        .collection('menu')
                        .add({
                      'name': nameController.text,
                      'price': double.parse(priceController.text),
                      'category': selectedCategory,
                      'currency': selectedCurrency,
                      'base_ingredient': selectedBaseIngredient,
                      'removable_ingredients':
                          selectedRemovableIngredients.toList(),
                      'addons': selectedAddons.toList(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Menu item added successfully!")),
                    );
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

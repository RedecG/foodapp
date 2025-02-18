// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrderItemsPage extends StatefulWidget {
  final String restaurantId;

  const MyOrderItemsPage({super.key, required this.restaurantId});

  @override
  State<MyOrderItemsPage> createState() => _MyOrderItemsPageState();
}

class _MyOrderItemsPageState extends State<MyOrderItemsPage> {
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _removeItem(String orderId, String itemId) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items') // ✅ Access subcollection correctly
        .doc(itemId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item removed successfully!")),
    );
  }

  void _editItem(String orderId, String itemId, Map<String, dynamic> itemData) {
    TextEditingController ingredientController = TextEditingController(
      text: (itemData['selectedIngredients'] as List<dynamic>).join(", "),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Ingredients"),
          content: TextField(
            controller: ingredientController,
            decoration: const InputDecoration(
              labelText: "Enter ingredients separated by commas",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                List<String> updatedIngredients = ingredientController.text
                    .split(",")
                    .map((e) => e.trim())
                    .toList();

                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .collection('items') // ✅ Correct Firestore path
                    .doc(itemId)
                    .update({'selectedIngredients': updatedIngredients});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingredients updated!")),
                );

                Navigator.pop(context);
                setState(() {}); // Refresh UI
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("My Ordered Items",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 77, 6, 95),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'Open') // ✅ Get only active orders
            .where('restaurantId', isEqualTo: widget.restaurantId)
            .snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("You have no items in this order.",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
          }

          List<QueryDocumentSnapshot> orders = orderSnapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: orders.expand((order) {
              return _fetchUserItems(order.id); // ✅ Fetch items per order
            }).toList(),
          );
        },
      ),
    );
  }

  /// ✅ Fetch user-specific items from each order
  List<Widget> _fetchUserItems(String orderId) {
    return [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .collection('items') // ✅ Accessing the correct subcollection
            .where('userId', isEqualTo: userId) // ✅ Show only this user's items
            .snapshots(),
        builder: (context, itemSnapshot) {
          if (!itemSnapshot.hasData || itemSnapshot.data!.docs.isEmpty) {
            return const SizedBox(); // No items found for this user in the order
          }

          return Column(
            children: itemSnapshot.data!.docs.map((itemDoc) {
              var item = itemDoc.data() as Map<String, dynamic>;
              String itemId = itemDoc.id;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(item['itemName'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Ingredients: ${item['selectedIngredients'].join(', ')}"),
                      Text("Price: ${item['price']} ${item['currency']}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editItem(orderId, itemId, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(orderId, itemId),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    ];
  }
}

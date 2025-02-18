// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MenuCard extends StatelessWidget {
  final QueryDocumentSnapshot menuItem;
  final String restaurantId;

  const MenuCard({
    super.key,
    required this.menuItem,
    required this.restaurantId,
  });

  final Color cardBackground = const Color(0xFF25273D);
  final Color textColor = const Color(0xFFEAEAEA);
  final Color priceColor = const Color(0xFFC59B76);
  final Color buttonColor = const Color(0xFF4B0082);
  final Color subTextColor = const Color(0xFFA0A3B1);

  @override
  Widget build(BuildContext context) {
    String formatPrice(dynamic price) {
      if (price == null) return "N/A";
      try {
        final formatter = NumberFormat("#,##0", "en_US");
        return formatter.format(price);
      } catch (e) {
        return price.toString();
      }
    }

    String baseIngredient = menuItem['base_ingredient'] ?? 'N/A';
    List<String> removableIngredients =
        List<String>.from(menuItem['removable_ingredients'] ?? []);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                menuItem['name'] ?? "Unnamed Item",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                "Price: ${formatPrice(menuItem['price'])} ${menuItem['currency'] ?? ''}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: priceColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Ingredients: $baseIngredient${removableIngredients.isNotEmpty ? ', ${removableIngredients.join(', ')}' : ''}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: priceColor,
                  ),
                  onPressed: () {
                    _showOrderSelectionDialog(context);
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFF2C2F48),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select an Order",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: priceColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Create a New Order",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () async {
                    String orderId = await _createNewOrder(context);
                    Navigator.pop(context);
                    _showIngredientSelectionSheet(context, orderId);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  "Add to an Existing Order",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchOpenOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            "No open orders found.",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade400),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 200,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade700,
                        ),
                        itemBuilder: (context, index) {
                          var order = snapshot.data![index];

                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            tileColor: const Color(0xFF25273D),
                            leading: const Icon(Icons.shopping_cart,
                                color: Color(0xFFD4A373)),
                            title: Text(
                              "Order #${order['orderId']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            subtitle: Text(
                              "Created by: ${order['firstName']} ${order['lastName']}",
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 18),
                            onTap: () {
                              Navigator.pop(context);
                              _showIngredientSelectionSheet(
                                  context, order['orderId']);
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _createNewOrder(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String firstName =
        userDoc.exists ? (userDoc['firstName'] ?? "Unknown") : "Unknown";
    String lastName = userDoc.exists ? (userDoc['lastName'] ?? "") : "";

    DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .get();

    String restaurantName = restaurantDoc.exists
        ? (restaurantDoc['name'] ?? "Unknown Restaurant")
        : "Unknown Restaurant";

    String orderId = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
      'orderId': orderId,
      'userId': user.uid,
      'firstName': firstName,
      'lastName': lastName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'status': 'Open',
      'timestamp': FieldValue.serverTimestamp(),
      'items': [],
    });

    return orderId;
  }

  Future<List<Map<String, dynamic>>> _fetchOpenOrders() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'Open')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  void _showIngredientSelectionSheet(BuildContext context, String orderId) {
    List<String> removableIngredients =
        List<String>.from(menuItem['removable_ingredients'] ?? []);
    List<String> addons = List<String>.from(menuItem['addons'] ?? []);

    Set<String> selectedRemovals = {};
    Set<String> selectedExtras = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2F48),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        "Customize Your Order",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: priceColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (removableIngredients.isNotEmpty) ...[
                      const Divider(color: Colors.grey, thickness: 0.3),
                      const SizedBox(height: 10),
                      Text(
                        "Remove Ingredients",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent[100],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: removableIngredients.map((ingredient) {
                          bool isSelected =
                              !selectedRemovals.contains(ingredient);
                          return SwitchListTile(
                            tileColor: const Color(0xFF25273D),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            title: Text(ingredient,
                                style: const TextStyle(color: Colors.white)),
                            activeColor: priceColor,
                            value: isSelected,
                            onChanged: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedRemovals.remove(ingredient);
                                } else {
                                  selectedRemovals.add(ingredient);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (addons.isNotEmpty) ...[
                      const Divider(color: Colors.grey, thickness: 0.3),
                      const SizedBox(height: 10),
                      Text(
                        "Add Extras",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent[200],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: addons.map((addon) {
                          bool isSelected = selectedExtras.contains(addon);
                          return SwitchListTile(
                            tileColor: const Color(0xFF25273D),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            title: Text(addon,
                                style: const TextStyle(color: Colors.white)),
                            activeColor: Colors.greenAccent[400],
                            value: isSelected,
                            onChanged: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedExtras.add(addon);
                                } else {
                                  selectedExtras.remove(addon);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .collection('cart')
                              .add({
                            'userId': FirebaseAuth.instance.currentUser?.uid,
                            'itemName': menuItem['name'],
                            'selectedIngredients': removableIngredients
                                .where((ingredient) =>
                                    !selectedRemovals.contains(ingredient))
                                .toList(),
                            'removedIngredients': selectedRemovals.toList(),
                            'addedExtras': selectedExtras.toList(),
                            'price': menuItem['price'],
                            'currency': menuItem['currency'],
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Item added to order!"),
                              backgroundColor: priceColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: priceColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Add to Order",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

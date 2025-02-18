import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodorder/Helpers/cart_provider.dart';

class CartPage extends StatelessWidget {
  final String orderId;

  const CartPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    // ✅ Load cart when entering the cart page
    cartProvider.loadCart(orderId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 77, 6, 95),
      ),
      body: cartProvider.items.isEmpty
          ? const Center(child: Text("Your cart is empty."))
          : ListView.builder(
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        item['firstName'][0]
                            .toUpperCase(), // Show first letter of user's name
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      item['itemName'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Added by: ${item['firstName']} ${item['lastName']}"),
                        Text(
                          "Ingredients: ${item['selectedIngredients'].join(', ')}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "Price: ${item['price']} ${item['currency']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        cartProvider.removeFromCart(item['id']);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodorder/Widgets/restaurant_card.dart';
import 'restaurantcreation_page.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  final Color backgroundColor = const Color(0xFF1E1E2E); // Dark Mode BG
  final Color cardColor = const Color(0xFF25273D); // Charcoal Gray
  final Color textColor = const Color(0xFFEAEAEA); // Light Gray
  final Color accentColor = const Color(0xFFC59B76); // Muted Gold

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Jaw3an?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C2F48), // Darker Elegant Header
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: accentColor), // Gold Add Icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestaurantCreationPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading restaurants.",
                style: TextStyle(fontSize: 18, color: Colors.redAccent[200]),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No restaurants found.",
                style: TextStyle(fontSize: 18, color: Colors.grey[400]),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: RestaurantCard(restaurant: docs[index]),
              );
            },
          );
        },
      ),
    );
  }
}

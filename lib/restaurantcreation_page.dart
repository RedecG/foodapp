// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantCreationPage extends StatefulWidget {
  const RestaurantCreationPage({super.key});

  @override
  State<RestaurantCreationPage> createState() => _RestaurantCreationPageState();
}

class _RestaurantCreationPageState extends State<RestaurantCreationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _foodTypeController = TextEditingController();

  final CollectionReference restaurants =
      FirebaseFirestore.instance.collection('restaurants');

  final Color backgroundColor = const Color(0xFF1E1E2E); // Dark Blue
  final Color cardColor = const Color(0xFF25273D); // Charcoal Gray
  final Color textColor = const Color(0xFFEAEAEA); // Light Gray
  final Color accentColor = const Color(0xFFC59B76); // Muted Gold
  final Color cancelButtonColor = const Color(0xFF444857); // Dark Gray
  final Color inputBorderColor =
      const Color(0xFF3E4155); // Slightly lighter gray

  Future<void> addRestaurant() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _foodTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields!")),
      );
      return;
    }

    try {
      await restaurants.add({
        'name': _nameController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'foodType': _foodTypeController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restaurant added successfully!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add restaurant: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        title: Text("Add New Restaurant", style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildTextField(_nameController, "Restaurant Name"),
                  const SizedBox(height: 16),
                  _buildTextField(_addressController, "Address"),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, "Phone", isPhone: true),
                  const SizedBox(height: 16),
                  _buildTextField(_foodTypeController,
                      "Food Type (e.g., Bakery, Pizzeria)"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildButton("Cancel", cancelButtonColor, () {
                  Navigator.pop(context);
                }),
                _buildButton("Add", accentColor, addRestaurant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        filled: true,
        fillColor: cardColor,
        labelText: label,
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

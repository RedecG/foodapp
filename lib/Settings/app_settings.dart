// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool isDarkMode = false;
  final TextEditingController _rateController = TextEditingController();

  // 🎨 Theme Colors
  final Color backgroundColor = const Color(0xFF1E1E2E);
  final Color cardColor = const Color(0xFF2A2D3E);
  final Color textColor = const Color(0xFFEAEAEA);
  final Color accentColor = const Color(0xFFC59B76);
  final Color inputFieldColor = const Color(0xFF303446);
  final Color borderColor = const Color(0xFF3B3F54);

  @override
  void initState() {
    super.initState();
    _loadConversionRate();
  }

  Future<void> _loadConversionRate() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('currency_rates')
          .doc('usd_to_lbp')
          .get();

      if (doc.exists) {
        _rateController.text = (doc['rate'] as num).toString();
      }
    } catch (e) {
      debugPrint("Error fetching conversion rate: $e");
    }
  }

  Future<void> _updateConversionRate() async {
    double? newRate = double.tryParse(_rateController.text);
    if (newRate != null && newRate > 0) {
      try {
        await FirebaseFirestore.instance
            .collection('currency_rates')
            .doc('usd_to_lbp')
            .set({'rate': newRate});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Conversion rate updated successfully!")),
        );
      } catch (e) {
        debugPrint("Error updating conversion rate: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update conversion rate.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid conversion rate!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        title: Text("App Settings", style: TextStyle(color: textColor)),
        backgroundColor: cardColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              title: "Set USD to LBP Conversion Rate",
              child: Column(
                children: [
                  TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFieldColor,
                      prefixIcon:
                          Icon(Icons.currency_exchange, color: accentColor),
                      labelText: "Enter conversion rate",
                      labelStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 1),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateConversionRate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Save Rate",
                          style: TextStyle(color: textColor, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required Widget child}) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

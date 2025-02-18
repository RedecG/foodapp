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
  //test

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
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 77, 6, 95),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text("Dark Mode"),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                },
              ),
            ),
            const Divider(),
            const Text(
              "Set USD to LBP Conversion Rate",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Enter conversion rate",
                prefixIcon: Icon(Icons.currency_exchange),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateConversionRate,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 77, 6, 95)),
              child: const Text("Save Rate",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

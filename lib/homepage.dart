// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodorder/Helpers/roles_panel.dart';
import 'package:foodorder/login_page.dart';
import 'package:foodorder/neworder_page.dart';
import 'package:foodorder/orders_page.dart';
import 'package:foodorder/Settings/settings.dart';
import 'package:foodorder/statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String firstName = "Guest";
  bool isAdmin = false;
  int _selectedIndex = 0;

  final Color appBarColor = const Color(0xFF2C2F48);
  final Color appBarTextColor = const Color(0xFFC59B76);
  final Color iconColor = const Color(0xFFC59B76);
  final Color navBarColor = const Color(0xFF2C2F48);
  final Color selectedNavColor = const Color(0xFFC59B76);
  final Color unselectedNavColor = const Color(0xFFA8A8A8);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          firstName = userDoc['firstName'] ?? "Guest";
          isAdmin = userDoc['role'] == "admin";
        });
      }
    } catch (e) {
      log("Error fetching user data: $e", name: "UserData");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const StatisticsPage(),
    const NewOrderPage(),
    const OrdersPage(),
  ];

  Future<void> _confirmSignOut() async {
    bool? firstStep = await _showConfirmationDialog(
      title: "Lak 5aleek 3inna",
      content: "Met2aked?",
    );

    if (firstStep == true) {
      bool? secondStep = await _showConfirmationDialog(
        title: "8ayer ra2yak!",
        content: "Ya3ne Met2aked",
      );

      if (secondStep == true) {
        bool? thirdStep = await _showConfirmationDialog(
          title: "E5er Forsa",
          content: "Mish tez3al lama kebak barra",
        );

        if (thirdStep == true) {
          await FirebaseAuth.instance.signOut();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            content,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: navBarColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Ok", style: TextStyle(color: Colors.white)),
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
        backgroundColor: appBarColor,
        title: Text("Welcome, $firstName!",
            style: const TextStyle(fontSize: 20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.logout, color: iconColor),
          onPressed: _confirmSignOut,
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.admin_panel_settings, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RolesPanelPage()),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.settings, color: iconColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBarColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics,
                color: _selectedIndex == 0
                    ? selectedNavColor
                    : unselectedNavColor),
            label: "Statistics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart,
                color: _selectedIndex == 1
                    ? selectedNavColor
                    : unselectedNavColor),
            label: "Restaurants",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt,
                color: _selectedIndex == 2
                    ? selectedNavColor
                    : unselectedNavColor),
            label: "Orders",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: selectedNavColor,
        unselectedItemColor: unselectedNavColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

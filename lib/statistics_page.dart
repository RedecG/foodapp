import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int totalOrders = 0;
  int totalItemsOrdered = 0;
  double totalUSD = 0;
  double totalLBP = 0;
  double conversionRate = 90000;
  String mostOrderedRestaurant = "N/A";
  String mostRemovedIngredient = "N/A";

  final Color cardColor = const Color(0xFF25273D);
  final Color textColor = const Color(0xFFEAEAEA);
  final Color accentColor = const Color(0xFFC59B76);

  @override
  void initState() {
    super.initState();
    _fetchConversionRate();
  }

  Future<void> _fetchConversionRate() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('currency_rates')
          .doc('usd_to_lbp')
          .get();

      if (doc.exists) {
        setState(() {
          conversionRate = (doc['rate'] as num).toDouble();
        });
      }
    } catch (e) {
      debugPrint("Error fetching conversion rate: $e");
    }

    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      QuerySnapshot closedOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Closed')
          .where('userId', isEqualTo: user.uid)
          .get();

      int orderCount = closedOrdersSnapshot.docs.length;
      int itemCount = 0;
      double usdTotal = 0;
      double lbpTotal = 0;
      Map<String, int> removedIngredientFrequency = {};

      List<Future<QuerySnapshot>> cartQueries = closedOrdersSnapshot.docs
          .map((order) => FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('cart')
              .get())
          .toList();

      List<QuerySnapshot> cartSnapshots = await Future.wait(cartQueries);

      for (var cartItems in cartSnapshots) {
        itemCount += cartItems.docs.length;

        for (var cartItem in cartItems.docs) {
          var item = cartItem.data() as Map<String, dynamic>;
          if (!item.containsKey('price') || !item.containsKey('currency')) {
            debugPrint("Missing price or currency in item: $item");
            continue;
          }

          double price = (item['price'] as num).toDouble();
          String currency = item['currency'] ?? "USD";

          if (currency == "USD") {
            usdTotal += price;
            lbpTotal += price * conversionRate;
          } else if (currency == "LBP") {
            usdTotal += price / conversionRate;
            lbpTotal += price;
          }

          List<dynamic> removedIngredients = item['removedIngredients'] ?? [];
          for (var ingredient in removedIngredients) {
            removedIngredientFrequency[ingredient] =
                (removedIngredientFrequency[ingredient] ?? 0) + 1;
          }
        }
      }

      String mostRemoved = removedIngredientFrequency.isNotEmpty
          ? removedIngredientFrequency.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : "N/A";

      setState(() {
        totalOrders = orderCount;
        totalItemsOrdered = itemCount;
        totalUSD = usdTotal;
        totalLBP = lbpTotal;
        mostRemovedIngredient = mostRemoved;
      });
    } catch (e) {
      debugPrint("Error fetching statistics: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        iconTheme: IconThemeData(color: textColor),
        title: Text("My Statistics", style: TextStyle(color: textColor)),
        backgroundColor: const Color(0xFF2C2F48),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Ensures two columns on mobile
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4, // Ensures content fits
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        List<Map<String, dynamic>> stats = [
          {
            "title": "Total Orders",
            "value": totalOrders.toString(),
            "icon": Icons.shopping_bag
          },
          {
            "title": "Total Items",
            "value": totalItemsOrdered.toString(),
            "icon": Icons.fastfood
          },
          {
            "title": "Total Paid (USD)",
            "value": "\$${formatNumber(totalUSD, isUSD: true)}",
            "icon": Icons.attach_money
          },
          {
            "title": "Total Paid (LBP)",
            "value": "${formatNumber(totalLBP)} LBP",
            "icon": Icons.monetization_on
          },
          {
            "title": "Most Removed",
            "value": mostRemovedIngredient,
            "icon": Icons.no_meals
          },
          {
            "title": "Favorite Restaurant",
            "value": mostOrderedRestaurant,
            "icon": Icons.store
          },
        ];

        return _buildStatCard(
            stats[index]["title"], stats[index]["value"], stats[index]["icon"]);
      },
    );
  }

  String formatNumber(dynamic number, {bool isUSD = false}) {
    if (number == null) return "N/A";
    final formatter = NumberFormat(isUSD ? "#,##0.00" : "#,##0", "en_US");
    return formatter.format(number);
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: accentColor),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

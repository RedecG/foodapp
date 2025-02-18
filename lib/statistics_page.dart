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

  final LinearGradient backgroundGradient = const LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF2C2F48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      Map<String, int> restaurantFrequency = {};
      Map<String, int> removedIngredientFrequency = {};
      Set<String> restaurantIds = {};

      List<Future<QuerySnapshot>> cartQueries = closedOrdersSnapshot.docs
          .map((order) => FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('cart')
              .get())
          .toList();

      List<QuerySnapshot> cartSnapshots = await Future.wait(cartQueries);

      for (int i = 0; i < closedOrdersSnapshot.docs.length; i++) {
        var order = closedOrdersSnapshot.docs[i];
        var cartItems = cartSnapshots[i].docs;

        if (cartItems.isEmpty) continue;

        String restaurantId = order['restaurantId'] ?? "Unknown";
        restaurantIds.add(restaurantId);
        restaurantFrequency[restaurantId] =
            (restaurantFrequency[restaurantId] ?? 0) + 1;

        itemCount += cartItems.length;

        for (var cartItem in cartItems) {
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

      Map<String, String> restaurantNames = {};
      if (restaurantIds.isNotEmpty) {
        List<Future<DocumentSnapshot>> restaurantQueries = restaurantIds
            .map((id) => FirebaseFirestore.instance
                .collection('restaurants')
                .doc(id)
                .get())
            .toList();

        List<DocumentSnapshot> restaurantDocs =
            await Future.wait(restaurantQueries);

        for (var doc in restaurantDocs) {
          if (doc.exists) {
            restaurantNames[doc.id] = doc['name'] ?? "Unknown Restaurant";
          }
        }
      }

      String favoriteRestaurant = "N/A";
      if (restaurantFrequency.isNotEmpty) {
        var sortedRestaurants = restaurantFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        String mostOrderedRestaurantId = sortedRestaurants.first.key;
        favoriteRestaurant =
            restaurantNames[mostOrderedRestaurantId] ?? "Unknown Restaurant";
      }

      String mostRemoved = "N/A";
      if (removedIngredientFrequency.isNotEmpty) {
        mostRemoved = removedIngredientFrequency.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      setState(() {
        totalOrders = orderCount;
        totalItemsOrdered = itemCount;
        totalUSD = usdTotal;
        totalLBP = lbpTotal;
        mostOrderedRestaurant = favoriteRestaurant;
        mostRemovedIngredient = mostRemoved;
      });
    } catch (e) {
      debugPrint("Error fetching statistics: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          iconTheme: IconThemeData(color: textColor),
          title: Text("My Statistics", style: TextStyle(color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: _buildStatsGrid(),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
            "My Total Orders", totalOrders.toString(), Icons.shopping_bag),
        _buildStatCard("Total Items Ordered", totalItemsOrdered.toString(),
            Icons.fastfood),
        _buildStatCard(
            "Favorite Restaurant", mostOrderedRestaurant, Icons.store),
        _buildStatCard("Total Paid (USD)",
            "\$${formatNumber(totalUSD, isUSD: true)}", Icons.attach_money),
        _buildStatCard("Total Paid (LBP)", "${formatNumber(totalLBP)} LBP",
            Icons.monetization_on),
        _buildStatCard(
            "Most Removed Ingredient", mostRemovedIngredient, Icons.no_meals),
      ],
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
            Icon(icon, size: 32, color: accentColor),
            const SizedBox(height: 6),
            Text(title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            Text(value, style: TextStyle(fontSize: 18, color: accentColor)),
          ],
        ),
      ),
    );
  }
}

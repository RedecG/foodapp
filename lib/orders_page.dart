import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String filterStatus = "All";
  double conversionRate = 90000;

  final Color cardBackground = const Color(0xFF25273D);
  final Color textColor = const Color(0xFFEAEAEA);
  final Color accentColor = const Color(0xFFC59B76);
  final Color borderColor = const Color(0xFF2C2F48);
  final Color orderOpenColor = Colors.greenAccent;
  final Color orderClosedColor = Colors.redAccent;

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
  }

  String formatPrice(dynamic price, {bool isUSD = false}) {
    if (price == null) return "N/A";
    try {
      final formatter = isUSD
          ? NumberFormat("#,##0.00", "en_US")
          : NumberFormat("#,##0", "en_US");
      return formatter.format(price);
    } catch (e) {
      return price.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2F48),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() {
                filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All Orders")),
              const PopupMenuItem(value: "Open", child: Text("Open Orders")),
              const PopupMenuItem(
                  value: "Closed", child: Text("Closed Orders")),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No orders found.",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var order =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Card(
                  color: cardBackground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      expandedAlignment: Alignment.centerLeft,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Text(
                        "Order #${order['orderId']}",
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${order['restaurantName'] ?? 'Unknown'}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Created by: ${order['firstName']} ${order['lastName']}",
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.8)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Date: ${order['timestamp'] != null ? (order['timestamp'] as Timestamp).toDate().toString() : 'Unknown'}",
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Status: ${order['status']}",
                              style: TextStyle(
                                color: order['status'] == "Open"
                                    ? orderOpenColor
                                    : orderClosedColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: FutureBuilder<double>(
                        future: _buildOrderTotal(order['orderId']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              width: 80,
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 1.5),
                              ),
                            );
                          }
                          if (!snapshot.hasData) return const Text("N/A");

                          return Text(
                            "${formatPrice(snapshot.data, isUSD: true)} USD",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          );
                        },
                      ),
                      children: [
                        _buildOrderItems(order['orderId']),
                        if (order['status'] == "Open")
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _closeOrder(order['orderId']);
                              },
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              label: const Text("Close Order",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA52A2A),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderItems(String orderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('cart')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                "No items in this order.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          );
        }

        Map<String, List<Map<String, dynamic>>> userOrders = {};
        Map<String, double> userTotalUSD = {};
        Map<String, double> userTotalLBP = {};

        for (var cartItem in snapshot.data!.docs) {
          var item = cartItem.data() as Map<String, dynamic>;
          double itemPrice = (item['price'] as num).toDouble();
          String currency = item['currency'] ?? "USD";
          String userId = item['userId'] ?? "Unknown";

          if (!userOrders.containsKey(userId)) {
            userOrders[userId] = [];
            userTotalUSD[userId] = 0;
            userTotalLBP[userId] = 0;
          }

          if (currency == "USD") {
            userTotalUSD[userId] = userTotalUSD[userId]! + itemPrice;
            userTotalLBP[userId] =
                userTotalLBP[userId]! + (itemPrice * conversionRate);
          } else if (currency == "LBP") {
            userTotalUSD[userId] =
                userTotalUSD[userId]! + (itemPrice / conversionRate);
            userTotalLBP[userId] = userTotalLBP[userId]! + itemPrice;
          }

          userOrders[userId]!.add(item);
        }

        return Column(
          children: userOrders.entries.map((entry) {
            String userId = entry.key;
            List<Map<String, dynamic>> items = entry.value;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                String firstName = "Unknown";
                String lastName = "";

                if (userSnapshot.connectionState == ConnectionState.done &&
                    userSnapshot.hasData &&
                    userSnapshot.data!.exists) {
                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  firstName = userData['firstName'] ?? "Unknown";
                  lastName = userData['lastName'] ?? "";
                }

                return Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2F48),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['itemName'] ?? "Unknown Item",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Ingredients: ${_filterSelectedIngredients(item)}",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white60),
                              ),
                              if (item.containsKey('addedExtras') &&
                                  item['addedExtras'] != null &&
                                  item['addedExtras'].isNotEmpty)
                                Text(
                                  "Add-ons: ${item['addedExtras'].join(', ')}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white60),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                "Price: ${formatPrice(item['price'], isUSD: item['currency'] == 'USD')} ${item['currency']}",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC59B76),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: Colors.white30),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          "Total: ${formatPrice(userTotalUSD[userId]!, isUSD: true)} USD / ${formatPrice(userTotalLBP[userId]!)} LBP",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accentColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<double> _buildOrderTotal(String orderId) async {
    double totalUSD = 0;

    QuerySnapshot cartSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('cart')
        .get();

    for (var cartItem in cartSnapshot.docs) {
      var item = cartItem.data() as Map<String, dynamic>;
      double itemPrice = (item['price'] as num).toDouble();
      String currency = item['currency'] ?? "USD";

      if (currency == "USD") {
        totalUSD += itemPrice;
      } else if (currency == "LBP") {
        totalUSD += itemPrice / conversionRate;
      }
    }
    return totalUSD;
  }

  String _filterSelectedIngredients(Map<String, dynamic> cartItem) {
    List<String> selectedIngredients =
        List<String>.from(cartItem['selectedIngredients'] ?? []);
    List<String> removedIngredients =
        List<String>.from(cartItem['removedIngredients'] ?? []);

    List<String> finalIngredients = selectedIngredients
        .where((ingredient) => !removedIngredients.contains(ingredient))
        .toList();

    return finalIngredients.isNotEmpty ? finalIngredients.join(", ") : "None";
  }

  Stream<QuerySnapshot> _fetchOrders() {
    Query query = FirebaseFirestore.instance.collection('orders');

    if (filterStatus != "All") {
      query = query.where('status', isEqualTo: filterStatus);
    }

    query = query.orderBy('timestamp', descending: true);

    return query.snapshots();
  }

  Future<void> _closeOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'Closed',
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order closed successfully!")),
    );
  }
}

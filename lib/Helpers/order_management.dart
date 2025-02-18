// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> completeOrder(String orderId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  await firestore.collection('orders').doc(orderId).update({
    'status': 'Closed',
    'completedAt': FieldValue.serverTimestamp(),
  });

  QuerySnapshot carts = await firestore
      .collection('orders')
      .doc(orderId)
      .collection('cart')
      .get();
  for (var doc in carts.docs) {
    await doc.reference.delete();
  }

  print("Order $orderId completed. All carts cleared.");
}

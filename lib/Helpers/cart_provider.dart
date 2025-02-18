import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  String? _currentOrderId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> get items => _cartItems;
  String? get currentOrderId => _currentOrderId;

  void setCurrentOrderId(String orderId) {
    _currentOrderId = orderId;
    loadCart(orderId);
  }

  Future<void> loadCart(String orderId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    _currentOrderId = orderId;

    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('cart')
        .get();

    _cartItems = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    notifyListeners();
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    if (_currentOrderId == null) return;

    DocumentReference docRef = await _firestore
        .collection('orders')
        .doc(_currentOrderId)
        .collection('cart')
        .add(item);

    item['id'] = docRef.id;
    _cartItems.add(item);
    notifyListeners();
  }

  Future<void> removeFromCart(String itemId) async {
    if (_currentOrderId == null) return;

    await _firestore
        .collection('orders')
        .doc(_currentOrderId)
        .collection('cart')
        .doc(itemId)
        .delete();

    _cartItems.removeWhere((item) => item['id'] == itemId);
    notifyListeners();
  }

  Future<void> clearCart() async {
    if (_currentOrderId == null) return;

    QuerySnapshot snapshot = await _firestore
        .collection('orders')
        .doc(_currentOrderId)
        .collection('cart')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    _cartItems.clear();
    notifyListeners();
  }
}

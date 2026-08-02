import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String title;
  final String storeName;
  final String storeId;
  final int priceIQD;
  int qty;

  CartItem({
    required this.id,
    required this.title,
    required this.storeName,
    required this.storeId,
    required this.priceIQD,
    this.qty = 1,
  });
}

class CartService {
  static final CartService instance = CartService._internal();
  CartService._internal();

  final List<CartItem> _items = [];

  final ValueNotifier<int> cartChangeNotifier = ValueNotifier<int>(0);

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItemsCount {
    int count = 0;
    for (var item in _items) {
      count += item.qty;
    }
    return count;
  }

  int get subtotalIQD {
    int total = 0;
    for (var item in _items) {
      total += item.priceIQD * item.qty;
    }
    return total;
  }

  // Prevents duplicate entries: Increments quantity if already exists!
  void addItem({
    required String id,
    required String title,
    required String storeName,
    required String storeId,
    required int priceIQD,
    int qty = 1,
  }) {
    final index = _items.indexWhere((item) => item.title == title || item.id == id);
    if (index >= 0) {
      _items[index].qty += qty;
    } else {
      _items.add(
        CartItem(
          id: id,
          title: title,
          storeName: storeName,
          storeId: storeId,
          priceIQD: priceIQD,
          qty: qty,
        ),
      );
    }
    cartChangeNotifier.value++;
  }

  void updateQuantity(int index, int newQty) {
    if (index >= 0 && index < _items.length) {
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].qty = newQty;
      }
      cartChangeNotifier.value++;
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      cartChangeNotifier.value++;
    }
  }

  void clearCart() {
    _items.clear();
    cartChangeNotifier.value++;
  }
}

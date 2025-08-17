import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/medicine_model.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => {..._items};
  List<CartItem> get cartItems => _items.values.toList();
  
  int get itemCount => _items.length;
  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';

  bool get isEmpty => _items.isEmpty;

  void addItem(Medicine medicine, {int quantity = 1}) {
    if (_items.containsKey(medicine.id)) {
      _items.update(
        medicine.id,
        (existingItem) => CartItem(
          medicine: existingItem.medicine,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        medicine.id,
        () => CartItem(medicine: medicine, quantity: quantity),
      );
    }
    notifyListeners();
  }

  void removeItem(int medicineId) {
    _items.remove(medicineId);
    notifyListeners();
  }

  void updateQuantity(int medicineId, int quantity) {
    if (quantity <= 0) {
      removeItem(medicineId);
    } else if (_items.containsKey(medicineId)) {
      _items.update(
        medicineId,
        (existingItem) => CartItem(
          medicine: existingItem.medicine,
          quantity: quantity,
        ),
      );
      notifyListeners();
    }
  }

  void incrementQuantity(int medicineId) {
    if (_items.containsKey(medicineId)) {
      final currentItem = _items[medicineId]!;
      updateQuantity(medicineId, currentItem.quantity + 1);
    }
  }

  void decrementQuantity(int medicineId) {
    if (_items.containsKey(medicineId)) {
      final currentItem = _items[medicineId]!;
      updateQuantity(medicineId, currentItem.quantity - 1);
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool contains(int medicineId) {
    return _items.containsKey(medicineId);
  }

  int getQuantity(int medicineId) {
    return _items[medicineId]?.quantity ?? 0;
  }

  CartItem? getItem(int medicineId) {
    return _items[medicineId];
  }

  List<Map<String, dynamic>> getOrderItems() {
    return _items.values.map((item) => {
      'medicine_id': item.medicine.id,
      'quantity': item.quantity,
    }).toList();
  }
} 
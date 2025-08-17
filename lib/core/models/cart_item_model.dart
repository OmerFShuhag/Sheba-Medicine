import 'medicine_model.dart';

class CartItem {
  final Medicine medicine;
  final int quantity;

  CartItem({
    required this.medicine,
    required this.quantity,
  });

  double get totalPrice => medicine.price * quantity;
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  CartItem copyWith({
    Medicine? medicine,
    int? quantity,
  }) {
    return CartItem(
      medicine: medicine ?? this.medicine,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.medicine.id == medicine.id;
  }

  @override
  int get hashCode => medicine.id.hashCode;

  @override
  String toString() {
    return 'CartItem(medicine: ${medicine.name}, quantity: $quantity)';
  }
} 
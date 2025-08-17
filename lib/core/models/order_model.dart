import 'medicine_model.dart';

class OrderItem {
  final int id;
  final Medicine medicine;
  final int quantity;
  final double price;

  OrderItem({
    required this.id,
    required this.medicine,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    
    Map<String, dynamic> medicineData;
    if (json['medicine_details'] != null) {
      medicineData = json['medicine_details'];
    } else if (json['medicine'] != null) {
      medicineData = json['medicine'];
    } else {
      throw Exception('No medicine data found in order item');
    }

    
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return OrderItem(
      id: json['id'] ?? 0,
      medicine: Medicine.fromJson(medicineData),
      quantity: json['quantity'] ?? 0,
      price: parsePrice(json['price']),
    );
  }

  double get totalPrice => price * quantity;
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'OrderItem(medicine: ${medicine.name}, quantity: $quantity, price: $price)';
  }
}

class Order {
  final int id;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String shippingAddress;
  final String phoneNumber;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? itemCount;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.itemCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    
    double parseTotalAmount(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    
    String parsePaymentStatus(dynamic value) {
      if (value == null) return 'pending';
      if (value is bool) return value ? 'paid' : 'pending';
      if (value is String) return value;
      return 'pending';
    }

    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      items:
          (json['items'] as List<dynamic>?)?.map((item) {
            return OrderItem.fromJson(item);
          }).toList() ??
          [],
      totalAmount: parseTotalAmount(
        json['total_price'] ?? json['total_amount'],
      ),
      status: json['status'] ?? 'pending',
      paymentStatus: parsePaymentStatus(json['payment_status']),
      shippingAddress: json['shipping_address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cash_on_delivery',
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      itemCount: json['item_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'items': items
          .map(
            (item) => {
              'id': item.id,
              'medicine': item.medicine.toJson(),
              'quantity': item.quantity,
              'price': item.price,
            },
          )
          .toList(),
      'total_amount': totalAmount,
      'status': status,
      'payment_status': paymentStatus,
      'shipping_address': shippingAddress,
      'phone_number': phoneNumber,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'item_count': itemCount,
    };
  }

  String get formattedTotalAmount => '\$${totalAmount.toStringAsFixed(2)}';
  int get totalItems {
    if (items.isEmpty && itemCount != null) {
      return itemCount!;
    }
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  bool get isPaid => paymentStatus == 'paid';
  bool get isPaymentPending => paymentStatus == 'pending';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case 'pending':
        return 'Payment Pending';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Payment Failed';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, totalAmount: $totalAmount, status: $status)';
  }
}

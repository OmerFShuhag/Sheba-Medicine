import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Order> get ordersByStatus {
    final Map<String, List<Order>> grouped = {};
    for (final order in _orders) {
      grouped.putIfAbsent(order.status, () => []).add(order);
    }
    return grouped.values.expand((orders) => orders).toList();
  }

  Future<void> loadOrders({
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        _setLoading(true);
      }
      _error = null;
      final ordersData = await _apiService.getOrders(
        status: status,
        paymentStatus: paymentStatus,
        startDate: startDate,
        endDate: endDate,
      );


      _orders = ordersData.map((json) {
        return Order.fromJson(json);
      }).toList();

    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
    }
  }

  Future<void> loadOrderDetails(int orderId) async {
    try {
      _setLoading(true);
      _error = null;

      final orderData = await _apiService.getOrderDetails(orderId);
      _currentOrder = Order.fromJson(orderData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createOrder({
    required String shippingAddress,
    required String phoneNumber,
    required String paymentMethod,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final orderData = {
        'shipping_address': shippingAddress,
        'phone_number': phoneNumber,
        'payment_method': paymentMethod,
        'notes': notes,
        'items': items,
      };

      final response = await _apiService.createOrder(orderData);

      _currentOrder = Order.fromJson(response);

      _orders.insert(0, _currentOrder!);

      return true;
    } catch (e) {

      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    await loadOrders(showLoading: false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

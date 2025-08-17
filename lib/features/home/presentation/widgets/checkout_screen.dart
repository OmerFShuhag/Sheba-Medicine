import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/providers/order_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/cart_item_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash_on_delivery';

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _addressController.text = user.address;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final success = await orderProvider.createOrder(
      shippingAddress: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      items: cartProvider.getOrderItems(),
    );

    if (success && mounted) {
      cartProvider.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place order'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Order Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...cartProvider.cartItems.map(
                        (item) => _buildOrderItem(item),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Text(
                            'Total (${cartProvider.totalQuantity} items):',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            cartProvider.formattedTotalAmount,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Delivery Information
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Information',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter delivery address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Payment Method
                        Text(
                          'Payment Method',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Row(
                                  children: [
                                    Icon(Icons.money),
                                    SizedBox(width: 8),
                                    Text('Cash on Delivery'),
                                  ],
                                ),
                                value: 'cash_on_delivery',
                                groupValue: _paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _paymentMethod = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Notes (Optional)',
                            prefixIcon: Icon(Icons.note_outlined),
                            hintText:
                                'Any special instructions for delivery...',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // Place Order Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Consumer<OrderProvider>(
                      builder: (context, orderProvider, child) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: orderProvider.isLoading
                                ? null
                                : _placeOrder,
                            icon: orderProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.shopping_cart_checkout),
                            label: Text(
                              orderProvider.isLoading
                                  ? 'Placing Order...'
                                  : 'Place Order',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Medicine Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryLightColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.medicine.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.medicine.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medical_services,
                          size: 25,
                          color: AppTheme.primaryColor,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.medical_services,
                    size: 25,
                    color: AppTheme.primaryColor,
                  ),
          ),
          const SizedBox(width: 12),

          // Medicine Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.medicine.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity}x ${item.medicine.formattedPrice}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            item.formattedTotalPrice,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

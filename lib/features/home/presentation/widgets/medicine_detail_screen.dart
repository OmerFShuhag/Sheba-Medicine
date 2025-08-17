import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/medicine_model.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;

  const MedicineDetailScreen({
    super.key,
    required this.medicine,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.medicine.name),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              final isInCart = cartProvider.contains(widget.medicine.id);
              return IconButton(
                icon: Icon(
                  isInCart ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  color: isInCart ? Colors.white : null,
                ),
                onPressed: () {
                  if (isInCart) {
                    Navigator.of(context).pushNamed('/cart');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medicine Image
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.primaryLightColor.withOpacity(0.1),
              ),
              child: widget.medicine.imageUrl != null
                  ? Image.network(
                      widget.medicine.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.medical_services,
                            size: 100,
                            color: AppTheme.primaryColor,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.medical_services,
                        size: 100,
                        color: AppTheme.primaryColor,
                      ),
                    ),
            ),

            // Medicine Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.medicine.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        widget.medicine.formattedPrice,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Manufacturer
                  Text(
                    'by ${widget.medicine.manufacturer}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.medicine.isInStock
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.medicine.isInStock
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: widget.medicine.isInStock
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.medicine.stockStatus,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: widget.medicine.isInStock
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.medicine.description.isNotEmpty
                        ? widget.medicine.description
                        : 'No description available for this medicine.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Medicine Information
                  _buildInfoSection('Category', widget.medicine.category),
                  _buildInfoSection('Stock Quantity', '${widget.medicine.stockQuantity} units'),
                  if (widget.medicine.expiryDate != null)
                    _buildInfoSection(
                      'Expiry Date',
                      '${widget.medicine.expiryDate!.day}/${widget.medicine.expiryDate!.month}/${widget.medicine.expiryDate!.year}',
                    ),
                  if (widget.medicine.requiresPrescription)
                    _buildInfoSection(
                      'Prescription Required',
                      'Yes',
                      icon: Icons.warning,
                      iconColor: AppTheme.warningColor,
                    ),
                  const SizedBox(height: 24),

                  // Quantity Selector
                  if (widget.medicine.isInStock) ...[
                    Text(
                      'Quantity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1 ? () {
                            setState(() {
                              _quantity--;
                            });
                          } : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryLightColor.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _quantity < widget.medicine.stockQuantity ? () {
                            setState(() {
                              _quantity++;
                            });
                          } : null,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryLightColor.withOpacity(0.1),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total: \$${(_quantity * widget.medicine.price).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Add to Cart Button
                  if (widget.medicine.isInStock)
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        final isInCart = cartProvider.contains(widget.medicine.id);
                        final cartQuantity = cartProvider.getQuantity(widget.medicine.id);
                        
                        return Column(
                          children: [
                            if (isInCart) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLightColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$cartQuantity in cart',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/cart');
                                      },
                                      child: const Text('View Cart'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            ElevatedButton.icon(
                              onPressed: () {
                                cartProvider.addItem(widget.medicine, quantity: _quantity);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Added ${_quantity}x ${widget.medicine.name} to cart',
                                    ),
                                    backgroundColor: AppTheme.successColor,
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.of(context).pushNamed('/cart');
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart),
                              label: Text(
                                isInCart ? 'Add More to Cart' : 'Add to Cart',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'This medicine is currently out of stock',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: iconColor ?? AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
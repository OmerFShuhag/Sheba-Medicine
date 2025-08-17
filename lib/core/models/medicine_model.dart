class Medicine {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String manufacturer;
  final String category;
  final String? imageUrl;
  final bool requiresPrescription;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.manufacturer,
    required this.category,
    this.imageUrl,
    this.requiresPrescription = false,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    // Handle price as string or number
    double parsePrice(dynamic price) {
      if (price == null) return 0.0;
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) {
        return double.tryParse(price) ?? 0.0;
      }
      return 0.0;
    }

    return Medicine(
      id: json['id'],
      name: json['name'],
      description: json['generic_name'] ?? json['description'] ?? '',
      price: parsePrice(json['price']),
      stockQuantity: json['is_in_stock'] == true
          ? 999
          : 0,
      manufacturer: json['manufacturer'] ?? '',
      category:
          json['category'] ?? 'General', 
      imageUrl: json['image'],
      requiresPrescription: json['requires_prescription'] ?? false,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock_quantity': stockQuantity,
      'manufacturer': manufacturer,
      'category': category,
      'image_url': imageUrl,
      'requires_prescription': requiresPrescription,
      'expiry_date': expiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 10;
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get stockStatus {
    if (!isInStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    String? manufacturer,
    String? category,
    String? imageUrl,
    bool? requiresPrescription,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medicine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Medicine(id: $id, name: $name, price: $price, stock: $stockQuantity)';
  }
}

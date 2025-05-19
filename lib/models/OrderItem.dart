class OrderItem {
  final String productId;
  final String? productVariantId;
  final String productName;
  final String variantName;
  final int quantity;
  final double price;
  final List<String> productItemIds;

  OrderItem({
    required this.productId,
    this.productVariantId,
    required this.productName,
    required this.variantName,
    required this.quantity,
    required this.price,
    this.productItemIds = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'],
    productVariantId: json['productVariantId'],
    productName: json['productName'],
    variantName: json['variantName'],
    quantity: json['quantity'],
    price: (json['price'] as num).toDouble(),
    productItemIds: List<String>.from(json['productItemIds'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    if (productVariantId != null) 'productVariantId': productVariantId,
    'productName': productName,
    'variantName': variantName,
    'quantity': quantity,
    'price': price,
    'productItemIds': productItemIds,
  };
}

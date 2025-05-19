class CartItem {
  final String productId;
  final String? productVariantId;
  int quantity;

  CartItem({
    required this.productId,
    this.productVariantId,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      productVariantId: json['productVariantId'] as String?,
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'productId': productId,
      'quantity': quantity,
    };
    if (productVariantId != null) {
      map['productVariantId'] = productVariantId;
    }
    return map;
  }
  factory CartItem.empty() => CartItem(
    productId: '',
    productVariantId: null,
    quantity: 0,
  );

}

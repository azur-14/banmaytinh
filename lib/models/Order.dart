import 'OrderItem.dart';
import 'OrderStatusHistory.dart';
import 'ShippingAddress.dart';

class Order {
  final String id;
  final String? userId;
  final String orderNumber;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode; // Nullable, giữ giống C#
  final int loyaltyPointsUsed;
  final int loyaltyPointsEarned;
  final int shippingFee;
  String status;
  List<OrderStatusHistory> statusHistory;
  final DateTime createdAt;
  DateTime updatedAt;

  Order({
    required this.id,
    this.userId,
    required this.orderNumber,
    required this.shippingAddress,
    required this.items,
    required this.totalAmount,
    this.discountAmount = 0,
    this.couponCode, // Có thể null
    this.loyaltyPointsUsed = 0,
    this.loyaltyPointsEarned = 0,
    this.shippingFee = 30000,
    this.status = 'pending',
    required this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['_id'] ?? json['id'], // Có thể là _id hoặc id
    userId: json['userId'],
    orderNumber: json['orderNumber'],
    shippingAddress: ShippingAddress.fromJson(json['shippingAddress']),
    items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
    couponCode: json.containsKey('couponCode') ? json['couponCode'] : null,
    loyaltyPointsUsed: json['loyaltyPointsUsed'] ?? 0,
    loyaltyPointsEarned: json['loyaltyPointsEarned'] ?? 0,
    shippingFee: json['shippingFee'] ?? 30000,
    status: json['status'] ?? 'pending',
    statusHistory: (json['statusHistory'] as List)
        .map((e) => OrderStatusHistory.fromJson(e)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'orderNumber': orderNumber,
    'shippingAddress': shippingAddress.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'discountAmount': discountAmount,
    // Luôn gửi couponCode, có thể là '' hoặc null nếu không có
    'couponCode': couponCode ?? '',
    'loyaltyPointsUsed': loyaltyPointsUsed,
    'loyaltyPointsEarned': loyaltyPointsEarned,
    'shippingFee': shippingFee,
    'status': status,
    'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

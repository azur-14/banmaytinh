class Coupon {
  final String? id;
  final String code;
  final int discountValue;
  final int usageLimit;
  final int usageCount;
  final DateTime createdAt;
  final List<String> orderIds;

  Coupon({
    this.id,
    required this.code,
    required this.discountValue,
    required this.usageLimit,
    required this.usageCount,
    required this.createdAt,
    required this.orderIds,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      code: json['code'],
      discountValue: json['discountValue'],
      usageLimit: json['usageLimit'],
      usageCount: json['usageCount'],
      createdAt: DateTime.parse(json['createdAt']),
      orderIds: List<String>.from(json['orderIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'code': code,
      'discountValue': discountValue,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'createdAt': createdAt.toIso8601String(),
      'orderIds': orderIds,
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id as Object;
    }
    return map;
  }
}

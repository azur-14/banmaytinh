
/// History record for an order's status changes.
class OrderStatusHistory {
  final String status;
  final DateTime timestamp;

  OrderStatusHistory({
    required this.status,
    required this.timestamp,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) =>
      OrderStatusHistory(
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };
}
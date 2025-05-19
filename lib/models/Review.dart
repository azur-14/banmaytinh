// lib/models/review.dart

class Review {
  final String id;
  final String productId;
  final String? userId;
  final String? guestName;
  final String comment;
  final int? rating;
  final String? sentiment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.productId,
    this.userId,
    this.guestName,
    required this.comment,
    this.rating,
    this.sentiment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      productId: json['productId'] as String,
      userId: json['userId'] as String?,
      guestName: json['guestName'] as String?,
      comment: json['comment'] as String,
      rating: json['rating'] != null ? (json['rating'] as num).toInt() : null,
      sentiment: json['sentiment'] as String?, // <- Thêm dòng này
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      if (userId != null)    'userId': userId,
      if (guestName != null) 'guestName': guestName,
      'comment': comment,
      if (rating != null)    'rating': rating,
      if (sentiment != null) 'sentiment': sentiment, // <- Thêm dòng này
      'createdAt': createdAt.toIso8601String(),
    };
  }

}

class ShippingAddress {
  final String receiverName;
  final String phoneNumber;
  final String addressLine;
  final String ward;
  final String district;
  final String city;
  final String email; // <-- thêm trường này

  ShippingAddress({
    required this.receiverName,
    required this.phoneNumber,
    required this.addressLine,
    required this.ward,
    required this.district,
    required this.city,
    required this.email, // <-- thêm vào constructor
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) => ShippingAddress(
    receiverName: json['receiverName'],
    phoneNumber: json['phoneNumber'],
    addressLine: json['addressLine'],
    ward: json['ward'],
    district: json['district'],
    city: json['city'],
    email: json['email'], // <-- bổ sung khi parse từ JSON
  );

  Map<String, dynamic> toJson() => {
    'receiverName': receiverName,
    'phoneNumber': phoneNumber,
    'addressLine': addressLine,
    'ward': ward,
    'district': district,
    'city': city,
    'email': email, // <-- thêm khi convert sang JSON
  };
}

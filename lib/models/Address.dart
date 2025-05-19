// lib/models/Address.dart

class Address {
  String receiverName;
  String phone;
  String addressLine;
  String? commune;
  String? district;
  String? city;
  bool isDefault;
  DateTime createdAt;

  Address({
    required this.receiverName,
    required this.phone,
    required this.addressLine,
    this.commune,
    this.district,
    this.city,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    receiverName: j['receiverName'] as String,
    phone: j['phone'] as String,
    addressLine: j['addressLine'] as String,
    commune: j['commune'] as String?,
    district: j['district'] as String?,
    city: j['city'] as String?,
    isDefault: j['isDefault'] as bool? ?? false,
    createdAt: j['createdAt'] != null
        ? DateTime.parse(j['createdAt'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'receiverName': receiverName,
    'phone': phone,
    'addressLine': addressLine,
    'commune': commune,
    'district': district,
    'city': city,
    'isDefault': isDefault,
    // omit createdAt on POST/PUT, server will set it
  };

  Address copyWith({
    String? receiverName,
    String? phone,
    String? addressLine,
    String? commune,
    String? district,
    String? city,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      receiverName: receiverName ?? this.receiverName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      commune: commune ?? this.commune,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

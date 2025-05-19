import 'package:flutter/material.dart';

class CardInfo {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;

  CardInfo({
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
  });

  // Optional: Add methods to convert to/from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cardHolderName': cardHolderName,
    };
  }

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo(
      cardNumber: json['cardNumber'],
      expiryDate: json['expiryDate'],
      cardHolderName: json['cardHolderName'],
    );
  }
}
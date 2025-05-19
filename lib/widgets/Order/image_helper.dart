import 'dart:convert';
import 'package:flutter/material.dart';

Widget imageFromBase64String(
    String base64String, {
      double? width,
      double? height,
      ImageProvider<Object>? placeholder,
    }) {
  try {
    // Decode the base64 string into bytes
    final bytes = base64Decode(base64String);
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return placeholder != null
            ? Image(
          image: placeholder,
          width: width,
          height: height,
          fit: BoxFit.cover,
        )
            : Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  } catch (e) {
    // If decoding fails, return the placeholder or a broken image icon
    return placeholder != null
        ? Image(
      image: placeholder,
      width: width,
      height: height,
      fit: BoxFit.cover,
    )
        : Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
// lib/utils/image_helper.dart

import 'dart:convert';
import 'package:flutter/material.dart';

/// Create an Image widget from a Base64 string or asset path.
/// If [url] is null or empty, returns the [placeholder] instead.
/// Supports both Base64 strings and asset paths (e.g., 'assets/placeholder.jpg').
Image imageFromBase64String(
    String? url, {
      double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
      ImageProvider<Object>? placeholder,
    }) {
  if (url == null || url.isEmpty) {
    return Image(
      image: placeholder ?? const AssetImage('assets/placeholder.jpg'),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading placeholder: $error');
        return Image(image: const AssetImage('assets/placeholder.jpg'), width: width, height: height, fit: fit);
      },
    );
  }

  // Handle asset paths (e.g., 'assets/placeholder.jpg')
  if (url.startsWith('assets/')) {
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading asset $url: $error');
        return Image(image: placeholder ?? const AssetImage('assets/placeholder.jpg'), width: width, height: height, fit: fit);
      },
    );
  }

  // Handle Base64 strings
  try {
    final bytes = base64Decode(url);
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error decoding Base64 $url: $error');
        return Image(image: placeholder ?? const AssetImage('assets/placeholder.jpg'), width: width, height: height, fit: fit);
      },
    );
  } catch (e) {
    debugPrint('Exception decoding Base64 $url: $e');
    return Image(
      image: placeholder ?? const AssetImage('assets/placeholder.jpg'),
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Return an [ImageProvider] from a Base64 string (e.g., for use in DecorationImage).
ImageProvider memoryImageProvider(String base64String) {
  try {
    final bytes = base64Decode(base64String);
    if (bytes.isEmpty) {
      throw Exception('Base64 string decoded to empty bytes');
    }
    return MemoryImage(bytes);
  } catch (e) {
    debugPrint('Exception decoding Base64 for MemoryImage: $e');
    // Throwing an exception or returning a default provider is better than an empty Uint8List
    throw Exception('Failed to decode Base64 string: $e');
    // Alternatively, you can return a default placeholder if needed
    // return const AssetImage('assets/placeholder.jpg');
  }
}
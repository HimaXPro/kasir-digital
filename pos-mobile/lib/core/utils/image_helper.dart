import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider getImageProvider(String imageUrl) {
  if (imageUrl.startsWith('data:image')) {
    final base64String = imageUrl.split(',').last;
    return MemoryImage(base64Decode(base64String));
  }
  return NetworkImage(imageUrl);
}

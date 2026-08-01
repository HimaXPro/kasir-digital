import 'dart:convert';
import 'package:flutter/material.dart';

final Map<String, ImageProvider> _imageCache = {};

ImageProvider getImageProvider(String imageUrl) {
  if (_imageCache.containsKey(imageUrl)) {
    return _imageCache[imageUrl]!;
  }

  ImageProvider provider;
  if (imageUrl.startsWith('data:image')) {
    final base64String = imageUrl.split(',').last;
    provider = MemoryImage(base64Decode(base64String));
  } else {
    provider = NetworkImage(imageUrl);
  }
  
  _imageCache[imageUrl] = provider;
  return provider;
}

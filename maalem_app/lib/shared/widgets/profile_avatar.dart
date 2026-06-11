import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/api_client.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double size;
  final double borderRadius;
  final Color backgroundColor;
  final Color textColor;
  final TextStyle? textStyle;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.imageBytes,
    this.size = 48,
    this.borderRadius = 999,
    this.backgroundColor = AppColors.navy,
    this.textColor = Colors.white,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: imageProvider == null
            ? Center(
                child: Text(
                  _initials(name),
                  style: textStyle ??
                      TextStyle(
                        color: textColor,
                        fontSize: size * 0.34,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              )
            : Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
      ),
    );
  }

  ImageProvider? _imageProvider() {
    if (imageBytes != null) return MemoryImage(imageBytes!);

    final source = imageUrl?.trim();
    if (source == null || source.isEmpty) return null;

    if (source.startsWith('data:image')) {
      final commaIndex = source.indexOf(',');
      if (commaIndex == -1) return null;
      try {
        return MemoryImage(base64Decode(source.substring(commaIndex + 1)));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(_resolveImageUrl(source));
  }

  String _resolveImageUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '${ApiClient.baseUrl}$value';
    return '${ApiClient.baseUrl}/$value';
  }

  String _initials(String value) {
    if (value.trim().isEmpty) return '?';
    final parts = value.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

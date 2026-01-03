import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

/// Custom search bar widget
class CustomSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search songs, artists, albums...',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: context.colors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

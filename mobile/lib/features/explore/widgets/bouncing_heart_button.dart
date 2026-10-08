import 'package:flutter/material.dart';

/// Saving state changes only after the server confirms the action.
class BouncingHeartButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  final double size;
  final Color activeColor;
  final bool useHeartIcon;
  const BouncingHeartButton({
    super.key,
    required this.isSaved,
    required this.onTap,
    this.size = 34,
    this.activeColor = const Color(0xFFE11D48),
    this.useHeartIcon = true,
  });
  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: isSaved ? 'Bỏ lưu địa điểm' : 'Lưu địa điểm',
    onPressed: onTap,
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    style: IconButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: isSaved
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface,
    ),
    icon: Icon(
      useHeartIcon
          ? (isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded)
          : (isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
      size: size * .54,
    ),
  );
}

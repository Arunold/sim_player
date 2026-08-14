import 'package:flutter/material.dart';

import '../../../core/constants/theme_constants.dart';

/// Reusable section header for settings
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Reusable settings tile
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? context.colors.error : null;

    return ListTile(
      leading: Icon(icon, color: color ?? context.colors.textSecondary),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      onTap: onTap,
    );
  }
}

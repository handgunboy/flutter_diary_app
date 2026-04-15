import 'package:flutter/material.dart';

class SettingsActionItem {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsActionItem({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class SettingsActionGroupCard extends StatelessWidget {
  final List<SettingsActionItem> items;

  const SettingsActionGroupCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _ActionTile(item: items[i]),
            if (i < items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final SettingsActionItem item;

  const _ActionTile({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: item.iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }
}

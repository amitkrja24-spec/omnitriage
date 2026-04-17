import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      color: AppTheme.warningAmber.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppTheme.warningAmber, size: 16),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              'Connection lost — showing last known data. Reconnecting...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.warningAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'All clear right now',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentGreen,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'No open tasks. Field workers can report via @OmniTriageBot',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLG),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.textMuted),
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('View completed tasks'),
          ),
        ],
      ),
    );
  }
}

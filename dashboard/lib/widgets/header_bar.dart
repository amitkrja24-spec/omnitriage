import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../screens/volunteer_roster_screen.dart';
import '../screens/reports_screen.dart';

class HeaderBar extends StatefulWidget {
  const HeaderBar({super.key});

  @override
  State<HeaderBar> createState() => _HeaderBarState();
}

class _HeaderBarState extends State<HeaderBar>
    with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      color: AppTheme.surface,
      child: Row(
        children: [
          // ── Logo + NGO name
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text('✚',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              const Text(
                'OmniTriage',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              const Text('·', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                'Asha Foundation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
          const Spacer(),
          // ── Live indicator
          Row(
            children: [
              FadeTransition(
                opacity: _pulseAnim,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.liveGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.liveGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingLG),
          // ── Clock
          Text(
            timeStr,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: AppTheme.spacingLG),
          // ── Volunteer Roster button
          TextButton.icon(
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            icon: const Icon(Icons.people_outline,
                size: 16, color: AppTheme.textSecondary),
            label: const Text(
              'Volunteer Roster',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          // ── Reports button
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppTheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const SizedBox(
                  height: 600,
                  child: ReportsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart,
                size: 16, color: AppTheme.textSecondary),
            label: const Text(
              'Reports',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          // ── Avatar
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.border,
            child: Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

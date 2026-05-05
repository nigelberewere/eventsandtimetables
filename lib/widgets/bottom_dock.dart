import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/theme_provider.dart';
import '../widgets/notification_provider.dart';

class BottomDock extends StatelessWidget {
  final int currentIndex;

  const BottomDock({
    super.key,
    required this.currentIndex,
  });

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/events');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/timetables');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/notifications');
        break;
    }
  }

  Widget _buildItem(
    BuildContext context,
    ThemeProvider theme,
    NotificationProvider notificationProvider,
    int index,
    IconData icon,
    String label,
  ) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _navigate(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? (theme.isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05))
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Stack(
                children: [
                  Icon(
                    icon,
                    color: isActive
                        ? theme.accentColor
                        : theme.textColor.withOpacity(0.4),
                  ),

                  // 🔴 BADGE ONLY FOR NOTIFICATIONS TAB
                  if (index == 4 && notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? theme.textColor
                    : theme.textColor.withOpacity(0.5),
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final notificationProvider =
        context.watch<NotificationProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: theme.isDark
                    ? theme.surfaceColor.withOpacity(0.7)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: theme.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(theme.isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  _buildItem(
                      context, theme, notificationProvider, 0, Icons.event, "Events"),
                  _buildItem(
                      context, theme, notificationProvider, 1, Icons.schedule, "Timetable"),
                  _buildItem(
                      context, theme, notificationProvider, 2, Icons.person, "Profile"),
                  _buildItem(
                      context, theme, notificationProvider, 3, Icons.settings, "Settings"),
                  _buildItem(
                      context, theme, notificationProvider, 4, Icons.notifications, "Notifications"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
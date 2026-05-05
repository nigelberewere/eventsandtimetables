import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../pages/theme_provider.dart';
import '../widgets/bottom_dock.dart';
import '../widgets/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  
  List notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

 

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
  title: const Text("Notifications"),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushReplacementNamed(context, '/home');
    },
  ),
),
bottomNavigationBar: const BottomDock(currentIndex: 4),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (_, i) {
          final n = notifications[i];

          return ListTile(
            title: Text(n['title']),
            subtitle: Text(n['message']),
            trailing: n['is_read']
                ? null
                : const Icon(Icons.circle, color: Colors.red, size: 10),
            onTap: () => markAsRead(n['id']),
          );
        },
      ),
    );
  }
}
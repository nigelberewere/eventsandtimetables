import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final supabase = Supabase.instance.client;
  List notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user!.id)
        .order('created_at', ascending: false);

    setState(() => notifications = data);
  }

  Future<void> markAsRead(String id) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);

    final provider =
        Provider.of<NotificationProvider>(context, listen: false);

    await provider.fetchUnreadCount();

    fetchNotifications();
  }

  // 🔥 NEW: Show popup dialog
  void showNotificationPopup(Map notification) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            notification['title'] ?? "Notification",
            style: TextStyle(color: theme.textColor),
          ),
          content: Text(
            notification['message'] ?? "",
            style: TextStyle(color: theme.textColor.withOpacity(0.8)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
              ),
              onPressed: () async {
                await markAsRead(notification['id']);
                Navigator.pop(context); // close popup
              },
              child: Text(
                "Seen",
                style: TextStyle(color: theme.textColor),
              ),
            ),
          ],
        );
      },
    );
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

      body: notifications.isEmpty
          ? Center(
              child: Text(
                "No notifications",
                style: TextStyle(color: theme.textColor.withOpacity(0.6)),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];

                return ListTile(
                  title: Text(
                    n['title'] ?? '',
                    style: TextStyle(color: theme.textColor),
                  ),
                  subtitle: Text(
                    n['message'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.7),
                    ),
                  ),
                  trailing: n['is_read']
                      ? null
                      : const Icon(Icons.circle, color: Colors.red, size: 10),

                  // 🔥 UPDATED TAP
                  onTap: () => showNotificationPopup(n),
                );
              },
            ),
    );
  }
}
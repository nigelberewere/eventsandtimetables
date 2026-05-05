import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart' ;
import 'admin_broadcast.dart';

class ManageNotificationsPage extends StatefulWidget {
  const ManageNotificationsPage({super.key});

  @override
  State<ManageNotificationsPage> createState() => _ManageNotificationsPageState();
}

class _ManageNotificationsPageState extends State<ManageNotificationsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = false;

 

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Manage Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: tp.accentColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tp.accentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Control Center',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Turn channels on/off and manage templates before broadcasting notices.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildChannelCard(
            tp,
            title: 'Push Notifications',
            subtitle: 'In-app and device push alerts',
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          _buildChannelCard(
            tp,
            title: 'Email Digest',
            subtitle: 'Weekly updates and reminders',
            value: _emailEnabled,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
          _buildChannelCard(
            tp,
            title: 'SMS Alerts',
            subtitle: 'Urgent notification channel',
            value: _smsEnabled,
            onChanged: (v) => setState(() => _smsEnabled = v),
          ),
          const SizedBox(height: 24),
          Text(
            'Templates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: tp.textColor,
            ),
          ),
          
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminBroadcastPage()),
           );
        },
        backgroundColor: tp.accentColor,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('Create Broadcast', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildChannelCard(
    ThemeProvider tp, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tp.accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: tp.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: tp.textColor.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: tp.accentColor.withOpacity(0.4),
            activeThumbColor: tp.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(ThemeProvider tp, Map<String, String> template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tp.accentColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tp.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.mark_email_unread_rounded,
              color: tp.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: tp.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template['description']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: tp.textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template editor coming soon.')),
              );
            },
            icon: Icon(Icons.edit_rounded, color: tp.accentColor),
          ),
        ],
      ),
    );
  }
}
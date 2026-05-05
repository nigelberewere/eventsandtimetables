import 'package:flutter/material.dart';

import 'package:provider/provider.dart'; // 1. Added Provider import
import 'theme_provider.dart'; // 2. Adjust this path to your file
import 'home.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  bool _notificationsEnabled = true;
  final bool _eventReminders = true;
  bool isLoading = true;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  

  @override
  Widget build(BuildContext context) {
    // 3. Initialize the theme provider access
    final theme = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: theme.accentColor)),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor, // ✅ Dynamic BG
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Keep white for AppBar contrast
          ),
        ),
        backgroundColor: theme.isDark ? theme.surfaceColor : const Color(0xFF1B2631), // Use surface or deep blue
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(theme), // Pass theme

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account Information', theme),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    theme: theme,
                    icon: Icons.person,
                    label: 'Full Name',
                    value: profile?['full_name'] ?? 'N/A',
                  ),

                  const SizedBox(height: 12),

                  _buildInfoCard(
                    theme: theme,
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: profile?['email'] ?? 'N/A',
                  ),

                  const SizedBox(height: 12),

                  _buildInfoCard(
                    theme: theme,
                    icon: Icons.location_city_rounded,
                    label: 'Program',
                    value: profile?['program'] ?? 'N/A',
                  ),

                  const SizedBox(height: 32),

                  _buildSectionTitle('Preferences', theme),
                  const SizedBox(height: 16),

                                  

                  const SizedBox(height: 12),

                  _buildPreferenceToggle(
                    theme: theme,
                    title: 'Enable Notifications',
                    subtitle: 'Receive alerts about updates',
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                    icon: Icons.notifications,
                  ),

                  const SizedBox(height: 40),

                  _buildActionButtons(context, theme),

                  const SizedBox(height: 32),

                  Center(
                    child: Text(
                      'App Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      decoration: BoxDecoration(
        color: theme.isDark ? theme.surfaceColor : const Color(0xFF1B2631),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.accentColor.withOpacity(0.2),
            child: Icon(Icons.person, size: 60, color: theme.accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            profile?['full_name'] ?? 'Student',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.accentColor, // Use accent for titles
      ),
    );
  }

  Widget _buildPreferenceToggle({
    required ThemeProvider theme,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: theme.accentColor),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 14, 
                color: theme.textColor)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: theme.textColor.withOpacity(0.7))),
        trailing: Switch.adaptive(
          value: value,
          activeColor: theme.accentColor,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.accentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.isDark ? Colors.grey : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        color: theme.textColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
        style: FilledButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: theme.isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
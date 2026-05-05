import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme_provider.dart';
import 'login.dart';
import 'home.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  
  Future<void> _handleLogout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the dynamic theme properties
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: theme.isDark ? theme.surfaceColor : theme.accentColor,
        elevation: 0,
        centerTitle: true,
        // Ensure text/icons in AppBar are visible
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // 🌗 THEME TOGGLE
          SwitchListTile(
            title: Text(
              "Dark Mode",
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "Switch between light and dark themes",
              style: TextStyle(color: theme.textColor.withOpacity(0.6)),
            ),
            value: theme.isDark,
            activeThumbColor: theme.accentColor,
            secondary: Icon(
              theme.isDark ? Icons.dark_mode : Icons.light_mode,
              color: theme.isDark ? theme.accentColor : Colors.orange,
            ),
            onChanged: (value) {
              theme.toggleTheme(value);
            },
          ),

          Divider(color: theme.textColor.withOpacity(0.1)),
        
          
          // 🚪 LOGOUT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () => _handleLogout(context),
          ),

          Divider(color: theme.textColor.withOpacity(0.1)),

          // ℹ️ APP VERSION
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.textColor),
            title: Text("App Version", style: TextStyle(color: theme.textColor)),
            subtitle: Text("v1.0.0", style: TextStyle(color: theme.textColor.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }
}
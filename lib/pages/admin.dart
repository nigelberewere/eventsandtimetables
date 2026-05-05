import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'theme_provider.dart';
import '../main.dart';
Timer? _pollingTimer;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}
RealtimeChannel? _logsChannel;
class _AdminPageState extends State<AdminPage> {
 
  
  

 

  List<dynamic> logs = [];

  @override
  void initState() {
    super.initState();
    
  }
  @override
@override
void dispose() {
  _pollingTimer?.cancel(); 
 
}
  

  

 

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: theme.accentColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

              // 🔥 HEADER STATS (LIVE FROM SUPABASE)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ⚡ QUICK ACTIONS 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _action(
                      context,
                      theme,
                      "Add Event",
                      "Create campus event",
                      Icons.event,
                      () => Navigator.pushNamed(context, addEventRoute),
                    ),

                    const SizedBox(height: 10),

                     _action(
                      context,
                      theme,
                      "Update Event",
                      "Edit existing event",
                      Icons.event,
                      () => Navigator.pushNamed(context, updateEventRoute),
                    ),

                     const SizedBox(height: 10),

                    _action(
                      context,
                      theme,
                      "Add Class",
                      "Schedule lecture",
                      Icons.school,
                      () => Navigator.pushNamed(context, addClassRoute),
                    ),

                    const SizedBox(height: 10),

                    _action(
                      context,
                      theme,
                      "Update Class",
                      "Edit existing class",
                      Icons.edit,
                      () => Navigator.pushNamed(context, updateClassRoute),
                    ),

                     const SizedBox(height: 10),

                    _action(
                      context,
                      theme,
                      "Notifications",
                      "Send alerts",
                      Icons.notifications,
                      () => Navigator.pushNamed(context, manageNotificationsRoute),
                    ),

                    const SizedBox(height: 10),

                    _action(
                      context,
                      theme,
                      "Users",
                      "Manage accounts",
                      Icons.people,
                      () => Navigator.pushNamed(context, manageUsersRoute),
                    ),
                    const SizedBox(height: 10),

                    _action(
  context,
  theme,
  "Logout",
  "Sign out of admin panel",
  Icons.logout,
  () => _logout(context),
),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 📊 RECENT ACTIVITY (REAL DATA)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (logs.isEmpty)
                      Text(
                        "No recent activity",
                        style: TextStyle(color: theme.textColor.withOpacity(0.5)),
                      )
                    else
                      ...logs.map((log) {
                        return Card(
                          color: theme.surfaceColor,
                          child: ListTile(
                            leading: Icon(Icons.history, color: theme.accentColor),
                            title: Text(
                              "${log['action']} ${log['entity']}",
                              style: TextStyle(color: theme.textColor),
                            ),
                            subtitle: Text(
                              log['created_at'],
                              style: TextStyle(
                                color: theme.textColor.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 STATS CARD
  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  // ⚡ QUICK ACTION TILE
  Widget _action(
    BuildContext context,
    ThemeProvider theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: theme.textColor.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
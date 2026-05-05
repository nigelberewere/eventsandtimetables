import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'theme_provider.dart';
import '../widgets/bottom_dock.dart';
import '../widgets/notification_provider.dart';

StreamSubscription? _logSubscription;
StreamSubscription? _broadcastSub;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  String get todayName {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return days[DateTime.now().weekday - 1];
  }

  // ✅ Simplified — no manual provider call, realtime handles badge

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('notifications').insert({
      'user_id': user.id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  final Set<String> sentReminders = {};

  double getProgress(DateTime start, DateTime end) {
    final total = end.difference(start).inSeconds;
    final passed = now.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (passed / total).clamp(0.0, 1.0);
  }

  List events = [];
  List timetable = [];
  String? userProgram;
  String? userName;
  String? userYear;
  String? studentId;

  bool isLoading = true;
  DateTime now = DateTime.now();
  Timer? timer;

  DateTime _combineDateAndTime(String time) {
    final today = DateTime.now();
    final date = today.toIso8601String().split('T')[0];
    return DateTime.parse("${date}T$time");
  }

  @override
  void initState() {
    super.initState();
    fetchData();

    // ✅ Timer only updates clock and checks reminders — no manual badge fetch
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => now = DateTime.now());
      checkClassReminders();
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _broadcastSub?.cancel();
    timer?.cancel();
    super.dispose();
  }

  void checkClassReminders() {
    for (var c in timetable) {
      final start = _combineDateAndTime(c['start_time']);
      final diff = start.difference(now).inMinutes;

      final key30 = "${c['id']}_30";
      final key15 = "${c['id']}_15";
      final key0 = "${c['id']}_start";

      // 30 min reminder
      if (diff == 30 && !sentReminders.contains(key30)) {
        addNotification(
          title: "Class Reminder",
          message: "${c['course_name']} starts in 30 minutes",
          type: "reminder",
        );
        sentReminders.add(key30);
      }

      // 15 min reminder
      if (diff == 15 && !sentReminders.contains(key15)) {
        addNotification(
          title: "Class Reminder",
          message: "${c['course_name']} starts in 15 minutes",
          type: "reminder",
        );
        sentReminders.add(key15);
      }

      // Class started
      if (now.isAfter(start) &&
          now.isBefore(_combineDateAndTime(c['end_time'])) &&
          !sentReminders.contains(key0)) {
        addNotification(
          title: "Class Started",
          message: "${c['course_name']} has started now",
          type: "class",
        );
        sentReminders.add(key0);
      }
    }
  }

  void listenToAdminLogs() {
    _logSubscription = supabase
        .from('admin_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((logs) async {
          // ✅ async added
          if (logs.isEmpty) return;

          final latest = logs.first;
          final action = latest['action'];
          final entity = latest['entity'] ?? '';

          if ((action == 'Updated Class' || action == 'Deleted Class') &&
              entity.contains(userProgram ?? '') &&
              entity.contains(userYear ?? '')) {
            final title = "Admin Update";
            final message = "$entity has been $action";

            // ✅ Check before showing popup
            final alreadySeen = await _notificationAlreadyExists(
              title: title,
              message: message,
              type: "admin",
            );

            if (alreadySeen) return;

            await addNotification(
              title: title,
              message: message,
              type: "admin",
            );

            _showAdminPopup(action, entity);
          }
        });
  }

  void _showAdminPopup(String action, String entity) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Admin Update"),
          content: Text("$entity has been $action.\n\nTap to view timetable."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/timetable');
              },
              child: const Text("View Timetable"),
            ),
          ],
        );
      },
    );
  }

  void listenToBroadcasts() {
    _broadcastSub = supabase
        .from('broadcasts')
        .stream(primaryKey: ['id'])
        .listen((data) async {
          //
          if (data.isEmpty) return;

          final latest = data.last;

          final programMatch =
              latest['target_program'] == null ||
              latest['target_program'] == userProgram;

          final yearMatch =
              latest['target_year'] == null ||
              latest['target_year'] == userYear;

          final isGlobal =
              latest['target_program'] == null && latest['target_year'] == null;

          if (isGlobal || (programMatch && yearMatch)) {
            final title = latest['title'] as String;
            final message = latest['message'] as String;

            //  Check before showing popup
            final alreadySeen = await _notificationAlreadyExists(
              title: title,
              message: message,
              type: 'broadcast',
            );

            if (alreadySeen) return; //

            await addNotification(
              title: title,
              message: message,
              type: 'broadcast',
            );

            _showPopup(title, message);
          }
        });
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
            child: const Text("View"),
          ),
        ],
      ),
    );
  }

  Future<void> fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        debugPrint("⚠️ Profile not found");
        return;
      }

      userProgram = profile['program'];
      userName = profile['full_name'];
      userYear = profile['year'];
      studentId = profile['student_id'];

      if (userProgram == null || userYear == null) {
        debugPrint("⚠️ Missing program or year in profile");
        return;
      }

      final eventsData = await supabase.from('events').select().order('date');

      final timetableData = await supabase
          .from('timetables')
          .select()
          .eq('program', userProgram!)
          .eq('year', userYear!);

      timetable = timetableData;

      timetable.sort((a, b) {
        final aTime = _combineDateAndTime(a['start_time']);
        final bTime = _combineDateAndTime(b['start_time']);
        return aTime.compareTo(bTime);
      });

      listenToAdminLogs();
      listenToBroadcasts();

      setState(() {
        events = eventsData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ fetchData error: $e");
      setState(() => isLoading = false);
    }
  }

  // ✅ Returns true if this exact notification was already inserted before
  Future<bool> _notificationAlreadyExists({
    required String title,
    required String message,
    required String type,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final existing = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .eq('title', title)
        .eq('message', message)
        .eq('type', type)
        .limit(1);

    return existing.isNotEmpty;
  }

  Map<String, dynamic>? getClassStatus() {
    final todayClasses = timetable.where((c) {
      return c['day'].toString().toLowerCase() == todayName.toLowerCase();
    }).toList();

    todayClasses.sort((a, b) {
      final aTime = _combineDateAndTime(a['start_time']);
      final bTime = _combineDateAndTime(b['start_time']);
      return aTime.compareTo(bTime);
    });

    for (var c in todayClasses) {
      final start = _combineDateAndTime(c['start_time']);
      final end = _combineDateAndTime(c['end_time']);

      if (now.isAfter(start) && now.isBefore(end)) {
        return {
          'type': 'current',
          'subject': c['course_name'],
          'room': c['venue'],
          'start': start,
          'end': end,
        };
      }

      if (now.isBefore(start)) {
        return {
          'type': 'next',
          'subject': c['course_name'],
          'room': c['venue'],
          'start': start,
          'end': end,
        };
      }
    }

    return null;
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final todayClasses = timetable.where((c) {
      return c['day'].toString().toLowerCase() == todayName.toLowerCase();
    }).toList();

    final classStatus = getClassStatus();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Campus Events And Timetables"),
        centerTitle: true,
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        foregroundColor: theme.textColor,
      ),

      // ✅ const removed — allows provider to trigger rebuilds
      bottomNavigationBar: BottomDock(currentIndex: 0),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName ?? "",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${userProgram ?? ""} • ${userYear ?? ""}",
              style: TextStyle(color: theme.accentColor),
            ),
            const SizedBox(height: 20),

            _card(
              theme: theme,
              child: classStatus == null
                  ? Text(
                      "You're free 🎉",
                      style: TextStyle(color: theme.textColor.withOpacity(0.7)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classStatus['type'] == 'current'
                              ? "Ongoing Class"
                              : "Next Class",
                          style: TextStyle(color: theme.accentColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          classStatus['subject'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        Text(
                          "Room: ${classStatus['room']}",
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          classStatus['type'] == 'current'
                              ? "Ends in: ${formatDuration(classStatus['end'].difference(now))}"
                              : "Starts in: ${formatDuration(classStatus['start'].difference(now))}",
                          style: TextStyle(
                            color: classStatus['type'] == 'current'
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (classStatus['type'] == 'current') ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 500),
                              tween: Tween(
                                begin: 0,
                                end: getProgress(
                                  classStatus['start'],
                                  classStatus['end'],
                                ),
                              ),
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor: Colors.white10,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.greenAccent,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            Text(
              "Today's Lectures ($todayName)",
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: todayClasses.map((c) {
                  final start = _combineDateAndTime(c['start_time']);
                  final end = _combineDateAndTime(c['end_time']);
                  final isCurrent = now.isAfter(start) && now.isBefore(end);

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _card(
                      theme: theme,
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['course_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${c['start_time']} - ${c['end_time']}",
                            style: TextStyle(
                              color: theme.accentColor,
                              fontSize: 12,
                            ),
                          ),
                          if (isCurrent)
                            const Text(
                              "LIVE",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "Quick Actions",
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _quick(theme, "ID", Icons.badge, onTap: () => _showStudentID()),
                _quick(
                  theme,
                  "Rooms",
                  Icons.meeting_room,
                  onTap: () => _showRooms(),
                ),
                _quick(
                  theme,
                  "Alerts",
                  Icons.notifications,
                  onTap: () => _showAlerts(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              "Events That Have Been Recommended For YOU",
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ...events.take(3).map((e) {
              final dt = DateTime.parse(e['date']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _card(
                  theme: theme,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['title'],
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${dt.day}/${dt.month} • ${e['location']}",
                        style: TextStyle(color: theme.accentColor),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required ThemeProvider theme,
    required Widget child,
    double? width,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: theme.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _quick(
    ThemeProvider theme,
    String label,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: _card(
            theme: theme,
            child: Column(
              children: [
                Icon(icon, color: theme.accentColor),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(color: theme.textColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentID() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.deepPurpleAccent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  userName ?? "Unknown",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Student ID: ${studentId ?? 'N/A'}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRooms() {
    final rooms = timetable.map((c) => c['venue'] as String).toSet().toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text("Your Program Rooms"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: rooms.length,
              itemBuilder: (_, i) {
                return ListTile(
                  leading: const Icon(Icons.meeting_room),
                  title: Text(rooms[i]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAlerts() {
    final upcoming = timetable
        .where((c) {
          final start = _combineDateAndTime(c['start_time']);
          return start.isAfter(now);
        })
        .take(3)
        .toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Upcoming Alerts"),
          content: upcoming.isEmpty
              ? const Text("No upcoming classes 🎉")
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: upcoming.map((c) {
                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(c['course_name']),
                      subtitle: Text(c['start_time']),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}

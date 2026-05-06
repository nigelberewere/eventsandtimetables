import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import '../widgets/bottom_dock.dart';
import 'home.dart';

class TimetablesPage extends StatefulWidget {
  const TimetablesPage({super.key});

  @override
  State<TimetablesPage> createState() => _TimetablesPageState();
}

class _TimetablesPageState extends State<TimetablesPage> {
  final supabase = Supabase.instance.client;

  String _selectedView = 'Day';
  String _selectedDay = 'Monday';

  List<Map<String, dynamic>> _classes = [];
  String? userProgram;
  String? userYear;
  bool isLoading = true;

  final List<String> _fullWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _fullWeek[DateTime.now().weekday - 1];
    fetchTimetable();
  }

  

  Color _getColor(String subject) {
    final colors = [
      const Color(0xFF5E88B0), // Soft Blue
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.green.shade400,
    ];
    return colors[subject.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _getClassesForDay(String day) {
    return _classes.where((cls) => cls['day'] == day).toList()
      ..sort((a, b) => a['startTime'].compareTo(b['startTime']));
  }

  double _parseTime(String time) {
    final parts = time.split(":");
    return int.parse(parts[0]) + (int.parse(parts[1]) / 60);
  }

  String _getStatus(Map<String, dynamic> c) {
    final now = TimeOfDay.now();
    final current = now.hour + (now.minute / 60);
    final start = _parseTime(c['startTime']);
    final end = _parseTime(c['endTime']);

    if (current >= start && current <= end) return "🟢 Ongoing";
    if (current < start) return "🔵 Upcoming";
    return "⚫ Completed";
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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Timetable'),
        backgroundColor: theme.isDark ? theme.surface : theme.accentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()),
          ),
        ),
      ),
      bottomNavigationBar: const BottomDock(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: fetchTimetable,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: theme.isDark ? theme.surface : theme.accentColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Schedule',
                        style: TextStyle(color: theme.text, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
  "${userProgram ?? ""} • ${userYear ?? ""}",
  style: TextStyle(color: theme.text.withOpacity(0.7)),
),
                  ],
                ),
              ),

              // VIEW SWITCH
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: theme.accentColor,
                    selectedForegroundColor: Colors.white,
                    backgroundColor: theme.surfaceColor,
                    foregroundColor: theme.textColor,
                  ),
                  segments: const [
                    ButtonSegment(value: 'Day', label: Text('Day')),
                    ButtonSegment(value: 'Week', label: Text('Week')),
                  ],
                  selected: {_selectedView},
                  onSelectionChanged: (s) => setState(() => _selectedView = s.first),
                ),
              ),

              _buildDayPicker(theme),

              const SizedBox(height: 10),

              _selectedView == 'Day' ? _buildTimelineView(theme) : _buildWeekView(theme),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayPicker(ThemeProvider theme) {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fullWeek.length,
        itemBuilder: (context, index) {
          final day = _fullWeek[index];
          final isSelected = day == _selectedDay;

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected ? theme.accentColor : theme.surfaceColor,
                boxShadow: isSelected ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                day.substring(0, 3),
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineView(ThemeProvider theme) {
    final classes = _getClassesForDay(_selectedDay);
    if (classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 80, color: theme.textColor.withOpacity(0.2)),
            const SizedBox(height: 10),
            Text("No classes today", style: TextStyle(fontSize: 16, color: theme.textColor.withOpacity(0.5))),
          ],
        ),
      );
    }

    const double startHour = 8;
    const double endHour = 20;
    const double hourHeight = 70;

    return SizedBox(
      height: (endHour - startHour) * hourHeight,
      child: Stack(
        children: [
          // GRID
          Column(
            children: List.generate((endHour - startHour).toInt(), (index) {
              return SizedBox(
                height: hourHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Center(
                        child: Text("${(startHour + index).toInt()}:00",
                            style: TextStyle(fontSize: 12, color: theme.textColor.withOpacity(0.5))),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.isDark ? Colors.white10 : Colors.grey.shade300)),
                  ],
                ),
              );
            }),
          ),
          // EVENTS
          ...classes.map((c) {
            final start = _parseTime(c['startTime']);
            final end = _parseTime(c['endTime']);
            return Positioned(
              top: (start - startHour) * hourHeight,
              left: 60, right: 10,
              child: Container(
                height: (end - start) * hourHeight,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (c['color'] as Color).withOpacity(theme.isDark ? 0.8 : 1.0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['subject'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("${c['startTime']} - ${c['endTime']} • ${c['room']}", 
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeekView(ThemeProvider theme) {
  const double startHour = 8;
  const double endHour = 20;
  const double hourHeight = 70;
  const double dayWidth = 120;
  const double timeColumnWidth = 60;

  final totalHeight = (endHour - startHour) * hourHeight;

  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  double parseTime(String time) {
    final parts = time.split(":");
    return int.parse(parts[0]) + (int.parse(parts[1]) / 60);
  }

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      child: SizedBox(
        width: timeColumnWidth + (dayWidth * days.length),
        height: totalHeight,
        child: Stack(
          children: [
            // 🔥 GRID BACKGROUND (time rows + day columns)
            Row(
              children: [
                // TIME COLUMN
                SizedBox(
                  width: timeColumnWidth,
                  child: Column(
                    children: List.generate(
                      (endHour - startHour).toInt(),
                      (i) {
                        final hour = startHour + i;
                        return SizedBox(
                          height: hourHeight,
                          child: Text(
                            "${hour.toInt()}:00",
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.isDark
                                  ? Colors.white54
                                  : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // DAY COLUMNS
                ...days.map(
                  (day) => Container(
                    width: dayWidth,
                    height: totalHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.isDark
                              ? Colors.white10
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🔥 EVENTS (GOOGLE CALENDAR STYLE BLOCKS)
            ...days.asMap().entries.expand((entry) {
              final dayIndex = entry.key;
              final dayName = entry.value;

              final dayEvents = _classes
                  .where((c) => c['day'].toString().startsWith(dayName))
                  .toList();

              return dayEvents.map((event) {
                final start = parseTime(event['startTime']);
                final end = parseTime(event['endTime']);

                final top = (start - startHour) * hourHeight;
                final height = (end - start) * hourHeight;

                return Positioned(
                  top: top,
                  left: timeColumnWidth + (dayIndex * dayWidth) + 4,
                  width: dayWidth - 8,
                  child: Container(
                    height: height,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: event['color'],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['subject'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${event['startTime']} - ${event['endTime']}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          event['room'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }),
          ],
        ),
      ),
    ),
  );
}
}
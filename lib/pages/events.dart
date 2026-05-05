import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'addEvent.dart';
import 'home.dart';
import '../widgets/bottom_dock.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];
  final supabase = Supabase.instance.client;

  DateTime? _getStartDate() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    // Create the stream query
    final query = supabase.from('events').stream(primaryKey: ['id']).order('date');

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: theme.isDark ? theme.surfaceColor : theme.accentColor,
        elevation: 0,
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
      bottomNavigationBar: const BottomDock(currentIndex: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.isDark ? theme.surfaceColor : theme.accentColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Events',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                          backgroundColor: theme.isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
                          selectedColor: theme.isDark ? theme.accentColor : const Color(0xFFFFBF00),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter ? Colors.white : theme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: query,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', 
                    style: TextStyle(color: theme.textColor)),
                  );
                }

                final startDate = _getStartDate();
                
                // SAFE DATA HANDLING: Check if snapshot.data is null before using it
                final rawData = snapshot.data ?? [];
                
                final events = rawData.where((event) {
                  // Skip events that are missing a date to prevent crash in DateTime.parse
                  if (event['date'] == null) return false;
                  
                  if (startDate == null) return true;
                  
                  try {
                    final eventDate = DateTime.parse(event['date']);
                    return eventDate.isAfter(startDate.subtract(const Duration(seconds: 1)));
                  } catch (e) {
                    return false; // Skip if date format is invalid
                  }
                }).toList();

                if (events.isEmpty) {
                  return Center(
                    child: Text("No events found for this period.", 
                    style: TextStyle(color: theme.textColor.withOpacity(0.6))),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEventCard(events[index], theme),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const AddEventPage())),
        backgroundColor: theme.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, ThemeProvider theme) {
    return Card(
      elevation: theme.isDark ? 0 : 4,
      color: theme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEventDetails(event, theme),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event['title'] ?? 'Untitled Event', // Null fallback
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                  ),
                  _buildCategoryBadge(event['category'] ?? 'General'),
                ],
              ),
              const SizedBox(height: 12),
              // All IconText widgets now have null fallbacks
              _buildIconText(Icons.calendar_today, event['date'] ?? 'No Date', theme),
              const SizedBox(height: 8),
              _buildIconText(Icons.access_time, event['time'] ?? 'No Time', theme),
              const SizedBox(height: 8),
              _buildIconText(Icons.location_on, event['location'] ?? 'No Location', theme),
              const SizedBox(height: 12),
              Text(
                event['description'] ?? 'No description provided.',
                style: TextStyle(fontSize: 14, height: 1.4, color: theme.textColor.withOpacity(0.8)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, ThemeProvider theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.accentColor),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, color: theme.textColor.withOpacity(0.7))),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Academic': return const Color(0xFF5E88B0);
      case 'Sports': return Colors.green;
      case 'Career': return Colors.orange;
      case 'Cultural': return Colors.purple;
      case 'Workshop': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showEventDetails(Map<String, dynamic> event, ThemeProvider theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceColor,
        title: Text(event['title'] ?? 'Event Details', style: TextStyle(color: theme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${event['date'] ?? "N/A"}', style: TextStyle(color: theme.textColor)),
            Text('Time: ${event['time'] ?? "N/A"}', style: TextStyle(color: theme.textColor)),
            Text('Location: ${event['location'] ?? "N/A"}', style: TextStyle(color: theme.textColor)),
            const SizedBox(height: 12),
            Text(event['description'] ?? 'No description provided.', 
              style: TextStyle(color: theme.textColor.withOpacity(0.8))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Close', style: TextStyle(color: theme.accentColor))
          ),
        ],
      ),
    );
  }
}
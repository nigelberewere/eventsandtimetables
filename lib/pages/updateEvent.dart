import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_provider.dart';

class UpdateEventPage extends StatefulWidget {
  const UpdateEventPage({super.key});

  @override
  State<UpdateEventPage> createState() => _UpdateEventPageState();
}

class _UpdateEventPageState extends State<UpdateEventPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> events = [];
  bool isLoading = false;
  String searchQuery = "";

  final categories = [
    'Academic', 'Sports', 'Career', 'Cultural', 'Workshop', 'Social', 'Other','General',
  ];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);

    final data = await supabase
        .from('events')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      events = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredEvents {
    if (searchQuery.isEmpty) return events;

    return events.where((e) {
      return e['title']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();
  }

  void _openEditDialog(Map<String, dynamic> e) {
  final title = TextEditingController(text: e['title']);
  final description = TextEditingController(text: e['description']);
  final location = TextEditingController(text: e['location']);
  final organizer = TextEditingController(text: e['organizer']);
  final attendees = TextEditingController(text: e['attendees'].toString());
  final date = TextEditingController(text: e['date']);
  final start = TextEditingController(text: e['start_time']);
  final end = TextEditingController(text: e['end_time']);

  // FIX: Ensure the value exists in the categories list before assigning it
  String category = categories.contains(e['category']) 
      ? e['category'] 
      : 'General'; // Default to General if not found

  showDialog(
    context: context,
    builder: (dialogContext) { // Use a unique name for dialog context
      final theme = Provider.of<ThemeProvider>(context, listen: false);

      return StatefulBuilder( // Use StatefulBuilder to allow dropdown to update
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: theme.surfaceColor,
            title: const Text("Edit Event"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _field(theme, title, "Title"),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: theme.textColor))))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() => category = v!);
                    },
                    dropdownColor: theme.surfaceColor,
                    decoration: InputDecoration(
                      labelText: "Category",
                      labelStyle: TextStyle(color: theme.textColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _field(theme, description, "Description"),
                  const SizedBox(height: 10),
                  _field(theme, location, "Location"),
                  const SizedBox(height: 10),
                  _field(theme, organizer, "Organizer"),
                  const SizedBox(height: 10),
                  _field(theme, attendees, "Attendees"),
                  const SizedBox(height: 10),
                  _field(theme, date, "Date"),
                  const SizedBox(height: 10),
                  _field(theme, start, "Start Time"),
                  const SizedBox(height: 10),
                  _field(theme, end, "End Time"),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await supabase.from('events').delete().eq('id', e['id']);


await supabase.from('admin_logs').insert({
  'action': 'Deleted Event',
  'entity': "${e['title']} (${e['category']})",
  'created_at': DateTime.now().toIso8601String(),
});

Navigator.pop(context);
fetchEvents();
                 
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                 await supabase.from('events').update({
  'title': title.text,
  'description': description.text,
  'location': location.text,
  'organizer': organizer.text,
  'attendees': int.tryParse(attendees.text) ?? 0,
  'category': category,
  'date': date.text,
  'start_time': start.text,
  'end_time': end.text,
}).eq('id', e['id']);

// 🔥 ADMIN LOG - UPDATE EVENT
await supabase.from('admin_logs').insert({
  'action': 'Updated Event',
  'entity': "${title.text} ($category)",
  'created_at': DateTime.now().toIso8601String(),
});

Navigator.pop(context);
fetchEvents();
                },
                child: const Text("Update"),
              ),
            ],
          );
        }
      );
    },
  );
}

  Widget _field(ThemeProvider theme, TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text("Manage Events"),
        backgroundColor: theme.accentColor,
      ),

      body: Column(
        children: [

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search events...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 📅 GRID
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                    ? Center(
                        child: Text(
                          "No events found",
                          style: TextStyle(color: theme.textColor),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: filteredEvents.length,
                        itemBuilder: (_, i) {
                          final e = filteredEvents[i];

                          return GestureDetector(
                            onTap: () => _openEditDialog(e),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                  const Spacer(),
                                  Text(
                                    e['category'] ?? '',
                                    style: TextStyle(
                                      color: theme.accentColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    e['date'] ?? '',
                                    style: TextStyle(
                                      color: theme.textColor.withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
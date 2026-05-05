import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_provider.dart';

class UpdateClassPage extends StatefulWidget {
  const UpdateClassPage({super.key});

  @override
  State<UpdateClassPage> createState() => _UpdateClassPageState();
}

class _UpdateClassPageState extends State<UpdateClassPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> classes = [];
  bool isLoading = false;

  String selectedProgram = "Computer Science";
  String selectedYear = "1.1 August";
  String searchQuery = "";

 final programs = [
  'Accounting',
  'Actuarial Science',
  'Agribusiness and Economics',
  'Agricultural Engineering',
  'Agricultural Genetics and Cell Technology',
  'Agricultural Information Technology',
  'Applied Biology and Biochemistry',
  'Applied Mathematics',
  'Applied Physics',
  'Architectural Studies',
  'Banking',
  'Biotechnology',
  'Business Analytics',
  'Chemical Engineering',
  'Computer Science',
  'Economics and Econometrics',
  'Electronic Engineering',
  'Environmental Science and Health',
  'Fibre and Polymer Materials Engineering',
  'Finance',
  'Forest Resources and Wildlife Management',
  'Geographical Information Systems and Remote Sensing',
  'Industrial and Manufacturing Engineering',
  'Informatics',
  'Journalism and Media Studies',
  'Operations Research and Statistics',
  'Property Development and Estate Management',
  'Public Health',
  'Quantity Surveying',
  'Radiography',
  'Risk Management and Insurance',
  'Sustainable Food Production',
];

 final years = [
  '1.1 August', '1.2 August', '1.1 March', '1.2 March',
  '2.1 August', '2.2 August', '2.1 March', '2.2 March',
  '3.1 March', '3.2 March', '3.1 August', '3.2 August',
  '4.1 March', '4.2 March', '4.1 August', '4.2 August',
  '5.1 March', '5.2 March', '5.1 August', '5.2 August',
];
  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    setState(() => isLoading = true);

    final data = await supabase
        .from('timetables')
        .select()
        .eq('program', selectedProgram)
        .eq('year', selectedYear);

    setState(() {
      classes = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredClasses {
    if (searchQuery.isEmpty) return classes;

    return classes.where((c) {
      return c['course_name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();
  }

  void _openEditDialog(Map<String, dynamic> c) {
    final course = TextEditingController(text: c['course_name']);
    final venue = TextEditingController(text: c['venue']);
    final instructor = TextEditingController(text: c['instructor']);

    String day = c['day'];
    String start = c['start_time'];
    String end = c['end_time'];
    int credits = c['credits'] ?? 3;

    showDialog(
      context: context,
      builder: (_) {
        final theme = context.read<ThemeProvider>();

        return AlertDialog(
          backgroundColor: theme.surfaceColor,
          title: const Text("Edit Class"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _field(theme, course, "Course Name"),
                const SizedBox(height: 10),
                _field(theme, venue, "Venue"),
                const SizedBox(height: 10),
                _field(theme, instructor, "Instructor"),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  initialValue: day,
                  items: [
                    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
                  ]
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => day = v!,
                  decoration: const InputDecoration(labelText: "Day"),
                ),

                const SizedBox(height: 10),

                _timeField("Start Time", start, (v) => start = v),
                const SizedBox(height: 10),
                _timeField("End Time", end, (v) => end = v),

                const SizedBox(height: 10),

                DropdownButtonFormField<int>(
                  initialValue: credits,
                  items: [1,2,3,4,5]
                      .map((c) => DropdownMenuItem(value: c, child: Text("$c")))
                      .toList(),
                  onChanged: (v) => credits = v!,
                  decoration: const InputDecoration(labelText: "Credits"),
                ),
              ],
            ),
          ),

          actions: [
            // ❌ DELETE
            TextButton(
              onPressed: () async {
                // 1. Delete class
await supabase
    .from('timetables')
    .delete()
    .eq('id', c['id']);

// 2. Log admin action
await supabase.from('admin_logs').insert({
  'action': 'Deleted Class',
  'entity': "${c['course_name']} (${c['program']} - ${c['year']})",
  'program': c['program'],
  'year': c['year'],
  'created_at': DateTime.now().toIso8601String(),
});

// 3. Get affected students
final students = await supabase
    .from('profiles')
    .select('id')
    .eq('program', c['program'])
    .eq('year', c['year']);

// 4. Send notifications
await supabase.from('notifications').insert(
  students.map((s) {
    return {
      'user_id': s['id'],
      'title': 'Class Removed',
      'message':
          "${c['course_name']} has been removed from your timetable",
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };
  }).toList(),
);
                Navigator.pop(context);
                fetchClasses();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),

            // 💾 UPDATE
            ElevatedButton(
              onPressed: () async {
              // 1. Update class in timetable
await supabase.from('timetables').update({
  'course_name': course.text,
  'venue': venue.text,
  'instructor': instructor.text,
  'day': day,
  'start_time': start,
  'end_time': end,
  'credits': credits,
}).eq('id', c['id']);

// 2. Log admin action
await supabase.from('admin_logs').insert({
  'action': 'Updated Class',
  'entity': "${course.text} (${selectedProgram} - ${selectedYear})",
  'program': selectedProgram,
  'year': selectedYear,
  'created_at': DateTime.now().toIso8601String(),
});

// 3. Get affected students
final students = await supabase
    .from('profiles')
    .select('id')
    .eq('program', selectedProgram)
    .eq('year', selectedYear);

// 4. Notify students
await supabase.from('notifications').insert(
  students.map((s) {
    return {
      'user_id': s['id'],
      'title': 'Class Updated',
      'message':
          "${course.text} timetable has been updated. Check your schedule.",
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    };
  }).toList(),
);
                Navigator.pop(context);
                fetchClasses();
              },
              child: const Text("Update"),
            )
          ],
        );
      },
    );
  }

  Widget _timeField(String label, String initial, Function(String) onChanged) {
    final controller = TextEditingController(text: initial);

    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  Widget _field(ThemeProvider theme, TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: TextStyle(color: theme.textColor),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text("Manage Classes"),
        backgroundColor: theme.accentColor,
      ),

      body: Column(
        children: [

          // 🔍 FILTER SECTION
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: selectedProgram,
                        items: programs
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedProgram = v!);
                          fetchClasses();
                        },
                        decoration: const InputDecoration(labelText: "Program"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: selectedYear,
                        items: years
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(y),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedYear = v!);
                          fetchClasses();
                        },
                        decoration: const InputDecoration(labelText: "Year"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextField(
                  onChanged: (v) => setState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search class...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // 📚 GRID
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredClasses.isEmpty
                    ? Center(
                        child: Text(
                          "No classes found",
                          style: TextStyle(color: theme.textColor),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filteredClasses.length,
                        itemBuilder: (_, i) {
                          final c = filteredClasses[i];

                          return GestureDetector(
                            onTap: () => _openEditDialog(c),
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
                                    c['course_name'],
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    c['day'],
                                    style: TextStyle(
                                      color: theme.accentColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    "${c['start_time']} - ${c['end_time']}",
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
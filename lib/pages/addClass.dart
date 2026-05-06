import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_provider.dart';

class AddClassPage extends StatefulWidget {
  const AddClassPage({super.key});

  @override
  State<AddClassPage> createState() => _AddClassPageState();
}

class _AddClassPageState extends State<AddClassPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _courseController = TextEditingController();
  final _venueController = TextEditingController();
  final _instructorController = TextEditingController();

  String _selectedDay = 'Monday';
  String _selectedProgram = 'Computer Science';

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  int _credits = 3;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

 final List<String> _programs = [
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
  String _selectedYear = '1.1 August';

final List<String> _years = [
  '1.1 August','1.2 August','1.1 March','1.2 March',
  '2.1 August','2.2 August','2.1 March','2.2 March',
  '3.1 August','3.2 August','3.1 March','3.2 March',
  '4.1 August','4.2 August','4.1 March','4.2 March',
  '5.1 August','5.2 August','5.1 March','5.2 March',
];

  @override
  void dispose() {
    _courseController.dispose();
    _venueController.dispose();
    _instructorController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return "$hour:$min:00"; // Supabase TIME format
  }

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final user = supabase.auth.currentUser;

    
    await supabase.from('timetables').insert({
      'program': _selectedProgram,
      'year': _selectedYear,
      'course_name': _courseController.text.trim(),
      'day': _selectedDay,
      'start_time': _formatTime(_startTime),
      'end_time': _formatTime(_endTime),
      'venue': _venueController.text.trim(),
      'instructor': _instructorController.text.trim(),
      'credits': _credits,
    });

    // 
    await supabase.from('admin_logs').insert({
  'action': 'Added Class',
  'entity':
      "${_courseController.text.trim()} ($_selectedProgram - $_selectedYear)",
  'program': _selectedProgram,
  'year': _selectedYear,
  'created_at': DateTime.now().toIso8601String(),
});

// 2. Get all students in that program + year
final students = await supabase
    .from('profiles')
    .select('id')
    .eq('program', _selectedProgram)
    .eq('year', _selectedYear);

// 3. Insert notifications for each student
for (final student in students) {
  await supabase.from('notifications').insert({
    'user_id': student['id'],
    'title': 'New Class Added',
    'message':
        "${_courseController.text.trim()} has been added to your timetable",
    'is_read': false,
    'created_at': DateTime.now().toIso8601String(),
  });
}

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Class added successfully 🎉")),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: tp.backgroundColor,
      appBar: AppBar(
        title: const Text("Add Class"),
        backgroundColor: tp.accentColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // PROGRAM DROPDOWN
              DropdownButtonFormField<String>(
                initialValue: _selectedProgram,
                items: _programs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProgram = v!),
                decoration: _input(tp, "Program", Icons.school),
              ),
              const SizedBox(height: 12),

DropdownButtonFormField<String>(
  initialValue: _selectedYear,
  items: _years
      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
      .toList(),
  onChanged: (v) => setState(() => _selectedYear = v!),
  decoration: _input(tp, "Academic Year", Icons.school_outlined),
),

              const SizedBox(height: 12),

              _field(tp, _courseController, "Course Name", Icons.book),
              const SizedBox(height: 12),

              // DAY
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                items: _days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDay = v!),
                decoration: _input(tp, "Day", Icons.calendar_today),
              ),

              const SizedBox(height: 12),

              // TIMES
              Row(
                children: [
                  Expanded(
                    child: _timeBox(
                      tp,
                      "Start",
                      _startTime.format(context),
                      () => _selectTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _timeBox(
                      tp,
                      "End",
                      _endTime.format(context),
                      () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _field(tp, _venueController, "Venue", Icons.location_on),
              const SizedBox(height: 12),

              _field(tp, _instructorController, "Instructor", Icons.person),

              const SizedBox(height: 20),

              // CREDITS
              Row(
                children: [
                  Text("Credits", style: TextStyle(color: tp.textColor)),
                  const SizedBox(width: 20),
                  DropdownButton<int>(
                    value: _credits,
                    items: [1, 2, 3, 4, 5]
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text("$c"),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _credits = v!),
                  )
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tp.accentColor,
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text(
                    "Save Class",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(ThemeProvider tp, TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
      style: TextStyle(color: tp.textColor),
      decoration: _input(tp, label, icon),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _timeBox(ThemeProvider tp, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _input(tp, label, Icons.access_time),
        child: Text(value, style: TextStyle(color: tp.textColor)),
      ),
    );
  }

  InputDecoration _input(ThemeProvider tp, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: tp.accentColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
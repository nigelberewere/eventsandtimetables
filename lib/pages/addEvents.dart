import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AddEventPage extends StatefulWidget {
  final Map? event; // 
  const AddEventPage({super.key, this.event});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;
  late TextEditingController _attendeesController;
  late TextEditingController _dateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  String _selectedCategory = 'Academic';

  final List<String> _categories = [
    'Academic', 'Sports', 'Career', 'Cultural', 'Workshop', 'Social', 'Other',
  ];

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();

    // 
    _titleController = TextEditingController(text: widget.event?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.event?['description'] ?? '');
    _locationController = TextEditingController(text: widget.event?['location'] ?? '');
    _organizerController = TextEditingController(text: widget.event?['organizer'] ?? '');
    _attendeesController = TextEditingController(
      text: widget.event?['attendees']?.toString() ?? '',
    );
    _dateController = TextEditingController(text: widget.event?['date'] ?? '');
    _startTimeController = TextEditingController(text: widget.event?['start_time'] ?? '');
    _endTimeController = TextEditingController(text: widget.event?['end_time'] ?? '');

    _selectedCategory = widget.event?['category'] ?? 'Academic';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _attendeesController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // --- DATE & TIME ---
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() => _dateController.text = _formatDate(picked));
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => controller.text = picked.format(context));
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

 

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Event' : 'Create Event',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: tp.accentColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              _buildTextField(tp,
                controller: _titleController,
                label: 'Event Title',
                hint: 'Tech Conference',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              _buildCategoryDropdown(tp),

              const SizedBox(height: 16),

              _buildTextField(tp,
                controller: _descriptionController,
                label: 'Description',
                hint: 'Details...',
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              _buildDateField(tp,
                controller: _dateController,
                label: 'Date',
                onTap: () => _selectDate(context),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              _buildTimeField(tp,
                controller: _startTimeController,
                label: 'Start Time',
                onTap: () => _selectTime(context, _startTimeController),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              _buildTimeField(tp,
                controller: _endTimeController,
                label: 'End Time',
                onTap: () => _selectTime(context, _endTimeController),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              _buildTextField(tp,
                controller: _locationController,
                label: 'Location',
                hint: 'Auditorium',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              _buildTextField(tp,
                controller: _organizerController,
                label: 'Organizer',
                hint: 'CS Dept',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              _buildTextField(tp,
                controller: _attendeesController,
                label: 'Attendees',
                hint: '100',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tp.accentColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  isEditing ? 'Update Event' : 'Create Event',
                  style: const TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildTextField(ThemeProvider tp,
      {required TextEditingController controller,
      required String label,
      required String hint,
      int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: tp.textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: tp.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDateField(ThemeProvider tp,
      {required TextEditingController controller,
      required String label,
      required VoidCallback onTap,
      required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildTimeField(ThemeProvider tp,
      {required TextEditingController controller,
      required String label,
      required VoidCallback onTap,
      required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown(ThemeProvider tp) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v!),
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
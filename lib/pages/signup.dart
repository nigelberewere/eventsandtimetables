import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // 1. Added Provider import
import 'theme_provider.dart'; // 2. Adjust this path

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedProgram;
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
  String? _selectedYear;

final List<String> _years = [
  '1.1 August', '1.2 August', '1.1 March', '1.2 March',
  '2.1 August', '2.2 August', '2.1 March', '2.2 March',
  '3.1 March', '3.2 March', '3.1 August', '3.2 August',
  '4.1 March', '4.2 March', '4.1 August', '4.2 August',
  '5.1 March', '5.2 March', '5.1 August', '5.2 August',
];

  final supabase = Supabase.instance.client;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;

      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': _fullNameController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'program': _selectedProgram,
          'year': _selectedYear,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Access the theme
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          _SignupBackdrop(theme: theme), // Pass theme to backdrop
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      // ✅ Glass effect adapts to theme
                      color: theme.isDark 
                          ? theme.surfaceColor.withOpacity(0.8) 
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: theme.isDark ? Colors.white10 : Colors.white70,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(Icons.arrow_back_rounded, color: theme.textColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create your account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor, // ✅ Theme Text
                          ),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'Full name',
                                theme: theme,
                                validator: (value) => value!.isEmpty ? 'Enter full name' : null,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _studentIdController,
                                label: 'Student ID',
                                theme: theme,
                                validator: (value) => value!.isEmpty ? 'Enter student ID' : null,
                              ),
                              const SizedBox(height: 12),
                              
                              // 
                              DropdownButtonFormField<String>(
                                initialValue: _selectedProgram,
                                dropdownColor: theme.surfaceColor, // Important for visibility
                                style: TextStyle(color: theme.textColor),
                                decoration: _inputDecoration('Academic Program', theme).copyWith(
                                  prefixIcon: Icon(Icons.school_outlined, color: theme.accentColor),
                                ),
                                hint: Text('Select your program', style: TextStyle(color: theme.textColor.withOpacity(0.6))),
                                items: _programs.map((String program) {
                                  return DropdownMenuItem<String>(
                                    value: program,
                                    child: Text(program),
                                  );
                                }).toList(),
                                onChanged: (newValue) => setState(() => _selectedProgram = newValue),
                                validator: (value) => value == null ? 'Please select a program' : null,
                              ),
                              const SizedBox(height: 12),

DropdownButtonFormField<String>(
  initialValue: _selectedYear,
  dropdownColor: theme.surfaceColor,
  style: TextStyle(color: theme.textColor),
  decoration: _inputDecoration('Academic Year', theme).copyWith(
    prefixIcon: Icon(Icons.timeline, color: theme.accentColor),
  ),
  hint: Text(
    'Select your year',
    style: TextStyle(color: theme.textColor.withOpacity(0.6)),
  ),
  items: _years.map((year) {
    return DropdownMenuItem(
      value: year,
      child: Text(year),
    );
  }).toList(),
  onChanged: (value) => setState(() => _selectedYear = value),
  validator: (value) => value == null ? 'Please select your year' : null,
),

                              const SizedBox(height: 12),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                theme: theme,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter email';
                                  if (!value.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: theme.textColor),
                                decoration: _inputDecoration('Password', theme).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: theme.accentColor),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 characters' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: TextStyle(color: theme.textColor),
                                decoration: _inputDecoration('Confirm Password', theme).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: theme.accentColor),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: _acceptedTerms,
                                activeColor: theme.accentColor,
                                checkColor: theme.isDark ? Colors.black : Colors.white,
                                onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                                title: Text(
                                  'Accept terms to receive notifications',
                                  style: TextStyle(fontSize: 13, color: theme.textColor),
                                ),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.accentColor,
                                    foregroundColor: theme.isDark ? Colors.black : Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Already have an account?', style: TextStyle(color: theme.accentColor)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Input Decoration to avoid repetition
  InputDecoration _inputDecoration(String label, ThemeProvider theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.textColor.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.accentColor, width: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required ThemeProvider theme,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: theme.textColor),
      decoration: _inputDecoration(label, theme),
      validator: validator,
    );
  }
}

class _SignupBackdrop extends StatelessWidget {
  final ThemeProvider theme;
  const _SignupBackdrop({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // ✅ Background gradient changes based on theme
          colors: theme.isDark 
              ? [const Color(0xFF121212), const Color(0xFF1E1E1E)] 
              : [const Color(0xFFFFF8F0), const Color(0xFFF1E6DA)],
        ),
      ),
    );
  }
}
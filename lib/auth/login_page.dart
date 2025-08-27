import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_page.dart'; // Ensure this path is correct
import 'package:my_app2/services/api_service.dart'; // Add this import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        _phoneNumberController.text.trim(),
        _passwordController.text,
        _codeController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Determine if login is successful
      bool isSuccess = false;
      const successMessage = "Login successful! Navigating to Dashboard...";

      if (response.containsKey('id') ||
          response.containsKey('token') ||
          response.containsKey('success') ||
          (response.containsKey('message') &&
              response['message'].toString().toLowerCase().contains(
                'success',
              )) ||
          (response.containsKey('status') && response['status'] == 'success')) {
        isSuccess = true;
      }

      if (!isSuccess &&
          !response.containsKey('message') &&
          response.isNotEmpty) {
        isSuccess = true;
      }

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(successMessage),
            backgroundColor: Color.fromARGB(255, 66, 230, 72),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Dashboard(loggedInCode: _codeController.text.trim()),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? "Login failed. Please try again.",
            ),
            backgroundColor: const Color.fromARGB(255, 235, 38, 24),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      String errorMessage =
          "Login failed. Please check your connection and try again.";

      if (e.toString().contains('TimeoutException')) {
        errorMessage = "Request timeout. Please check your connection.";
      } else if (e.toString().contains('Network error')) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (e.toString().contains('Invalid phone number or password')) {
        errorMessage = "Invalid phone number, password, or code.";
      } else if (e.toString().contains('Invalid request')) {
        errorMessage = "Invalid request. Please check your input.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Account'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Phone Number
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key), // Fixed: removed asterisk
                  ),
                  keyboardType:
                      TextInputType.text, // Allows both words and digits
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the code';
                    }
                    // Optional: Add minimum length validation
                    if (value.length < 4) {
                      return 'Code must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

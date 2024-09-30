import 'package:flutter/material.dart';
import 'package:lendana/pages/landing_page.dart';
import 'package:lendana/pages/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;
  bool _cameraPermissionGranted = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login successful!'),
        ));

        // Show dialog to confirm camera permission request
        _showCameraPermissionDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Login failed.'),
          ));
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message}'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Unexpected error occurred: $e'),
        ));
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Camera Permission'),
          content: Text(
              'This app requires access to your camera to provide a better experience. Do you want to grant camera permission?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _requestCameraPermission();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();

    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });

    if (_cameraPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Camera permission granted.'),
      ));
      // Navigate to Landing Page after permission is granted
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LandingPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Camera permission denied.'),
      ));
    }
  }

  // Forgot Password
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    try {
      await _supabaseClient.auth.resetPasswordForEmail(_emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reset email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              // Company Logo
              Image.asset(
                'assets/lendana.png',
                height: 100,
              ),
              SizedBox(height: 40),
              // Email TextField with Icon
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Password TextField with Icon
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              // Login Button
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
              SizedBox(height: 20),
              // Forgot Password Button
              TextButton(
                onPressed: _resetPassword,
                child: Text('Forgot Password?'),
              ),
              SizedBox(height: 20),
              // Register Button at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account? '),
                  TextButton(
                    onPressed: () {
                      // Navigate to Register Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

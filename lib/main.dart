import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/landing_page.dart';
import 'package:lendana_admin/pages/login_page.dart';
import 'package:lendana_admin/pages/register_page.dart';
import 'package:lendana_admin/themes/light_mode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_screen.dart'; // Import your splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url:
        'https://diqmnwgzykbfkrnhsrva.supabase.co', // Replace with your Supabase project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpcW1ud2d6eWtiZmtybmhzcnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU5NDIzMzYsImV4cCI6MjA0MTUxODMzNn0.iECRGEBfku8lqlRI3q7SpInjxsLp1E7LbMUQGt3jPPw', // Replace with your Supabase anon key
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/landingpage': (context) => LandingPage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),

        // Add more routes as needed
      },
      title: 'Flutter Registration and Login App',
      theme: lightMode,
      home: SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}

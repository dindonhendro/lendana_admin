import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/loan_page.dart';
import 'package:lendana_admin/pages/card_page.dart';

import 'package:lendana_admin/pages/lengkapi_page.dart';
import 'package:lendana_admin/pages/profile_template_page.dart';
import 'package:lendana_admin/pages/profile_display_page.dart';
import 'package:lendana_admin/pages/profile_page.dart';

import 'package:lendana_admin/pages/save_profile_to_file_page.dart';
import 'package:lendana_admin/pages/storage_page.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    // Home Page
//(),

    // Name & Phone Page
    LengkapiPage(),

    // Profile Page
    LoanPage(),

    // Storage Page
    SaveProfileToFilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('lendana_admin'),
        elevation: 0.0,
        automaticallyImplyLeading: false,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Loan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed, // Keeps labels visible
      ),
    );
  }
}

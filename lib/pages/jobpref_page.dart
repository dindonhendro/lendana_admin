import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../components/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobprefPage extends StatefulWidget {
  @override
  _JobprefPageState createState() => _JobprefPageState();
}

class _JobprefPageState extends State<JobprefPage> {
  final _supabaseClient = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  String? _avatarUrl; // To store and display the avatar URL
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _destCountryController = TextEditingController();
  final _experienceController = TextEditingController();

  String? _selectedEducation;
  String? _selectedOccupation;
  String? _selectedDestCountry;

  final List<String> _educationOptions = [
    'SMK / SMA',
    'D3',
    'S1',
    'S2',
    'Other',
  ];

  final List<String> _occupationOptions = [
    'Perawat Lansia (Kaigo)',
    'Industri Pengolahan Makanan/Minuman',
    'Restoran atau Pelayanan Makanan',
    'Perbaikan dan Pemeliharaan Mobil',
    'Agrikultur ',
    'Pekerjaan Rumah Tangga',
    'Pekerjaan Konstruksi',
    'Pekerjaan Pabrik',
    'Pekerjaan Perhotelan',
    'Pekerjaan Perikanan',
    'Pekerjaan Pertanian',
    'Pekerjaan Perkebunan',
    'Pekerjaan Peternakan',
    'Other',
  ];

  final List<String> _destCountryOptions = [
    'Hongkong',
    'Japan',
    'Korea',
    'Taiwan',
    'Other',
  ];

  bool _isLoading = false;

  // Get the current user's ID
  String get userId => _supabaseClient.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in. Redirecting to login.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      // Fetch user data from the 'users' table
      final response = await _supabaseClient
          .from('users')
          .select('education, occupation, dest_country, experience')
          .eq('user_id', user.id)
          .single();

      // Populate the text fields with the fetched data
      _selectedEducation = response['education'];
      _selectedOccupation = response['occupation'];
      _selectedDestCountry = response['dest_country'];
      _experienceController.text = response['experience'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    final experience = _experienceController.text;

    if (_selectedEducation == null || _selectedOccupation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select education and occupation')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in. Redirecting to login.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      final existingResponse = await _supabaseClient
          .from('users')
          .select()
          .eq('user_id', user.id)
          .single();

      if (existingResponse != null) {
        await _supabaseClient.from('users').update({
          'education': _selectedEducation,
          'occupation': _selectedOccupation,
          'dest_country': _selectedDestCountry,
          'experience': experience,
        }).eq('user_id', user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data updated successfully')),
        );
      } else {
        await _supabaseClient.from('users').insert({
          'education': _selectedEducation,
          'occupation': _selectedOccupation,
          'dest_country': _selectedDestCountry,
          'experience': experience,
          'user_id': user.id,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data submitted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferensi Pekerjaan',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedEducation,
                      decoration: InputDecoration(labelText: 'Education'),
                      items: _educationOptions
                          .map((option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEducation = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedOccupation,
                      decoration: InputDecoration(labelText: 'Occupation'),
                      items: _occupationOptions
                          .map((option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOccupation = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDestCountry,
                      decoration:
                          InputDecoration(labelText: 'Destination Country'),
                      items: _destCountryOptions
                          .map((option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDestCountry = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _experienceController,
                      decoration: InputDecoration(labelText: 'Experience'),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Submit Data Calon Pekerja Migran'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

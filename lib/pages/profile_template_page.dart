import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lendana_admin/pages/template_page.dart';

class ProfileTemplatePage extends StatefulWidget {
  @override
  _ProfileTemplatePageState createState() => _ProfileTemplatePageState();
}

class _ProfileTemplatePageState extends State<ProfileTemplatePage> {
  final _supabaseClient = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  bool _isLoading = false;

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
          .select('name, phone, nik')
          .eq('user_id', user.id)
          .single();

      // Populate the text fields with the fetched data
      _nameController.text = response['name'] ?? '';
      _phoneController.text = response['phone'] ?? '';
      _nikController.text = response['nik'] ?? '';

      // After fetching the data, navigate to TemplatePage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplatePage(
            name: _nameController.text,
            phone: _phoneController.text,
            nik: _nikController.text,
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile & Details'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(child: Text('Profile Data Loaded')),
    );
  }
}

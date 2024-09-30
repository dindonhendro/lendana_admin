import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobAdd extends StatefulWidget {
  @override
  _JobAddState createState() => _JobAddState();
}

class _JobAddState extends State<JobAdd> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  final _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _addJob() async {
    final String country = _countryController.text.trim();
    final String company = _companyController.text.trim();
    final String role = _roleController.text.trim();
    final String detail = _detailController.text.trim();
    final String salary = _salaryController.text.trim();

    if (country.isEmpty ||
        company.isEmpty ||
        role.isEmpty ||
        detail.isEmpty ||
        salary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Insert the job details into the 'job' table
      final response = await _supabaseClient.from('job').insert({
        'country': country,
        'company': company,
        'role': role,
        'detail': detail,
        'salary': salary,
      });

      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job added successfully')),
        );
        Navigator.pop(context); // Navigate back after adding
      }
    } catch (e) {
      print('Error adding job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding job: $e')),
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
        title: Text('Add Job'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _countryController,
                      decoration: InputDecoration(labelText: 'Country'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _companyController,
                      decoration: InputDecoration(labelText: 'Company'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _roleController,
                      decoration: InputDecoration(labelText: 'Role'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _detailController,
                      decoration: InputDecoration(labelText: 'Job Detail'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _salaryController,
                      decoration: InputDecoration(labelText: 'Salary'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addJob,
                      child: Text('Add Job'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _detailController.dispose();
    _salaryController.dispose();
    super.dispose();
  }
}

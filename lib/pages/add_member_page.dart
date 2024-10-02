import 'dart:io'; // For handling files
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMemberPage extends StatefulWidget {
  final Function onMemberAdded;
  AddMemberPage({required this.onMemberAdded});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _loan_amountController = TextEditingController();
  XFile? _profileImage;
  XFile? _passportImage;
  bool _isLoading = false;
  int _currentStep = 0;

  Future<void> _pickProfileImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _profileImage = selectedImage;
    });
  }

  Future<void> _pickPassportImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _passportImage = selectedImage;
    });
  }

  Future<void> _saveDraft() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please complete all required fields before saving.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabaseClient.from('drafts').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loan_amountController.text,
        'profile_image_url': _profileImage != null ? _profileImage!.path : null,
        'passport_image_url':
            _passportImage != null ? _passportImage!.path : null,
        'is_submitted': false, // Mark this draft as not yet submitted
      }).select();

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Draft saved successfully!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error saving draft: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Please complete all required fields and upload the profile image.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Upload the profile image to Supabase storage
      final profileFile = File(_profileImage!.path);
      final profileUploadPath = 'public/${_profileImage!.name}';
      await _supabaseClient.storage
          .from('profile_images')
          .upload(profileUploadPath, profileFile);
      final profileImageUrl = _supabaseClient.storage
          .from('profile_images')
          .getPublicUrl(profileUploadPath);

      String? passportImageUrl;

      // Step 2: Upload the passport image to Supabase storage (only if it's selected)
      if (_passportImage != null) {
        final passportFile = File(_passportImage!.path);
        final passportUploadPath = 'public/${_passportImage!.name}';
        await _supabaseClient.storage
            .from('passport_images')
            .upload(passportUploadPath, passportFile);
        passportImageUrl = _supabaseClient.storage
            .from('passport_images')
            .getPublicUrl(passportUploadPath);
      }

      // Step 3: Insert the member data into the 'members' table
      final memberResponse = await _supabaseClient.from('members').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loan_amountController.text,
        'profile_image_url': profileImageUrl,
        'passport_image_url': passportImageUrl, // This can be null
        'is_approved': false,
      }).select();

      if (memberResponse.isEmpty) {
        throw Exception('Error adding member.');
      }

      final memberId = memberResponse.first['id'];

      // Step 4: Insert into the 'loan_applications' table
      final loanResponse =
          await _supabaseClient.from('loan_applications').insert({
        'member_id': memberId,
        'status': 'pending',
        'reviewed_by': null,
      }).select();

      if (loanResponse.isNotEmpty) {
        widget.onMemberAdded(); // Refresh the member list
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loan application submitted successfully!'),
        ));
        Navigator.pop(context);
      } else {
        throw Exception('Error creating loan application.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding member and loan application: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: Text('Member Info'),
        content: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _nikController,
              decoration: InputDecoration(labelText: 'NIK'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _dobController,
              decoration: InputDecoration(labelText: 'Date of Birth'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _loan_amountController,
              decoration: InputDecoration(labelText: 'Loan Amount'),
            ),
          ],
        ),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Upload Images'),
        content: Column(
          children: [
            _profileImage == null
                ? Text('No profile image selected.')
                : Image.file(File(_profileImage!.path)),
            ElevatedButton(
              onPressed: _pickProfileImage,
              child: Text('Select Profile Image'),
            ),
            SizedBox(height: 10),
            _passportImage == null
                ? Text('No passport image selected.')
                : Image.file(File(_passportImage!.path)),
            ElevatedButton(
              onPressed: _pickPassportImage,
              child: Text('Select Passport Image (Optional)'),
            ),
          ],
        ),
        isActive: _currentStep == 1,
      ),
      Step(
        title: Text('Review & Submit'),
        content: Column(
          children: [
            Text('Review all the information before submission.'),
            ElevatedButton(
              onPressed: _submitForm, // Submit to the bank
              child: Text('Submit To The Bank'),
            ),
          ],
        ),
        isActive: _currentStep == 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Member')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() {
                    _currentStep += 1;
                  });
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                }
              },
              steps: _getSteps(),
            ),
    );
  }
}

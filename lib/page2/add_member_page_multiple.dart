import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Use file_picker instead of image_picker
import 'package:intl/intl.dart'; // For currency formatting
import 'package:lendana_admin/components/card_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart'; // Use universal_io instead of dart:io

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();

  List<PlatformFile?> _images =
      List.filled(10, null); // Holds images for 10 different uploads

  bool _isLoading = false;
  int _currentStep = 0;

  // Format the currency input
  String _formatCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String numericString = amount.replaceAll(RegExp(r'[^\d]'), '');
    if (numericString.isEmpty) return '';
    final numericAmount = int.tryParse(numericString);
    return numericAmount != null ? formatter.format(numericAmount) : amount;
  }

  // Handle loan amount change and format it
  void _onLoanAmountChanged(String value) {
    final formattedAmount = _formatCurrency(value);
    _loanAmountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );
  }

  // Pick multiple images using file_picker
  Future<void> _pickImages(List<String> imageTypes) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true, // Allow multiple file selection
      withData: true,
    );

    if (result != null) {
      setState(() {
        for (var i = 0; i < imageTypes.length; i++) {
          if (i < result.files.length) {
            _images[i] = result.files[
                i]; // Assign each picked image to the respective variable
          }
        }
      });
    }
  }

  // Save draft of the form
  Future<void> _saveDraft() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Please complete all required fields before saving.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _supabaseClient.from('drafts').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        'profile_image_url': _images[0]?.name,
        'passport_image_url': _images[1]?.name,
        'is_submitted': false,
      }).select();

      if (response.isNotEmpty) {
        _showSnackBar('Draft saved successfully!');
      }
    } catch (e) {
      _showSnackBar('Error saving draft: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Submit form and upload images
  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _images.any((image) => image == null)) {
      // Check if any image is null
      _showSnackBar('Please complete all fields and upload all images.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _supabaseClient.auth.currentUser?.id;

      // Upload images and store URLs
      List<String> imageUrls = await Future.wait(
        _images.map((image) => _uploadImage(image!, 'doc1')).toList(),
      );

      final memberResponse = await _supabaseClient.from('members').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        'profile_image_url': imageUrls[0],
        'passport_image_url': imageUrls[1],
        'identity_image_url': imageUrls[2],
        'family_image_url': imageUrls[3],
        // Add more URLs for additional documents as needed
        'doc1_image_url': imageUrls[4],
        'doc2_image_url': imageUrls[5],
        'doc3_image_url': imageUrls[6],
        'doc4_image_url': imageUrls[7],
        'doc5_image_url': imageUrls[8],
        'doc6_image_url': imageUrls[9],
        'is_approved': false,
        'admin_id': userId,
      }).select();

      if (memberResponse.isEmpty) throw Exception('Error adding member.');

      final memberId = memberResponse.first['id'];
      final loanResponse =
          await _supabaseClient.from('loan_applications').insert({
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        'member_id': memberId,
        'status': 'pending',
        'reviewed_by': null,
      }).select();

      if (loanResponse.isNotEmpty) {
        widget.onMemberAdded();
        _showSnackBar('Loan application submitted successfully!');
        Navigator.pop(context);
      } else {
        throw Exception('Error creating loan application.');
      }
    } catch (e) {
      _showSnackBar('Error adding member and loan application: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Upload image to Supabase storage
  Future<String> _uploadImage(PlatformFile file, String bucket) async {
    final uploadPath = 'public/${file.name}';
    await _supabaseClient.storage
        .from(bucket)
        .uploadBinary(uploadPath, file.bytes!);
    return _supabaseClient.storage.from(bucket).getPublicUrl(uploadPath);
  }

  // Show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Define steps for the Stepper widget
  List<Step> _getSteps() {
    return [
      Step(
        title: Text('Member Info'),
        content: Column(
          children: [
            _buildTextField('Name', _nameController),
            _buildTextField('Phone', _phoneController),
            _buildTextField('NIK', _nikController),
            _buildTextField('Email', _emailController),
            _buildTextField('Date of Birth (dd/mm/yyyy)', _dobController,
                inputType: TextInputType.number,
                inputFormatter: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                ]),
            _buildTextField('Address', _addressController),
            _buildTextField('Loan Amount', _loanAmountController,
                inputType: TextInputType.number)
          ],
        ),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Upload Images'),
        content: Column(
          children: [
            ElevatedButton(
              onPressed: () => _pickImages([
                'Profile',
                'Passport',
                'Identity',
                'Family',
                'Doc1',
                'Doc2',
                'Doc3',
                'Doc4',
                'Doc5',
                'Doc6'
              ]),
              child: Text('Select Images'),
            ),
            Wrap(
              spacing: 20, // Horizontal spacing between items
              runSpacing: 20, // Vertical spacing between rows
              children: List.generate(_images.length, (index) {
                return Column(
                  children: [
                    _buildImagePreview('Image ${index + 1}', _images[index]),
                  ],
                );
              }),
            ),
          ],
        ),
        isActive: _currentStep == 1,
      ),
    ];
  }

  // Build text field
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? inputType, List<TextInputFormatter>? inputFormatter}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatter,
      decoration: InputDecoration(labelText: label),
    );
  }

  // Build image preview
  Widget _buildImagePreview(String label, PlatformFile? file) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 10),
        file != null
            ? Image.memory(
                file.bytes!,
                height: 100, // Adjust as needed
                width: 100, // Adjust as needed
                fit: BoxFit.cover,
              )
            : Container(
                height: 100,
                width: 100,
                color: Colors.grey[300],
                child: Center(child: Text('No Image')),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Member'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDraft,
            child: Text('Save Draft'),
          ),
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: Text('Submit'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < _getSteps().length - 1) {
                  setState(() => _currentStep++);
                } else {
                  _submitForm();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: _getSteps(),
            ),
    );
  }
}

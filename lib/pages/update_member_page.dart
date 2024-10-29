import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';

class UpdateMemberPage extends StatefulWidget {
  final String id;
  final Function onMemberUpdated;

  UpdateMemberPage({required this.id, required this.onMemberUpdated});

  @override
  _UpdateMemberPageState createState() => _UpdateMemberPageState();
}

class _UpdateMemberPageState extends State<UpdateMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  PlatformFile? _profileImage;
  PlatformFile? _passportImage;
  bool _isLoading = false;
  int _currentStep = 0;
  Map<String, dynamic>? memberData;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id)
          .single();
      memberData = response;

      if (memberData != null) {
        _nameController.text = memberData!['name'] ?? '';
        _emailController.text = memberData!['email'] ?? '';
        _phoneController.text = memberData!['phone'] ?? '';
        _nikController.text = memberData!['nik'] ?? '';
        _dobController.text = memberData!['dob'] ?? '';
        _addressController.text = memberData!['address'] ?? '';
        _loanAmountController.text =
            _formatCurrency(memberData!['loan_amount'] ?? '0');
      }
    } catch (e) {
      _showSnackBar('Error fetching member data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String numericString = amount.replaceAll(RegExp(r'[^\d]'), '');
    final numericAmount = int.tryParse(numericString);
    return numericAmount != null ? formatter.format(numericAmount) : amount;
  }

  Future<void> _pickImage(String imageType) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      setState(() {
        if (imageType == 'profile') {
          _profileImage = result.files.first;
        } else if (imageType == 'passport') {
          _passportImage = result.files.first;
        }
      });
    }
  }

  Future<void> _updateMemberInfo() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Please complete all required fields before updating.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? profileImageUrl;
      String? passportImageUrl;

      if (_profileImage != null) {
        profileImageUrl = await _uploadImage(_profileImage!, 'profile_images');
      }
      if (_passportImage != null) {
        passportImageUrl =
            await _uploadImage(_passportImage!, 'passport_images');
      }

      final updateResponse = await _supabaseClient.from('members').update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        if (passportImageUrl != null) 'passport_image_url': passportImageUrl,
      }).eq('id', widget.id);

      if (updateResponse.isEmpty)
        throw Exception('Error updating member info.');

      widget.onMemberUpdated();
      _showSnackBar('Member information updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error updating member info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadImage(PlatformFile file, String bucket) async {
    final uploadPath = 'public/${file.name}';
    await _supabaseClient.storage
        .from(bucket)
        .uploadBinary(uploadPath, file.bytes!);
    return _supabaseClient.storage.from(bucket).getPublicUrl(uploadPath);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

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
            _buildTextField('Date of Birth (dd/mm/yyyy)', _dobController),
            _buildTextField('Address', _addressController),
            _buildTextField('Loan Amount', _loanAmountController,
                onChanged: _onLoanAmountChanged),
          ],
        ),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Edit Document'),
        content: Column(
          children: [
            _buildImagePreview('Profile Image', _profileImage,
                memberData?['profile_image_url']),
            _buildImagePickerButton(
                'Change Profile Image', () => _pickImage('profile')),
            SizedBox(height: 10),
            _buildImagePreview('Passport Image', _passportImage,
                memberData?['passport_image_url']),
            _buildImagePickerButton(
                'Change Passport Image', () => _pickImage('passport')),
          ],
        ),
        isActive: _currentStep == 1,
      ),
      Step(
        title: Text('Review & Update'),
        content: Column(
          children: [
            Text('Review all the information before updating.'),
            SizedBox(height: 20),
            _buildActionButton('Update Info', _updateMemberInfo),
          ],
        ),
        isActive: _currentStep == 2,
      ),
    ];
  }

  void _onLoanAmountChanged(String value) {
    final formattedAmount = _formatCurrency(value);
    _loanAmountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImagePreview(
      String label, PlatformFile? image, String? imageUrl) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 8),
        image != null
            ? Image.memory(image.bytes!,
                height: 100, width: 100, fit: BoxFit.cover)
            : imageUrl != null
                ? Image.network(imageUrl,
                    height: 100, width: 100, fit: BoxFit.cover)
                : _buildImagePlaceholder('No image selected.'),
      ],
    );
  }

  Widget _buildImagePlaceholder(String text) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text)),
    );
  }

  Widget _buildImagePickerButton(String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.image),
      label: Text(label),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit CPMI')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stepper(
              steps: _getSteps(),
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _updateMemberInfo();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
            ),
    );
  }
}

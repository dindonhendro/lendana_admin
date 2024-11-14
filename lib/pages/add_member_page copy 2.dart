import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Use file_picker instead of image_picker
import 'package:intl/intl.dart'; // For currency formatting
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMemberPage extends StatefulWidget {
  final Function onMemberAdded;

  AddMemberPage({required this.onMemberAdded});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  List<dynamic> _dataProv = [];
  List<dynamic> _dataDist = [];
  List<dynamic> _dataSubDist = [];
  String?
      _getProvId; // To store the province ID (for logic, like fetching districts)
  String? _getProvName; // To store the province name (for storing in Supabase)
  String? _getProv; // Selected Province
  String? _nameProv;
  String? _getDist; // Selected District
  String? _nameDist;
  String? _getSubDist; // Selected Sub-District
  String? _nameSubDist;
  bool enableDist = false; // Enable/disable district dropdown
  bool enableSubDist = false; // Enable/disable sub-district dropdown

  // Load JSON data from assets
  Future<void> loadProvData() async {
    String jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/province_data.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _dataProv = jsonData['provinsi'];
    });
    print("Provinces data: $_dataProv");
  }

  Future<void> loadDistData(String provinceId) async {
    String jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/district_data.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _dataDist = jsonData['districts'][provinceId] ?? [];
      enableDist = _dataDist
          .isNotEmpty; // Enable district dropdown if there are districts
    });
    print("Districts data for Province $provinceId: $_dataDist");
  }

  Future<void> loadSubDistData(String districtId) async {
    String jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/subdistrict_data.json');
    final jsonData = jsonDecode(jsonString);
    setState(() {
      _dataSubDist = jsonData['subdistricts'][districtId] ?? [];
      enableSubDist = _dataSubDist
          .isNotEmpty; // Enable sub-district dropdown if there are sub-districts
    });
    print("Sub-districts data for District $districtId: $_dataSubDist");
  }

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
  PlatformFile? _identityImage;
  PlatformFile? _familyImage;
  PlatformFile? _doc1Image;
  bool _isLoading = false;
  int _currentStep = 0;

  // Added religion variable for dropdown
  String? _selectedReligion;
  String? _selectedEducation;
  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedBank;

  final List<String> _religionOptions = ['Islam', 'Christianity', 'Other'];
  final List<String> _educationOptions = [
    'SD',
    'SMP',
    'SMA',
    'D3',
    'S1',
    'Other'
  ];

  final List<String> _genderOptions = ['Man', 'Woman'];
  final List<String> _statusOptions = ['Married', 'Not Married'];

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

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  // Pick image using file_picker
  Future<void> _pickImage(String imageType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        switch (imageType) {
          case 'profile':
            _profileImage = result.files.first;
            break;
          case 'passport':
            _passportImage = result.files.first;
            break;
          case 'identity':
            _identityImage = result.files.first;
            break;
          case 'family':
            _familyImage = result.files.first;
            break;
          case 'doc1':
            _doc1Image = result.files.first;
            break;
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
        'profile_image_url': _profileImage?.name,
        'passport_image_url': _passportImage?.name,
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
// Submit form and upload images
  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _profileImage == null ||
        _passportImage == null ||
        _identityImage == null ||
        _familyImage == null) {
      _showSnackBar('Please complete all fields and upload all images.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      final profileImageUrl =
          await _uploadImage(_profileImage!, 'profile_images');
      final passportImageUrl =
          await _uploadImage(_passportImage!, 'passport_images');
      final identityImageUrl =
          await _uploadImage(_identityImage!, 'identity_image');
      final familyImageUrl = await _uploadImage(_familyImage!, 'family_image');
      final doc1ImageUrl = await _uploadImage(_doc1Image!, 'doc1');

      final memberResponse = await _supabaseClient.from('members').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'religion': _selectedReligion,
        'education': _selectedEducation,
        'bank': _selectedBank,
        'gender': _selectedGender,
        'status': _selectedStatus,
        'province': _getProvName,
        'district': _getDist,
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        'profile_image_url': profileImageUrl,
        'passport_image_url': passportImageUrl,
        'identity_image_url': identityImageUrl,
        'family_image_url': familyImageUrl,
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
            _provinsi(),
            _district(),
            _buildTextField('Name', _nameController),
            _buildTextField('Phone', _phoneController),
            _buildTextField('NIK', _nikController),
            _buildTextField('Email', _emailController),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: _buildTextField(
                  'Date of Birth (dd/mm/yyyy)',
                  _dobController,
                ),
              ),
            ),
            _buildTextField('Address', _addressController),
            _buildDropdownField1('Religion', _selectedReligion, (newValue) {
              setState(() {
                _selectedReligion = newValue;
              });
            }),
            _buildDropdownField2('Education', _selectedEducation, (newValue) {
              setState(() {
                _selectedEducation = newValue;
              });
            }),
            _buildDropdownField3('Gender', _selectedGender, (newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            }),
            _buildDropdownField4('Status', _selectedStatus, (newValue) {
              setState(() {
                _selectedStatus = newValue;
              });
            }),
            Text('Bank',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: Text('BNI'),
              value: 'BNI',
              groupValue: _selectedBank,
              onChanged: (value) {
                setState(() {
                  _selectedBank = value;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('Nano'),
              value: 'Nano',
              groupValue: _selectedBank,
              onChanged: (value) {
                setState(() {
                  _selectedBank = value;
                });
              },
            ),
            _buildTextField('Loan Amount', _loanAmountController,
                inputType: TextInputType.number,
                onChanged: _onLoanAmountChanged),
          ],
        ),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Upload Images'),
        content: Column(
          children: [
            Row(
              children: [
                _buildImagePreview('Profile Image', _profileImage),
                _buildImagePickerButton(
                    'Select Profile Image', () => _pickImage('profile')),
                SizedBox(height: 10),
                _buildImagePreview('Passport Image', _passportImage),
                _buildImagePickerButton(
                    'Select Passport Image', () => _pickImage('passport')),
              ],
            ),
            Row(
              children: [
                SizedBox(height: 10),
                _buildImagePreview('Identity Image', _identityImage),
                _buildImagePickerButton(
                    'Select Identity  Image', () => _pickImage('identity')),
                SizedBox(height: 10),
                _buildImagePreview('Family Image', _familyImage),
                _buildImagePickerButton(
                    'Select Family Image', () => _pickImage('family')),
                SizedBox(height: 10),
                _buildImagePreview('Doc1 Image', _doc1Image),
                _buildImagePickerButton(
                    'Select Doc1 Image', () => _pickImage('doc1')),
              ],
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
            SizedBox(height: 20),
            _buildActionButton('Submit', _submitForm),
            //_buildActionButton('Save Draft', _saveDraft),
          ],
        ),
        isActive: _currentStep == 2,
      ),
    ];
  }

  // Build text field with custom styling
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text,
      List<TextInputFormatter>? inputFormatter,
      Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent)),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
        keyboardType: inputType,
        inputFormatters: inputFormatter,
        onChanged: onChanged,
      ),
    );
  }

  // Build dropdown field for religion
  Widget _buildDropdownField1(
      String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent)),
        ),
        items: _religionOptions
            .map((religion) => DropdownMenuItem(
                  value: religion,
                  child: Text(religion),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Build dropdown field for education
  Widget _buildDropdownField2(
      String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent)),
        ),
        items: _educationOptions
            .map((education) => DropdownMenuItem(
                  value: education,
                  child: Text(education),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Build dropdown field for gender
  Widget _buildDropdownField3(
      String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent)),
        ),
        items: _genderOptions
            .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Build dropdown field for status
  Widget _buildDropdownField4(
      String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent)),
        ),
        items: _statusOptions
            .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Build image preview widget
  Widget _buildImagePreview(String label, PlatformFile? image) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 8),
        image == null
            ? _buildImagePlaceholder('No image selected.')
            : Image.memory(image.bytes!,
                height: 100, width: 100, fit: BoxFit.cover),
      ],
    );
  }

  // Placeholder for image preview
  Widget _buildImagePlaceholder(String text) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(text)),
    );
  }

  // Build image picker button
  Widget _buildImagePickerButton(String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.image),
      label: Text(label),
    );
  }

  // Build action buttons (submit or save draft)
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _provinsi() {
    return Padding(
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DropdownButtonHideUnderline(
          child: Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              hint: Text("Choose Province"),
              value: _getProv,
              items: _dataProv.map((item) {
                return DropdownMenuItem(
                  child: Text(item['nama']),
                  value: item['id'].toString(),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _nameDist = null;
                  _nameSubDist = null;
                  _getDist = null;
                  _getSubDist = null;
                  _getProvId =
                      value as String?; // Store the selected province ID
                  _getProvName = _dataProv.firstWhere((item) =>
                      item['id'].toString() ==
                      _getProvId)['nama']; // Get the name based on ID

                  enableDist = false; // Disable district dropdown initially
                  enableSubDist = false; // Disable sub-district dropdown
                  if (_getProv != null) {
                    loadDistData(
                        _getProv!); // Load districts for selected province
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _district() {
    return Padding(
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DropdownButtonHideUnderline(
          child: Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: enableDist
                  ? Colors.grey[200]
                  : Colors.grey[300], // Change color when disabled
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              hint: Text("Choose District"),
              value: _getDist,
              items: _dataDist.map((item) {
                return DropdownMenuItem(
                  child: Text(item['nama']),
                  value: item['id'].toString(),
                );
              }).toList(),
              onChanged: enableDist
                  ? (value) {
                      setState(() {
                        _nameSubDist = null;
                        _getSubDist = null;
                        _getDist = value as String?;
                        enableSubDist = false; // Disable sub-district initially
                        if (_getDist != null) {
                          loadSubDistData(
                              _getDist!); // Load sub-districts for selected district
                        }
                      });
                    }
                  : null, // Disable onChanged when district dropdown is disabled
            ),
          ),
        ),
      ),
    );
  }

  // Build the main UI of the page
  @override
  void initState() {
    super.initState();
    loadProvData(); // Load province data on init
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Member')),
      body: Stepper(
        steps: _getSteps(),
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _submitForm();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              if (_currentStep < 2)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: const Text('Next'),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/profile_service.dart';

class ProfileDisplayPage extends StatefulWidget {
  @override
  _ProfileDisplayPageState createState() => _ProfileDisplayPageState();
}

class _ProfileDisplayPageState extends State<ProfileDisplayPage> {
  final _supabaseClient = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  String? _avatarUrl; // To store and display the avatar URL
  String? _name;
  String? _phone;
  String? _nik;
  String? _dob;
  String? _gender;
  String? _status;
  String? _address;
  String? _education;
  String? _occupation;
  String? _destCountry;
  String? _experience;
  String? _bank;
  String? _amount;
  String? _statusApplication;

  bool _isLoading = false;

  // Get the current user's ID
  String get userId => _supabaseClient.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch the current user's profile image URL
    final avatarUrl = await _profileService.getProfileImageUrl(userId);

    setState(() {
      _avatarUrl = avatarUrl;
      _isLoading = false;
    });
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
          .select(
              'name, phone, nik, dob, gender, status, address, education, occupation, dest_country, experience, bank, amount, status_aplication') // Select the fields to fetch
          .eq('user_id', user.id)
          .single(); // Ensure we're getting a single result

      // Assign fetched data to variables
      setState(() {
        _name = response['name'] ?? '';
        _phone = response['phone'] ?? '';
        _nik = response['nik'] ?? '';
        _dob = response['dob'] ?? '';
        _gender = response['gender'] ?? '';
        _status = response['status'] ?? '';
        _address = response['address'] ?? '';
        _education = response['education'] ?? '';
        _occupation = response['occupation'] ?? '';
        _destCountry = response['dest_country'] ?? '';
        _experience = response['experience'] ?? '';
        _bank = response['bank'] ?? '';
        _amount = response['amount'] ?? '';
        _statusApplication = response['status_aplication'] ?? '';
      });
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

  Future<void> _signOut() async {
    await _supabaseClient.auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _deleteAccount() async {
    // setState(() {
    //   _isLoading = true; // Show loading indicator
    // });

    // try {
    //   await _supabaseClient.auth.admin.deleteUser(userId);
    //   await _supabaseClient.from('users').delete().eq('user_id', userId);

    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Account successfully deleted.')),
    //   );

    //   Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error deleting account: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isLoading = false; // Hide loading indicator
    //   });
    // }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteAccount(); // Proceed to delete account
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Details'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Using CircleAvatar for a circular avatar
                    CircleAvatar(
                      radius: 0, // Set the radius for the CircleAvatar
                      backgroundColor: const Color.fromARGB(255, 249, 249, 248),
                      backgroundImage:
                          _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Icon(Icons.person,
                              size: 60) // Default icon if no avatar
                          : null,
                    ),
                    SizedBox(height: 10),
                    Text(
                      _name ?? 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: _signOut,
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Account'),
              onTap: _confirmDeleteAccount, // Show confirmation dialog
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Profile Image Section using CircleAvatar
                CircleAvatar(
                  radius: 40, // Set the radius for the CircleAvatar
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? Icon(Icons.person,
                          size: 60) // Default icon if no avatar
                      : null,
                ),
                SizedBox(height: 20),
                // Display user data with icons
                _buildProfileInfo(Icons.person, 'Name', _name),
                Divider(color: Colors.grey[200]), // Grey separator line
                _buildProfileInfo(Icons.phone, 'Phone Number', _phone),
                Divider(color: Colors.grey[200]), // Grey separator line
                _buildProfileInfo(Icons.card_membership, 'KTP Number', _nik),
                Divider(color: Colors.grey[200]), // Grey separator line
                _buildProfileInfo(Icons.calendar_today, 'Date of Birth', _dob),
                Divider(color: Colors.grey[200]), // Grey separator line
                _buildProfileInfo(Icons.home, 'Address', _address),
                Divider(color: Colors.grey[400]), // Grey separator line
                _buildProfileInfo(
                    Icons.flag, 'Destination Country', _destCountry),
                Divider(color: Colors.grey[200]), // Grey separator line
                _buildProfileInfo(Icons.money, 'Bank', _bank),
                Divider(color: Colors.grey[200]), // Grey separator line
                _buildProfileInfo(
                    Icons.monetization_on, 'Loan Amount', _amount),
                Divider(color: Colors.grey[500]), // Grey separator line
                _buildProfileInfo(
                    Icons.assignment, 'Application Status', _statusApplication),
              ],
            ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue), // Icon on the left
          SizedBox(width: 10), // Space between icon and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.blue[200],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600], // Different color for the text
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

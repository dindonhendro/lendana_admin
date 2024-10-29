
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';


// class MultiMemberInputForm extends StatefulWidget {
//   @override
//   _MultiMemberInputFormState createState() => _MultiMemberInputFormState();
// }

// class _MultiMemberInputFormState extends State<MultiMemberInputForm> {
//   List<Map<String, dynamic>> _members = [
//     {"name": "", "phone": "", "nik": "", "dob": ""}
//   ];

//   void _addNewMember() {
//     setState(() {
//       _members.add({"name": "", "phone": "", "nik": "", "dob": ""});
//     });
//   }

//   void _removeMember(int index) {
//     setState(() {
//       _members.removeAt(index);
//     });
//   }

//   void _submitMembers() async {
//     final user = _supabaseClient.auth.currentUser;

//     if (user != null && _members.isNotEmpty) {
//       for (var member in _members) {
//         await _supabaseClient.from('members').insert({
//           'name': member['name'],
//           'phone': member['phone'],
//           'nik': member['nik'],
//           'dob': member['dob'],
//           'created_by': user.id
//         });
//       }
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Members added successfully'),
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Add Members")),
//       body: ListView.builder(
//         itemCount: _members.length,
//         itemBuilder: (context, index) {
//           return MemberInputCard(
//             memberData: _members[index],
//             onRemove: () => _removeMember(index),
//             onChanged: (newData) {
//               setState(() {
//                 _members[index] = newData;
//               });
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _addNewMember,
//         child: Icon(Icons.add),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ElevatedButton(
//           onPressed: _submitMembers,
//           child: Text("Submit All Members"),
//         ),
//       ),
//     );
//   }
// }

// class MemberInputCard extends StatelessWidget {
//   final Map<String, dynamic> memberData;
//   final VoidCallback onRemove;
//   final ValueChanged<Map<String, dynamic>> onChanged;

//   MemberInputCard({required this.memberData, required this.onRemove, required this.onChanged});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Column(
//         children: [
//           TextField(
//             decoration: InputDecoration(labelText: "Name"),
//             onChanged: (value) {
//               memberData['name'] = value;
//               onChanged(memberData);
//             },
//           ),
//           TextField(
//             decoration: InputDecoration(labelText: "Phone"),
//             onChanged: (value) {
//               memberData['phone'] = value;
//               onChanged(memberData);
//             },
//           ),
//           TextField(
//             decoration: InputDecoration(labelText: "NIK"),
//             onChanged: (value) {
//               memberData['nik'] = value;
//               onChanged(memberData);
//             },
//           ),
//           TextField(
//             decoration: InputDecoration(labelText: "Date of Birth"),
//             onChanged: (value) {
//               memberData['dob'] = value;
//               onChanged(memberData);
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.delete),
//             onPressed: onRemove,
//           ),
//         ],
//       ),
//     );
//   }
// }

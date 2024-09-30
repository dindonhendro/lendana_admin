import 'package:flutter/material.dart';

class TemplatePage extends StatelessWidget {
  final String name;
  final String phone;
  final String nik;

  TemplatePage({
    required this.name,
    required this.phone,
    required this.nik,
  });

  String getTemplateText() {
    // Using string interpolation to insert dynamic values into the template
    return "Dear $name, your phone number is $phone and your NIK is $nik. "
        "Thank you for using our service!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Template Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generated Message:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              getTemplateText(), // Display the generated message
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

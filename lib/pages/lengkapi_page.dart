import 'package:flutter/material.dart';
import 'package:lendana/components/my_button.dart';
import 'package:lendana/pages/card_page.dart';
import 'package:lendana/pages/jobpref_page.dart';

import 'package:lendana/pages/profile_page.dart';

class LengkapiPage extends StatefulWidget {
  @override
  State<LengkapiPage> createState() => _LengkapiPageState();
}

class _LengkapiPageState extends State<LengkapiPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      'Lengkapi profile anda untuk pengajuan pinjaman',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                      //  style: Theme.of(context).textTheme.headline1,
                    )),
                SizedBox(height: 10),
                SizedBox(height: 10),
                MyButton(
                  width: 250, // Set your desired width
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage()), // UserPage1(userId: widget.userId)),
                    );
                  },
                  child: Text('Isi Data Pribadi',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                ),
                SizedBox(height: 10),
                MyButton(
                  width: 250, // Set your desired width
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CardPage()),
                    );
                  },
                  child: Text('Unggah Dokumen',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                ),
                SizedBox(height: 20),
                MyButton(
                  width: 250, // Set your desired width
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JobprefPage()),
                    );
                  },
                  child: Text('Preferensi Pekerjaan',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PhoneSettingsScreen extends StatelessWidget {
  const PhoneSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            title: Text('No settings available'),
            subtitle: Text('This is a phone companion for scanning only.'),
          ),
        ],
      ),
    );
  }
}

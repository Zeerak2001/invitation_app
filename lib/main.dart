import 'package:flutter/material.dart';

import 'screens/template_picker_screen.dart';

void main() => runApp(const InvitationApp());

class InvitationApp extends StatelessWidget {
  const InvitationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invitation Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7B4B94),
        useMaterial3: true,
      ),
      home: const TemplatePickerScreen(),
    );
  }
}

import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import 'theme.dart';

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Mis recordatorios',
    theme: buildAppTheme(),
    debugShowCheckedModeBanner: false,
    home: const HomeScreen(),
  );
}

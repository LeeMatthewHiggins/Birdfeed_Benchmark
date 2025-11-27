import 'package:atlas_creator/screens/atlas_creator_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AtlasCreatorApp());
}

class AtlasCreatorApp extends StatelessWidget {
  const AtlasCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AtlasCreatorScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart';

import 'package:benchmark/screens/benchmark_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();
  runApp(const RiveBenchmarkApp());
}

class RiveBenchmarkApp extends StatelessWidget {
  const RiveBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive Rendering Benchmark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BenchmarkScreen(),
    );
  }
}

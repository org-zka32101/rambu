import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rambu_shogi/views/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: RambuShogiApp()));
}

class RambuShogiApp extends StatelessWidget {
  const RambuShogiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乱舞将棋',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

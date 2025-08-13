import 'package:flutter/material.dart';
import 'package:voice/data/notifiers.dart';
import 'package:voice/views/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkNotifier, 
      builder:(context, bool isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: isDark ? Brightness.dark : Brightness.light
            ),
            useMaterial3: true,
          ),
          home: HomeWidget(),
        );
      });
  }
}

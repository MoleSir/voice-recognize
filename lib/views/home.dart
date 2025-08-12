
import 'package:voice/data/notifiers.dart';
import 'package:voice/views/pages/edit.dart';
import 'package:voice/views/pages/mic.dart';
import 'package:voice/views/widgets/navigationbar.dart';
import 'package:flutter/material.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  HomeWidgetState createState() => HomeWidgetState();
}

class HomeWidgetState extends State<HomeWidget> {
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MicPage(),
      EditPage()
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Recognize"),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              isDarkNotifier.value = !isDarkNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkNotifier, 
              builder: (context, bool value, child) => Icon(value ? Icons.light_mode : Icons.dark_mode),
            ),
          )
        ],
      ),

        body: ValueListenableBuilder(
          valueListenable: selectedPageNotifier, 
          builder:(context, value, child) {
            return _pages.elementAt(value);
          },
        ),

        bottomNavigationBar: NavigationBarWidget(),
    );
  }
}
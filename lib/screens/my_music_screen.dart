import 'package:flutter/material.dart';


class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({super.key});

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          child: Center(
            child: Text("my music"),
          ),
        )
    );
  }
}

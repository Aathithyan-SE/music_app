import 'package:flutter/material.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Container(
          child: Center(
            child: Text("download"),
          ),
        )
    );
  }
}

import 'package:flutter/material.dart';

class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Model Analysis")),
      body: const Center(
        child: Text("Model Analysis Page", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

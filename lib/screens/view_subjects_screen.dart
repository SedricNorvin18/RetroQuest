import 'package:flutter/material.dart';

class ViewSubjectsScreen extends StatelessWidget {
  const ViewSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: const Center(
        child: Text('List of subjects will be here.'),
      ),
    );
  }
}

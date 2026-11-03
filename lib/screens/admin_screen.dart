import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление и износ оборудования (Управляющий)'),
      ),
      body: const Center(
        child: Text(
          'Аналитика доходности категорий и процент износа техпаспортов',
        ),
      ),
    );
  }
}

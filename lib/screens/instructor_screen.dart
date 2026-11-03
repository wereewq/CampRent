import 'package:flutter/material.dart';

class InstructorScreen extends StatelessWidget {
  const InstructorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал приёмки и акты осмотра (Инструктор)'),
      ),
      body: const Center(
        child: Text('Оформление актов возврата инвентаря и фиксация залога'),
      ),
    );
  }
}

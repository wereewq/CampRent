import 'package:flutter/material.dart';

class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои активные аренды')),
      body: const Center(
        child: Text('Раздел истории и статуса бронирований текущего клиента'),
      ),
    );
  }
}

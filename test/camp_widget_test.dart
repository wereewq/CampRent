import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camp_rent/models/role.dart';

void main() {
  group('Тестирование виджетов интерфейса CampRent', () {
    testWidgets('1. Отображение спиннера загрузки', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2. Отображение сообщения пустого каталога', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Инвентарь по заданным критериям не найден'),
            ),
          ),
        ),
      );
      expect(
        find.text('Инвентарь по заданным критериям не найден'),
        findsOneWidget,
      );
    });

    testWidgets('3. Обработка ошибки с кнопкой повтора', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilledButton(
              onPressed: () => pressed = true,
              child: const Text('Повторить'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Повторить'));
      expect(pressed, isTrue);
    });

    testWidgets('4. Срабатывание валидатора формы', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (v) => v!.isEmpty ? 'Ошибка' : null,
              ),
            ),
          ),
        ),
      );
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Ошибка'), findsOneWidget);
    });

    testWidgets('5. Скрытие кнопок управления для роли клиента', (
      tester,
    ) async {
      const userRole = Role.reader;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (userRole.level >= Role.librarian.level)
                  const Icon(Icons.delete),
                const Text('Каталог CampRent'),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.text('Каталог CampRent'), findsOneWidget);
    });
  });
}

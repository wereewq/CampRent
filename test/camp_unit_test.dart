import 'package:flutter_test/flutter_test.dart';
import 'package:camp_rent/core/rental_calculator.dart';
import 'package:camp_rent/core/validators.dart';
import 'package:camp_rent/models/role.dart';
import 'package:camp_rent/models/tech_passport.dart';

void main() {
  group('1. Валидаторы полей ввода', () {
    test('Обязательное поле отклоняет пустоту', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('Палатка'), isNull);
    });

    test('Положительное число', () {
      expect(V.positiveNumber()('-5'), isNotNull);
      expect(V.positiveNumber()('1500'), isNull);
    });
  });

  group('2. Расчёт сметы и скидок (Пункт 20)', () {
    test('Аренда на 2 суток рассчитывается без скидки', () {
      final res = RentalCalculator.calculate(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 3),
        dailyRate: 1000,
        deposit: 2000,
      );
      expect(res.days, 2);
      expect(res.discountPercent, 0);
      expect(res.total, 4000);
    });

    test('Аренда от 3 суток активирует скидку 10%', () {
      final res = RentalCalculator.calculate(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 4),
        dailyRate: 1000,
        deposit: 2000,
      );
      expect(res.days, 3);
      expect(res.discountPercent, 10);
      expect(res.discountedCost, 2700);
      expect(res.total, 4700);
    });
  });

  group('3. Алгоритм предотвращения коллизий дат (Overlap Check)', () {
    test('Пересекающиеся интервалы фиксируются как коллизия', () {
      final overlap = RentalCalculator.checkOverlap(
        newStart: DateTime(2026, 6, 2),
        newEnd: DateTime(2026, 6, 5),
        existingStart: DateTime(2026, 6, 1),
        existingEnd: DateTime(2026, 6, 4),
      );
      expect(overlap, isTrue);
    });

    test('Непересекающиеся интервалы одобряются', () {
      final overlap = RentalCalculator.checkOverlap(
        newStart: DateTime(2026, 6, 10),
        newEnd: DateTime(2026, 6, 15),
        existingStart: DateTime(2026, 6, 1),
        existingEnd: DateTime(2026, 6, 5),
      );
      expect(overlap, isFalse);
    });
  });

  group('4. Разбор моделей данных и уровни ролей', () {
    test('Парсинг TechPassport (1:1) из JSON', () {
      final pass = TechPassport.fromJson({
        'id': 1,
        'equipmentId': 5,
        'serialNumber': 'SN-001',
        'wearPercent': 10,
      });
      expect(pass.equipmentId, 5);
      expect(pass.wearPercent, 10);
    });

    test('Иерархия ролей: Управляющий > Инструктор > Клиент', () {
      expect(Role.admin.level > Role.librarian.level, isTrue);
      expect(Role.librarian.level > Role.reader.level, isTrue);
    });
  });
}

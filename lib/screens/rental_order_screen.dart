import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/rental_calculator.dart';
import '../repositories/equipment_repository.dart';

class RentalOrderScreen extends StatefulWidget {
  final int equipmentId;
  const RentalOrderScreen({super.key, required this.equipmentId});

  @override
  State<RentalOrderScreen> createState() => _RentalOrderScreenState();
}

class _RentalOrderScreenState extends State<RentalOrderScreen> {
  DateTime _start = DateTime.now().add(const Duration(days: 1));
  DateTime _end = DateTime.now().add(const Duration(days: 4));
  final double _dailyRate = 1500;
  final double _deposit = 5000;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final calc = RentalCalculator.calculate(
      start: _start,
      end: _end,
      dailyRate: _dailyRate,
      deposit: _deposit,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Оформление бронирования #${widget.equipmentId}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Интерактивный расчёт стоимости аренды',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.red.shade50,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Начало: ${_start.toString().substring(0, 10)}'),
                      OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _start,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (d != null) setState(() => _start = d);
                        },
                        child: const Text('Выбрать'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Возврат: ${_end.toString().substring(0, 10)}'),
                      OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _end,
                            firstDate: _start,
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (d != null) setState(() => _end = d);
                        },
                        child: const Text('Выбрать'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue.shade50,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Срок аренды:'),
                            Text('${calc.days} суток'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Базовая стоимость:'),
                            Text('${calc.baseCost.toStringAsFixed(0)} ₽'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Скидка от 3 суток (10%):'),
                            Text(
                              '${calc.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Обязательный залог:'),
                            Text('${calc.deposit.toStringAsFixed(0)} ₽'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Итого к оплате:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${calc.total.toStringAsFixed(0)} ₽',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() {
                              _saving = true;
                              _error = null;
                            });
                            try {
                              await context
                                  .read<EquipmentRepository>()
                                  .createOrder(
                                    equipmentId: widget.equipmentId,
                                    startDate: _start
                                        .toIso8601String()
                                        .substring(0, 10),
                                    endDate: _end.toIso8601String().substring(
                                      0,
                                      10,
                                    ),
                                    dailyRate: _dailyRate,
                                    depositAmount: _deposit,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Бронь успешно оформлена!'),
                                  ),
                                );
                                context.go('/catalog');
                              }
                            } on ConflictException catch (e) {
                              setState(
                                () => _error = e.message,
                              ); // Защита от наложения дат!
                            } catch (_) {
                              setState(
                                () => _error = 'Ошибка создания бронирования',
                              );
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Подтвердить бронь'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

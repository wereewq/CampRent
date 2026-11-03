import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/rental_calculator.dart';
import '../models/accessory.dart';
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

  List<Accessory> _accessories = [];
  final Set<int> _selectedAccessoryIds = {};
  bool _loadingAccessories = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccessories();
  }

  Future<void> _loadAccessories() async {
    try {
      final list = await context.read<EquipmentRepository>().getAccessories();
      if (mounted) {
        setState(() {
          _accessories = list;
          _loadingAccessories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAccessories = false);
    }
  }

  double get _accessoriesDailyTotal {
    double sum = 0;
    for (final a in _accessories) {
      if (_selectedAccessoryIds.contains(a.id)) {
        sum += a.dailyPrice;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final calc = RentalCalculator.calculate(
      start: _start,
      end: _end,
      dailyRate: _dailyRate,
      deposit: _deposit,
      accessoriesDailyTotal: _accessoriesDailyTotal,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Бронирование снаряжения #${widget.equipmentId}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Интерактивный расчёт сметы и комплектации',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    // Выбор дат
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              'Старт: ${_start.toString().substring(0, 10)}',
                            ),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _start,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 90),
                                ),
                              );
                              if (d != null) setState(() => _start = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event, size: 16),
                            label: Text(
                              'Возврат: ${_end.toString().substring(0, 10)}',
                            ),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _end,
                                firstDate: _start.add(const Duration(days: 1)),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 90),
                                ),
                              );
                              if (d != null) setState(() => _end = d);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Блок дополнительных аксессуаров (M:N)
                    Text(
                      'Дополнительные аксессуары в комплект (M:N):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingAccessories)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_accessories.isEmpty)
                      const Text(
                        'Аксессуары не найдены',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _accessories.map((acc) {
                            final isChecked = _selectedAccessoryIds.contains(
                              acc.id,
                            );
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              title: Text(acc.name),
                              subtitle: Text(
                                '+${acc.dailyPrice.toStringAsFixed(0)} ₽/сут',
                              ),
                              secondary: const Icon(Icons.backpack_outlined),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedAccessoryIds.add(acc.id);
                                  } else {
                                    _selectedAccessoryIds.remove(acc.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Детализация сметы
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Длительность аренды:'),
                              Text(
                                '${calc.days} сут.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Базовый тариф инвентаря:'),
                              Text('${calc.baseCost.toStringAsFixed(0)} ₽'),
                            ],
                          ),
                          if (calc.discountPercent > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Скидка от 3 суток:'),
                                Text(
                                  '-${calc.discountPercent}%',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (calc.accessoriesCost > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Аксессуары (за весь срок):'),
                                Text(
                                  '+${calc.accessoriesCost.toStringAsFixed(0)} ₽',
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Возвратный залог:'),
                              Text('${calc.deposit.toStringAsFixed(0)} ₽'),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Итого к оплате:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${calc.total.toStringAsFixed(0)} ₽',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade900,
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
                                final selectedList = _accessories
                                    .where(
                                      (a) =>
                                          _selectedAccessoryIds.contains(a.id),
                                    )
                                    .map(
                                      (a) => {
                                        'accessoryId': a.id,
                                        'quantity': 1,
                                        'dailyPrice': a.dailyPrice,
                                      },
                                    )
                                    .toList();

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
                                      accessories: selectedList,
                                    );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Бронирование успешно оформлено!',
                                      ),
                                    ),
                                  );
                                  context.go('/catalog');
                                }
                              } on ConflictException catch (e) {
                                setState(() => _error = e.message);
                              } catch (_) {
                                setState(
                                  () => _error = 'Ошибка создания бронирования',
                                );
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Подтвердить бронирование'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

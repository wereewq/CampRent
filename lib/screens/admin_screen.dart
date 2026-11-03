import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../models/rental_order.dart';
import '../models/tech_passport.dart';
import '../repositories/equipment_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Equipment> _equipments = [];
  List<Equipment> _deletedEquipments = [];
  List<RentalOrder> _orders = [];
  List<TechPassport> _passports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = context.read<EquipmentRepository>();
    try {
      final eq = await repo.getEquipments();
      final del = await repo.getDeletedEquipments();
      final ord = await repo.getMyOrders();
      final pass = await repo.getTechPassports();
      if (mounted) {
        setState(() {
          _equipments = eq;
          _deletedEquipments = del;
          _orders = ord;
          _passports = pass;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _orders.fold<double>(
      0,
      (sum, o) => sum + (o.totalAmount - o.depositAmount),
    );
    final activeDeposits = _orders
        .where((o) => o.status == 'active')
        .fold<double>(0, (sum, o) => sum + o.depositAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель управления (Управляющий)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Аналитика и выручка'),
            Tab(icon: Icon(Icons.badge), text: 'Техпаспорта (1:1)'),
            Tab(icon: Icon(Icons.delete_sweep), text: 'Корзина и списание'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Аналитика
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.teal.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Общая выручка проката',
                                      style: TextStyle(color: Colors.teal),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${totalRevenue.toStringAsFixed(0)} ₽',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              color: Colors.amber.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Залоги на удержании',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${activeDeposits.toStringAsFixed(0)} ₽',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.sports_tennis,
                                  size: 36,
                                  color: Colors.blue,
                                ),
                                title: const Text('Парк активного снаряжения'),
                                subtitle: Text(
                                  '${_equipments.length} позиций в каталоге',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.receipt_long,
                                  size: 36,
                                  color: Colors.purple,
                                ),
                                title: const Text('Всего оформлено заказов'),
                                subtitle: Text(
                                  '${_orders.length} договоров аренды',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Техпаспорта (1:1)
                _passports.isEmpty
                    ? const Center(child: Text('Техпаспорта отсутствуют'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _passports.length,
                        itemBuilder: (ctx, i) {
                          final p = _passports[i];
                          final wear = p.wearPercent;
                          final color = wear > 40
                              ? Colors.red
                              : (wear > 20 ? Colors.orange : Colors.green);

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Серийный номер: ${p.serialNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          'Инвентарь #${p.equipmentId}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Дата ввода в эксплуатацию: ${p.purchaseDate} | Предел нагрузки: ${p.maxLoadKg > 0 ? "${p.maxLoadKg} кг" : "Без ограничений"}',
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Текущий износ: $wear% ',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: wear / 100,
                                          color: color,
                                          backgroundColor: Colors.grey.shade200,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // 3. Корзина и восстановление (Пункт 16)
                _deletedEquipments.isEmpty
                    ? const Center(
                        child: Text('Корзина пуста (списанных позиций нет)'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _deletedEquipments.length,
                        itemBuilder: (ctx, i) {
                          final item = _deletedEquipments[i];
                          return Card(
                            color: Colors.red.shade50,
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Text(
                                '${item.brand} • Тариф: ${item.dailyPrice} ₽/сут',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.restore),
                                    label: const Text('Восстановить'),
                                    onPressed: () async {
                                      await context
                                          .read<EquipmentRepository>()
                                          .restoreEquipment(item.id);
                                      _loadData();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Удалить навсегда (Hard Delete)',
                                    onPressed: () async {
                                      await context
                                          .read<EquipmentRepository>()
                                          .hardDeleteEquipment(item.id);
                                      _loadData();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}

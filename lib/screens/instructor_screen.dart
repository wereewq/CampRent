import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inspection_act.dart';
import '../models/rental_order.dart';
import '../repositories/equipment_repository.dart';

class InstructorScreen extends StatefulWidget {
  const InstructorScreen({super.key});

  @override
  State<InstructorScreen> createState() => _InstructorScreenState();
}

class _InstructorScreenState extends State<InstructorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RentalOrder> _orders = [];
  List<InspectionAct> _acts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = context.read<EquipmentRepository>();
    try {
      final orders = await repo.getMyOrders();
      final acts = await repo.getInspectionActs();
      if (mounted) {
        setState(() {
          _orders = orders;
          _acts = acts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openInspectionDialog(RentalOrder order) {
    String condition = 'Идеальное';
    final penaltyController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final penalty = double.tryParse(penaltyController.text) ?? 0;
          final refundDeposit = (order.depositAmount - penalty).clamp(
            0,
            order.depositAmount,
          );

          return AlertDialog(
            title: Text('Акт приёмки заказа #${order.id}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Инвентарь #${order.equipmentId} | Залог: ${order.depositAmount.toStringAsFixed(0)} ₽',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: condition,
                    decoration: const InputDecoration(
                      labelText: 'Состояние снаряжения',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Идеальное',
                        child: Text('Идеальное / Без следов износа'),
                      ),
                      DropdownMenuItem(
                        value: 'Загрязнение',
                        child: Text('Требуется химчистка / мойка'),
                      ),
                      DropdownMenuItem(
                        value: 'Повреждение',
                        child: Text('Механические повреждения / ремонт'),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        condition = val ?? 'Идеальное';
                        if (condition == 'Загрязнение') {
                          penaltyController.text = '500';
                        }
                        if (condition == 'Повреждение') {
                          penaltyController.text = '1500';
                        }
                        if (condition == 'Идеальное') {
                          penaltyController.text = '0';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: penaltyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Удержание из залога (штраф, ₽)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Заметки дежурного инструктора',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.green.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Возврат клиенту:'),
                        Text(
                          '${refundDeposit.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  await context.read<EquipmentRepository>().createInspectionAct(
                    orderId: order.id,
                    inspectorName: 'Дежурный Инструктор',
                    conditionStatus: condition,
                    penaltyAmount: double.tryParse(penaltyController.text) ?? 0,
                    notes: notesController.text,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  _loadData();
                },
                child: const Text('Утвердить возврат'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orders.where((o) => o.status == 'active').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал приёмки (Инструктор)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'К приёмке (${activeOrders.length})',
            ),
            Tab(
              icon: const Icon(Icons.history_edu),
              text: 'Составленные акты (${_acts.length})',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                activeOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'Нет активного снаряжения, ожидающего приёмки',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeOrders.length,
                        itemBuilder: (ctx, i) {
                          final o = activeOrders[i];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.inventory_2),
                              ),
                              title: Text(
                                'Заказ #${o.id} • Инвентарь #${o.equipmentId}',
                              ),
                              subtitle: Text(
                                'Период: ${o.startDate} — ${o.endDate} | Залог: ${o.depositAmount.toStringAsFixed(0)} ₽',
                              ),
                              trailing: FilledButton.icon(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: const Text('Принять'),
                                onPressed: () => _openInspectionDialog(o),
                              ),
                            ),
                          );
                        },
                      ),
                _acts.isEmpty
                    ? const Center(
                        child: Text('Акты возврата ещё не оформлялись'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _acts.length,
                        itemBuilder: (ctx, i) {
                          final act = _acts[i];
                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.assignment_turned_in,
                                color: Colors.teal,
                              ),
                              title: Text(
                                'Акт #${act.id} к заказу #${act.orderId} (${act.conditionStatus})',
                              ),
                              subtitle: Text(
                                '${act.inspectionDate} • ${act.inspectorName}\nПримечания: ${act.notes.isEmpty ? "Без замечаний" : act.notes}',
                              ),
                              trailing: Text(
                                act.penaltyAmount > 0
                                    ? '-${act.penaltyAmount.toStringAsFixed(0)} ₽'
                                    : 'Штраф: 0 ₽',
                                style: TextStyle(
                                  color: act.penaltyAmount > 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
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

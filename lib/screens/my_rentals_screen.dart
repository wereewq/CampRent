import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../models/rental_order.dart';
import '../repositories/equipment_repository.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  bool _loading = true;
  String? _error;
  List<RentalOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await context.read<EquipmentRepository>().getMyOrders();
      if (mounted) {
        setState(() {
          _orders = items;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить историю аренды';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои активные аренды'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _fetchOrders,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }
                if (_orders.isEmpty) {
                  return const Center(
                    child: Text(
                      'У вас пока нет активных бронирований',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final order = _orders[i];
                    final isActive = order.status == 'active';
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Заказ #${order.id} • Инвентарь #${order.equipmentId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    isActive ? 'Активна' : 'Завершена',
                                  ),
                                  backgroundColor: isActive
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  labelStyle: TextStyle(
                                    color: isActive
                                        ? Colors.green.shade900
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              'Период аренды: ${order.startDate} — ${order.endDate} (${order.totalDays} сут.)',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Тариф: ${order.dailyRate.toStringAsFixed(0)} ₽/сут${order.discountPercent > 0 ? " (скидка ${order.discountPercent}%)" : ""}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Залог: ${order.depositAmount.toStringAsFixed(0)} ₽',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Итого к оплате: ${order.totalAmount.toStringAsFixed(0)} ₽',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

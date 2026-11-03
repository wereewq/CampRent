import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';
import '../state/equipment_list_notifier.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentListNotifier>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EquipmentListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final size = screenSizeOf(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Панель поиска с Wrap
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск снаряжения...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) => notifier.setFilter(search: v),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => notifier.load(),
                  child: const Text('Обновить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (notifier.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (notifier.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notifier.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => notifier.load(),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (notifier.items.isEmpty) {
                    return const Center(
                      child: Text('Инвентарь по заданным критериям не найден'),
                    );
                  }

                  // 360px: мобильные карточки
                  if (size == ScreenSize.compact) {
                    return ListView.builder(
                      itemCount: notifier.items.length,
                      itemBuilder: (ctx, i) {
                        final eq = notifier.items[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              eq.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${eq.brand} • ${eq.dailyPrice} ₽/день (залог ${eq.deposit} ₽)',
                            ),
                            trailing: auth.has(Role.librarian)
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => notifier.remove(eq.id),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.event_available,
                                      color: Colors.green,
                                    ),
                                    onPressed: () =>
                                        context.go('/rent/${eq.id}'),
                                  ),
                          ),
                        );
                      },
                    );
                  }

                  // Десктоп / Планшет: таблица с двумерным скроллом
                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Наименование')),
                          DataColumn(label: Text('Бренд')),
                          DataColumn(label: Text('Тариф (₽/сут)')),
                          DataColumn(label: Text('Залог (₽)')),
                          DataColumn(label: Text('Действие')),
                        ],
                        rows: notifier.items.map((eq) {
                          return DataRow(
                            cells: [
                              DataCell(Text('#${eq.id}')),
                              DataCell(Text(eq.name)),
                              DataCell(Text(eq.brand)),
                              DataCell(Text('${eq.dailyPrice} ₽')),
                              DataCell(Text('${eq.deposit} ₽')),
                              DataCell(
                                Row(
                                  children: [
                                    FilledButton.icon(
                                      icon: const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                      label: const Text('Бронь'),
                                      onPressed: () =>
                                          context.go('/rent/${eq.id}'),
                                    ),
                                    if (auth.has(Role.librarian)) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => notifier.remove(eq.id),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

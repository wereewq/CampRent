import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/equipment.dart';
import '../models/role.dart';
import '../models/tech_passport.dart';
import '../repositories/equipment_repository.dart';
import '../state/auth_notifier.dart';
import '../state/equipment_list_notifier.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentListNotifier>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryName(int id) {
    return switch (id) {
      1 => 'Водный спорт',
      2 => 'Кемпинг и бивак',
      3 => 'Велопрокат',
      _ => 'Снаряжение',
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'available' => 'Доступен',
      'rented' => 'В аренде',
      'maintenance' => 'На ремонте',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'available' => Colors.green,
      'rented' => Colors.orange,
      'maintenance' => Colors.red,
      _ => Colors.blueGrey,
    };
  }

  void _showDetailsDialog(Equipment eq) async {
    TechPassport? passport;
    try {
      final passports = await context
          .read<EquipmentRepository>()
          .getTechPassports();
      passport = passports.cast<TechPassport?>().firstWhere(
        (p) => p?.equipmentId == eq.id,
        orElse: () => null,
      );
    } catch (_) {}

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(child: Text(eq.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Бренд и Категория'),
                  subtitle: Text(
                    '${eq.brand} • ${_categoryName(eq.categoryId)}',
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Текущий статус'),
                  subtitle: Text(
                    _statusLabel(eq.status),
                    style: TextStyle(
                      color: _statusColor(eq.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Финансовые условия'),
                  subtitle: Text(
                    'Тариф: ${eq.dailyPrice.toStringAsFixed(0)} ₽/сут | Залог: ${eq.deposit.toStringAsFixed(0)} ₽',
                  ),
                ),
                const Divider(height: 20),
                const Text(
                  'Технический паспорт (1:1)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (passport != null) ...[
                  Text('Серийный номер: ${passport.serialNumber}'),
                  Text('Дата ввода: ${passport.purchaseDate}'),
                  Text(
                    'Макс. нагрузка: ${passport.maxLoadKg > 0 ? "${passport.maxLoadKg} кг" : "Без ограничений"}',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Износ: ${passport.wearPercent}% '),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: passport.wearPercent / 100,
                          color: passport.wearPercent > 30
                              ? Colors.red
                              : Colors.green,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Техпаспорт сформирован автоматически в реестре',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  void _openCreateDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final depositCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final maxLoadCtrl = TextEditingController(text: '120');
    int categoryId = 1;
    String status = 'available';
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Добавление нового инвентаря'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null) ...[
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Наименование *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Бренд *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Категория *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Водный спорт')),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Кемпинг и бивак'),
                      ),
                      DropdownMenuItem(value: 3, child: Text('Велопрокат')),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        categoryId = v ?? 1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Тариф (₽/сут) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: depositCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Залог (₽) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Статус инвентаря',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'available',
                        child: Text('Доступен для аренды'),
                      ),
                      DropdownMenuItem(
                        value: 'rented',
                        child: Text('В аренде'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('На ремонте / обслуживании'),
                      ),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        status = v ?? 'available';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: serialCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Заводской серийный номер',
                      hintText: 'SN-CAMP-2026-XX',
                      border: OutlineInputBorder(),
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
                  final name = nameCtrl.text.trim();
                  final brand = brandCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final deposit = double.tryParse(depositCtrl.text) ?? 0;

                  if (name.isEmpty || brand.isEmpty || price <= 0) {
                    setDialogState(() {
                      dialogError =
                          'Заполните обязательные поля: Название, Бренд и Тариф';
                    });
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final notifier = context.read<EquipmentListNotifier>();

                  try {
                    await notifier.createEquipment(
                      name: name,
                      brand: brand,
                      dailyPrice: price,
                      deposit: deposit,
                      categoryId: categoryId,
                      status: status,
                      serialNumber: serialCtrl.text.trim().isNotEmpty
                          ? serialCtrl.text.trim()
                          : null,
                      maxLoadKg: int.tryParse(maxLoadCtrl.text),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Новый инвентарь успешно добавлен в каталог!',
                        ),
                      ),
                    );
                  } catch (_) {
                    setDialogState(() {
                      dialogError = 'Ошибка при добавлении снаряжения';
                    });
                  }
                },
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEditDialog(Equipment eq) {
    final nameCtrl = TextEditingController(text: eq.name);
    final brandCtrl = TextEditingController(text: eq.brand);
    final priceCtrl = TextEditingController(
      text: eq.dailyPrice.toStringAsFixed(0),
    );
    final depositCtrl = TextEditingController(
      text: eq.deposit.toStringAsFixed(0),
    );
    int categoryId = eq.categoryId;
    String status = eq.status;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Редактирование: #${eq.id} ${eq.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null) ...[
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Наименование *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Бренд *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Категория *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Водный спорт')),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Кемпинг и бивак'),
                      ),
                      DropdownMenuItem(value: 3, child: Text('Велопрокат')),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        categoryId = v ?? 1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Тариф (₽/сут) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: depositCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Залог (₽) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Статус инвентаря',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'available',
                        child: Text('Доступен для аренды'),
                      ),
                      DropdownMenuItem(
                        value: 'rented',
                        child: Text('В аренде'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('На ремонте / обслуживании'),
                      ),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        status = v ?? 'available';
                      });
                    },
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
                  final name = nameCtrl.text.trim();
                  final brand = brandCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final deposit = double.tryParse(depositCtrl.text) ?? 0;

                  if (name.isEmpty || brand.isEmpty || price <= 0) {
                    setDialogState(() {
                      dialogError = 'Проверьте заполнение обязательных полей';
                    });
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final notifier = context.read<EquipmentListNotifier>();

                  try {
                    await notifier.updateEquipment(
                      eq.id,
                      name: name,
                      brand: brand,
                      dailyPrice: price,
                      deposit: deposit,
                      categoryId: categoryId,
                      status: status,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Данные товара успешно обновлены!'),
                      ),
                    );
                  } catch (_) {
                    setDialogState(() {
                      dialogError = 'Не удалось сохранить изменения';
                    });
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(Equipment eq) {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = context.read<EquipmentListNotifier>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение списания'),
        content: Text(
          'Списать инвентарь «${eq.name}» (ID: #${eq.id}) в архив/корзину?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await notifier.remove(eq.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Инвентарь перемещён в корзину')),
              );
            },
            child: const Text('Списать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<EquipmentListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final size = screenSizeOf(context);
    final isStaff = auth.has(Role.librarian);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск по названию...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (v) => notifier.setFilter(search: v),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () =>
                      notifier.setFilter(search: _searchController.text),
                  child: const Text('Найти'),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    _searchController.clear();
                    notifier.setFilter(search: '');
                  },
                  child: const Text('Сброс'),
                ),
                if (isStaff) ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить снаряжение'),
                    onPressed: _openCreateDialog,
                  ),
                ],
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

                  if (size == ScreenSize.compact) {
                    return ListView.builder(
                      itemCount: notifier.items.length,
                      itemBuilder: (ctx, i) {
                        final eq = notifier.items[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              eq.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${eq.brand} • ${eq.dailyPrice.toStringAsFixed(0)} ₽/сут • ${_statusLabel(eq.status)}',
                            ),
                            trailing: !isStaff
                                ? FilledButton.icon(
                                    icon: const Icon(
                                      Icons.event_available,
                                      size: 16,
                                    ),
                                    label: const Text('Бронь'),
                                    onPressed: () =>
                                        context.go('/rent/${eq.id}'),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Детали',
                                        onPressed: () => _showDetailsDialog(eq),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.teal,
                                        ),
                                        tooltip: 'Редактировать',
                                        onPressed: () => _openEditDialog(eq),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Списать',
                                        onPressed: () => _confirmDelete(eq),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('ID')),
                          const DataColumn(label: Text('Наименование')),
                          const DataColumn(label: Text('Бренд')),
                          const DataColumn(label: Text('Категория')),
                          const DataColumn(label: Text('Тариф (₽/сут)')),
                          const DataColumn(label: Text('Залог (₽)')),
                          const DataColumn(label: Text('Статус')),
                          DataColumn(
                            label: Text(isStaff ? 'Управление' : 'Действие'),
                          ),
                        ],
                        rows: notifier.items.map((eq) {
                          return DataRow(
                            cells: [
                              DataCell(Text('#${eq.id}')),
                              DataCell(Text(eq.name)),
                              DataCell(Text(eq.brand)),
                              DataCell(Text(_categoryName(eq.categoryId))),
                              DataCell(
                                Text('${eq.dailyPrice.toStringAsFixed(0)} ₽'),
                              ),
                              DataCell(
                                Text('${eq.deposit.toStringAsFixed(0)} ₽'),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(_statusLabel(eq.status)),
                                  backgroundColor: _statusColor(
                                    eq.status,
                                  ).withAlpha(40),
                                  labelStyle: TextStyle(
                                    color: _statusColor(eq.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                !isStaff
                                    ? FilledButton.icon(
                                        icon: const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                        ),
                                        label: const Text('Бронь'),
                                        onPressed: () =>
                                            context.go('/rent/${eq.id}'),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.info_outline,
                                              color: Colors.blue,
                                            ),
                                            tooltip: 'Подробности и техпаспорт',
                                            onPressed: () =>
                                                _showDetailsDialog(eq),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.teal,
                                            ),
                                            tooltip: 'Редактировать',
                                            onPressed: () =>
                                                _openEditDialog(eq),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            tooltip: 'Списать в корзину',
                                            onPressed: () => _confirmDelete(eq),
                                          ),
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

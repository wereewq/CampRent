import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';

class EquipmentListNotifier extends ChangeNotifier {
  final EquipmentRepository _repo;

  bool _isLoading = false;
  String? _errorMessage;
  List<Equipment> _items = [];
  String _search = '';
  int? _categoryId;

  EquipmentListNotifier(this._repo);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Equipment> get items => _items;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repo.getEquipments(
        search: _search,
        categoryId: _categoryId,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Не удалось загрузить каталог снаряжения';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter({String? search, int? categoryId}) {
    if (search != null) {
      _search = search;
    }
    _categoryId = categoryId;
    load();
  }

  Future<void> createEquipment({
    required String name,
    required String brand,
    required double dailyPrice,
    required double deposit,
    required int categoryId,
    String? status,
    String? serialNumber,
    int? maxLoadKg,
  }) async {
    await _repo.createEquipment(
      name: name,
      brand: brand,
      dailyPrice: dailyPrice,
      deposit: deposit,
      categoryId: categoryId,
      status: status,
      serialNumber: serialNumber,
      maxLoadKg: maxLoadKg,
    );
    await load();
  }

  Future<void> updateEquipment(
    int id, {
    required String name,
    required String brand,
    required double dailyPrice,
    required double deposit,
    required int categoryId,
    String? status,
    String? serialNumber,
    int? wearPercent,
  }) async {
    await _repo.updateEquipment(
      id,
      name: name,
      brand: brand,
      dailyPrice: dailyPrice,
      deposit: deposit,
      categoryId: categoryId,
      status: status,
      serialNumber: serialNumber,
      wearPercent: wearPercent,
    );
    await load();
  }

  Future<void> remove(int id) async {
    await _repo.deleteEquipment(id);
    await load();
  }
}

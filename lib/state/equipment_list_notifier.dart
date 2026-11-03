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
    if (search != null) _search = search;
    _categoryId = categoryId;
    load();
  }

  Future<void> remove(int id) async {
    await _repo.deleteEquipment(id);
    await load();
  }
}

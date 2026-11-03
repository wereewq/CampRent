import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/accessory.dart';
import '../models/equipment.dart';
import '../models/inspection_act.dart';
import '../models/rental_order.dart';
import '../models/tech_passport.dart';

class EquipmentRepository {
  final Dio _dio;
  EquipmentRepository(this._dio);

  Future<List<Equipment>> getEquipments({String? search, int? categoryId}) =>
      guard(() async {
        final queryParams = <String, dynamic>{};
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        if (categoryId != null) {
          queryParams['categoryId'] = categoryId;
        }

        final res = await _dio.get(
          '/collections/equipments/records',
          queryParameters: queryParams,
        );
        final list = (res.data['items'] as List?) ?? [];
        return list
            .map((j) => Equipment.fromJson(j as Map<String, dynamic>))
            .toList();
      });

  Future<Equipment> createEquipment({
    required String name,
    required String brand,
    required double dailyPrice,
    required double deposit,
    required int categoryId,
    String? status,
    String? serialNumber,
    int? maxLoadKg,
  }) => guard(() async {
    final data = <String, dynamic>{
      'name': name,
      'brand': brand,
      'dailyPrice': dailyPrice,
      'deposit': deposit,
      'categoryId': categoryId,
      'status': status ?? 'available',
    };
    if (serialNumber != null) {
      data['serialNumber'] = serialNumber;
    }
    if (maxLoadKg != null) {
      data['maxLoadKg'] = maxLoadKg;
    }

    final res = await _dio.post('/collections/equipments/records', data: data);
    return Equipment.fromJson(res.data as Map<String, dynamic>);
  });

  Future<Equipment> updateEquipment(
    int id, {
    required String name,
    required String brand,
    required double dailyPrice,
    required double deposit,
    required int categoryId,
    String? status,
    String? serialNumber,
    int? wearPercent,
  }) => guard(() async {
    final data = <String, dynamic>{
      'name': name,
      'brand': brand,
      'dailyPrice': dailyPrice,
      'deposit': deposit,
      'categoryId': categoryId,
    };
    if (status != null) {
      data['status'] = status;
    }
    if (serialNumber != null) {
      data['serialNumber'] = serialNumber;
    }
    if (wearPercent != null) {
      data['wearPercent'] = wearPercent;
    }

    final res = await _dio.put(
      '/collections/equipments/records/$id',
      data: data,
    );
    return Equipment.fromJson(res.data as Map<String, dynamic>);
  });

  Future<List<Equipment>> getDeletedEquipments() => guard(() async {
    final res = await _dio.get(
      '/collections/equipments/records',
      queryParameters: {'deleted': 'true'},
    );
    final list = (res.data['items'] as List?) ?? [];
    return list
        .map((j) => Equipment.fromJson(j as Map<String, dynamic>))
        .toList();
  });

  Future<void> restoreEquipment(int id) => guard(() async {
    await _dio.post('/collections/equipments/records/$id/restore');
  });

  Future<void> hardDeleteEquipment(int id) => guard(() async {
    await _dio.delete(
      '/collections/equipments/records/$id',
      queryParameters: {'hard': 'true'},
    );
  });

  Future<List<Accessory>> getAccessories({int? categoryId}) => guard(() async {
    final queryParams = <String, dynamic>{};
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }
    final res = await _dio.get(
      '/collections/accessories/records',
      queryParameters: queryParams,
    );
    final list = (res.data['items'] as List?) ?? [];
    return list
        .map((j) => Accessory.fromJson(j as Map<String, dynamic>))
        .toList();
  });

  Future<List<RentalOrder>> getMyOrders() => guard(() async {
    final res = await _dio.get('/collections/rentalOrders/records');
    final list = (res.data['items'] as List?) ?? [];
    return list
        .map((j) => RentalOrder.fromJson(j as Map<String, dynamic>))
        .toList();
  });

  Future<List<TechPassport>> getTechPassports() => guard(() async {
    final res = await _dio.get('/collections/techPassports/records');
    final list = (res.data['items'] as List?) ?? [];
    return list
        .map((j) => TechPassport.fromJson(j as Map<String, dynamic>))
        .toList();
  });

  Future<List<InspectionAct>> getInspectionActs() => guard(() async {
    final res = await _dio.get('/collections/inspectionActs/records');
    final list = (res.data['items'] as List?) ?? [];
    return list
        .map((j) => InspectionAct.fromJson(j as Map<String, dynamic>))
        .toList();
  });

  Future<void> createInspectionAct({
    required int orderId,
    required String inspectorName,
    required String conditionStatus,
    required double penaltyAmount,
    required String notes,
  }) => guard(() async {
    await _dio.post(
      '/collections/inspectionActs/records',
      data: {
        'orderId': orderId,
        'inspectorName': inspectorName,
        'conditionStatus': conditionStatus,
        'penaltyAmount': penaltyAmount,
        'notes': notes,
      },
    );
  });

  Future<void> deleteEquipment(int id) => guard(() async {
    await _dio.delete('/collections/equipments/records/$id');
  });

  Future<RentalOrder> createOrder({
    required int equipmentId,
    required String startDate,
    required String endDate,
    required double dailyRate,
    required double depositAmount,
    List accessories = const [],
  }) => guard(() async {
    final res = await _dio.post(
      '/collections/rentalOrders/records',
      data: {
        'equipmentId': equipmentId,
        'startDate': startDate,
        'endDate': endDate,
        'dailyRate': dailyRate,
        'depositAmount': depositAmount,
        'accessories': accessories,
      },
    );
    return RentalOrder.fromJson(res.data as Map<String, dynamic>);
  });
}

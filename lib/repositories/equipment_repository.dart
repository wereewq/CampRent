import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/accessory.dart';
import '../models/equipment.dart';
import '../models/rental_order.dart';

class EquipmentRepository {
  final Dio _dio;
  EquipmentRepository(this._dio);

  Future<List<RentalOrder>> getMyOrders() => guard(() async {
        final res = await _dio.get('/collections/rentalOrders/records');
        final list = (res.data['items'] as List?) ?? [];
        return list.map((j) => RentalOrder.fromJson(j as Map<String, dynamic>)).toList();
      });
      
  Future<List<Equipment>> getEquipments({String? search, int? categoryId}) =>
      guard(() async {
        final res = await _dio.get(
          '/collections/equipments/records',
          queryParameters: {
            if (search != null && search.isNotEmpty) 'search': search,
            if (categoryId != null) 'categoryId': categoryId,
          },
        );
        final list = (res.data['items'] as List?) ?? [];
        return list
            .map((j) => Equipment.fromJson(j as Map<String, dynamic>))
            .toList();
      });

  Future<List<Accessory>> getAccessories({int? categoryId}) => guard(() async {
    final res = await _dio.get(
      '/collections/accessories/records',
      queryParameters: {if (categoryId != null) 'categoryId': categoryId},
    );
    final list = (res.data['items'] as List?) ?? [];
    return list
        .map((j) => Accessory.fromJson(j as Map<String, dynamic>))
        .toList();
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

import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/equipment.dart';
import '../models/rental_order.dart';

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

  Future<void> deleteEquipment(int id) => guard(() async {
    await _dio.delete('/collections/equipments/records/$id');
  });

  Future<RentalOrder> createOrder({
    required int equipmentId,
    required String startDate,
    required String endDate,
    required double dailyRate,
    required double depositAmount,
  }) => guard(() async {
    final res = await _dio.post(
      '/collections/rentalOrders/records',
      data: {
        'equipmentId': equipmentId,
        'startDate': startDate,
        'endDate': endDate,
        'dailyRate': dailyRate,
        'depositAmount': depositAmount,
      },
    );
    return RentalOrder.fromJson(res.data as Map<String, dynamic>);
  });
}

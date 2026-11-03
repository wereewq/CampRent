import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение',
  ]);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(this.errors, [super.message = 'Ошибка валидации']);
}

class ConflictException extends ApiException {
  const ConflictException([super.message = 'Конфликт целостности данных']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запрашиваемый ресурс не найден']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Доступ запрещён']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется аутентификация']);
}

class ServerException extends ApiException {
  final int statusCode;
  const ServerException(
    this.statusCode, [
    super.message = 'Внутренняя ошибка сервера',
  ]);
}

ApiException mapHttpError(int statusCode, dynamic body) {
  final message = body is Map ? (body['message']?.toString() ?? '') : '';
  return switch (statusCode) {
    400 => ServerException(
      400,
      message.isNotEmpty ? message : 'Некорректный запрос',
    ),
    401 => UnauthorizedException(
      message.isNotEmpty ? message : 'Требуется авторизация',
    ),
    403 => ForbiddenException(
      message.isNotEmpty ? message : 'Доступ ограничен',
    ),
    404 => NotFoundException(
      message.isNotEmpty ? message : 'Запись не найдена',
    ),
    409 => ConflictException(
      message.isNotEmpty ? message : 'Конфликт дат или связей',
    ),
    422 => ValidationException(
      body is Map && body['errors'] is Map
          ? (body['errors'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : {},
      message.isNotEmpty ? message : 'Ошибка валидации данных',
    ),
    _ => ServerException(
      statusCode,
      message.isNotEmpty ? message : 'Сбой сервера ($statusCode)',
    ),
  };
}

Future<T> guard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    if (e.error is ApiException) throw e.error as ApiException;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      throw const NetworkException();
    }
    throw const NetworkException('Сетевой сбой при обращении к серверу');
  }
}

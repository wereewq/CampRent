class V {
  static String? Function(String?) required([
    String message = 'Обязательное поле',
  ]) {
    return (val) => val == null || val.trim().isEmpty ? message : null;
  }

  static String? Function(String?) length({int min = 0, int max = 255}) {
    return (val) {
      if (val == null || val.isEmpty) return null;
      if (val.length < min) return 'Минимум $min символов';
      if (val.length > max) return 'Максимум $max символов';
      return null;
    };
  }

  static String? Function(String?) positiveNumber([
    String message = 'Введите положительное число',
  ]) {
    return (val) {
      if (val == null || val.isEmpty) return null;
      final n = double.tryParse(val);
      return (n == null || n <= 0) ? message : null;
    };
  }
}

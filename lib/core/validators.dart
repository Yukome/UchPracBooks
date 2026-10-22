class Validators {
  static String? required(String? value, [String message = 'Обязательное поле']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? length(String? value, int min, int max) {
    if (value == null || value.trim().isEmpty) return 'Обязательное поле';
    if (value.length < min) return 'Минимум $min символов';
    if (value.length > max) return 'Максимум $max символов';
    return null;
  }

  static String? number(String? value, {int? min, int? max}) {
    if (value == null || value.trim().isEmpty) return 'Обязательное поле';
    final num = int.tryParse(value);
    if (num == null) return 'Введите число';
    if (min != null && num < min) return 'Не меньше $min';
    if (max != null && num > max) return 'Не больше $max';
    return null;
  }

  static String? isbn(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите ISBN';
    final clean = value.replaceAll('-', '').trim();
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return 'ISBN должен содержать только цифры';
    }
    if (clean.length != 10 && clean.length != 13) {
      return 'ISBN должен содержать 10 или 13 цифр';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите Email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Некорректный формат Email';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите телефон';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      return 'Некорректный номер телефона';
    }
    return null;
  }
}
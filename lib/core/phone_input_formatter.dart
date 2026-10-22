import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final buffer = StringBuffer();
    if (digits.startsWith('7') || digits.startsWith('8')) {
      buffer.write('+7 ');
      final rest = digits.length > 1 ? digits.substring(1) : '';
      if (rest.isNotEmpty) {
        buffer.write(rest.length > 3 ? rest.substring(0, 3) : rest);
      }
      if (rest.length > 3) {
        buffer.write(' ');
        buffer.write(rest.length > 6 ? rest.substring(3, 6) : rest.substring(3));
      }
      if (rest.length > 6) {
        buffer.write('-');
        buffer.write(rest.length > 8 ? rest.substring(6, 8) : rest.substring(6));
      }
      if (rest.length > 8) {
        buffer.write('-');
        buffer.write(rest.substring(8, rest.length > 10 ? 10 : rest.length));
      }
    } else {
      buffer.write('+');
      buffer.write(digits);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
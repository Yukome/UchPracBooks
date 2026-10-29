import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_uchprac2/models/app_user.dart';
import 'package:flutter_uchprac2/state/auth_notifier.dart';
import 'package:flutter_uchprac2/repositories/auth_api.dart';

class MockAuthApi implements AuthApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;
  late AuthNotifier auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = AuthNotifier(prefs, MockAuthApi());
  });

  group('Логика разграничения прав (Role)', () {
    test('Читатель не имеет прав библиотекаря и администратора', () {
      final readerUser = const AppUser(
        id: 1, username: 'reader', fullName: 'Читатель', email: '', role: Role.reader,
      );
      expect(Role.reader.level >= Role.reader.level, isTrue);
      expect(Role.reader.level >= Role.librarian.level, isFalse);
      expect(Role.reader.level >= Role.admin.level, isFalse);
    });

    test('Библиотекарь имеет права библиотекаря, но не администратора', () {
      expect(Role.librarian.level >= Role.reader.level, isTrue);
      expect(Role.librarian.level >= Role.librarian.level, isTrue);
      expect(Role.librarian.level >= Role.admin.level, isFalse);
    });

    test('Администратор имеет права всех ролей', () {
      expect(Role.admin.level >= Role.reader.level, isTrue);
      expect(Role.admin.level >= Role.librarian.level, isTrue);
      expect(Role.admin.level >= Role.admin.level, isTrue);
    });

    test('Неавторизованный пользователь не имеет никаких прав', () {
      expect(auth.has(Role.reader), isFalse);
      expect(auth.has(Role.librarian), isFalse);
      expect(auth.has(Role.admin), isFalse);
    });

    test('Проверка иерархии ролей (сравнение уровней)', () {
      expect(Role.reader.level, 1);
      expect(Role.librarian.level, 2);
      expect(Role.admin.level, 3);
      expect(Role.admin.level > Role.librarian.level, isTrue);
    });
  });
}
import 'package:shared_preferences/shared_preferences.dart';

abstract class ISharedPreferencesManager {
  Future<void> setValue({required String key, required Object value});

  Future<T?> getValue<T>({required String key});

  Future<List<String>?> getList({required String key});

  Future<void> removeValue({required String key});
}

/// A key-value store that stores values in SharedPreferences and UserDefaults.
/// Wrapper for `shared_preferences` package.
class SharedPreferencesManager implements ISharedPreferencesManager {
  @override
  Future<void> setValue({required String key, required Object value}) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    if (value is String) {
      await sharedPreferences.setString(key, value);
    } else if (value is int) {
      await sharedPreferences.setInt(key, value);
    } else if (value is bool) {
      await sharedPreferences.setBool(key, value);
    } else if (value is double) {
      await sharedPreferences.setDouble(key, value);
    } else if (value is List<String>) {
      await sharedPreferences.setStringList(key, value);
    } else {
      throw UnsupportedError('Unsupported data type');
    }
  }

  /// Fetch a value from shared preferences associated with [key].
  /// Returns an optional value of type [T].
  @override
  Future<T?> getValue<T>({required String key}) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    switch (T) {
      case const (String):
        return sharedPreferences.getString(key) as T?;
      case const (int):
        return sharedPreferences.getInt(key) as T?;
      case const (bool):
        return sharedPreferences.getBool(key) as T?;
      case const (double):
        return sharedPreferences.getDouble(key) as T?;

      default:
        throw UnsupportedError('Unsupported data type');
    }
  }

  @override
  Future<List<String>?> getList({required String key}) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getStringList(key);
  }

  @override
  Future<void> removeValue({required String key}) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.remove(key);
  }
}

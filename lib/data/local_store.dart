import 'package:shared_preferences/shared_preferences.dart';

/// The small key-value storage the outbox writes to. Hide the real storage
/// behind this so the outbox can be tested with [InMemoryLocalStore].
abstract interface class LocalStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Keeps values in memory. The tests (and the grader) use this one; a "restart"
/// is a new Outbox on the same InMemoryLocalStore.
class InMemoryLocalStore implements LocalStore {
  InMemoryLocalStore([Map<String, String>? initial])
      : _data = {...?initial};

  final Map<String, String> _data;

  /// Every key written so far, in order (for tests).
  final List<String> writes = <String>[];

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    writes.add(key);
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

/// For a real app: stores values with shared_preferences
/// (SharedPreferencesAsync, the API the package recommends for new code).
/// Not used by the tests.
class SharedPreferencesLocalStore implements LocalStore {
  SharedPreferencesLocalStore([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);
}

import 'package:hive_ce/hive.dart';

class CacheService {
  static final CacheService _instance = CacheService._();
  CacheService._();
  factory CacheService() => _instance;

  Future<Box> _openBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    return Hive.openBox(boxName);
  }

  Future<void> put(String boxName, String key, dynamic value) async {
    final box = await _openBox(boxName);
    await box.put(key, value);
  }

  Future<dynamic> get(String boxName, String key) async {
    final box = await _openBox(boxName);
    return box.get(key);
  }

  Future<void> delete(String boxName, String key) async {
    final box = await _openBox(boxName);
    await box.delete(key);
  }

  Future<void> clearBox(String boxName) async {
    final box = await _openBox(boxName);
    await box.clear();
  }

  Future<void> putList(String boxName, String key, List<dynamic> list) async {
    final box = await _openBox(boxName);
    await box.put(key, list);
  }

  Future<List<dynamic>> getList(String boxName, String key) async {
    final box = await _openBox(boxName);
    final data = box.get(key);
    if (data == null) return [];
    return List<dynamic>.from(data as List);
  }

  Future<void> clearAll() async {
    await Hive.deleteFromDisk();
  }
}

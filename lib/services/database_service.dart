import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/character.dart';
import '../models/character_adapter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static const String charactersBoxName = 'characters';
  static const String favoritesBoxName = 'favorites';
  static const String cacheBoxName = 'cache';

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // Инициализация Hive
  Future<void> initHive() async {
    await Hive.initFlutter();
    
    // Регистрация адаптеров
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ManualCharacterAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ManualOriginAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ManualLocationAdapter());
    }
    
    // Открытие боксов
    await Hive.openBox<Character>(charactersBoxName);
    await Hive.openBox<int>(favoritesBoxName);
    await Hive.openBox<Map>(cacheBoxName);
  }

  // Получение боксов
  Box<Character> get charactersBox => Hive.box<Character>(charactersBoxName);
  Box<int> get favoritesBox => Hive.box<int>(favoritesBoxName);
  Box<Map> get cacheBox => Hive.box<Map>(cacheBoxName);

  // Сохранение персонажа
  Future<void> saveCharacter(Character character) async {
    await charactersBox.put(character.id, character);
  }

  // Получение персонажа по id
  Character? getCharacter(int id) {
    return charactersBox.get(id);
  }

  // Получение всех персонажей
  List<Character> getAllCharacters() {
    return charactersBox.values.toList();
  }

  // Добавление в избранное
  Future<void> addToFavorites(int characterId) async {
    await favoritesBox.put(characterId, characterId);
  }

  // Удаление из избранного
  Future<void> removeFromFavorites(int characterId) async {
    await favoritesBox.delete(characterId);
  }

  // Проверка находится ли персонаж в избранном
  bool isFavorite(int characterId) {
    return favoritesBox.containsKey(characterId);
  }

  // Получение всех избранных персонажей
  List<Character> getFavoriteCharacters({String? sortBy}) {
    final List<int> favoriteIds = favoritesBox.values.toList();
    List<Character> favorites = [];
    
    for (var id in favoriteIds) {
      final character = charactersBox.get(id);
      if (character != null) {
        favorites.add(character);
      }
    }
    
    // Сортировка персонажей
    if (sortBy != null) {
      switch (sortBy) {
        case 'name':
          favorites.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'status':
          favorites.sort((a, b) => a.status.compareTo(b.status));
          break;
        case 'species':
          favorites.sort((a, b) => a.species.compareTo(b.species));
          break;
      }
    }
    
    return favorites;
  }

  // Кэширование данных
  Future<void> cacheCharacters(List<Character> characters, int timestamp) async {
    // Сохраняем персонажей
    for (var character in characters) {
      await saveCharacter(character);
      
      // Добавляем информацию о времени кэширования
      await cacheBox.put(character.id, {
        'character_id': character.id,
        'timestamp': timestamp,
      });
    }
  }

  // Получение кэшированных персонажей
  List<Character> getCachedCharacters() {
    final List<Map> cacheInfo = cacheBox.values.toList();
    List<Character> cachedCharacters = [];
    
    for (var info in cacheInfo) {
      final characterId = info['character_id'] as int;
      final character = charactersBox.get(characterId);
      if (character != null) {
        cachedCharacters.add(character);
      }
    }
    
    return cachedCharacters;
  }

  // Очистка старого кэша
  Future<void> clearOldCache(int olderThan) async {
    final List<Map> cacheInfo = cacheBox.values.toList();
    final List<int> keysToRemove = [];
    
    for (var info in cacheInfo) {
      final timestamp = info['timestamp'] as int;
      if (timestamp < olderThan) {
        keysToRemove.add(info['character_id'] as int);
      }
    }
    
    for (var key in keysToRemove) {
      await cacheBox.delete(key);
    }
  }
  
  // Очистка всех данных
  Future<void> clearAllData() async {
    await charactersBox.clear();
    await favoritesBox.clear();
    await cacheBox.clear();
  }
}
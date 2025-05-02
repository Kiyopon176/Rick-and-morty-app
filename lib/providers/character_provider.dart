import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class CharacterProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  
  List<Character> _characters = [];
  List<Character> _favorites = [];
  Map<int, bool> _favoriteStatus = {}; // Кэш статусов избранных
  bool _isLoading = false;
  String _error = '';
  int _currentPage = 1;
  int _totalPages = 0;
  bool _hasMorePages = true;
  String _currentSortBy = 'name'; // Default sort by name
  bool _isInitialized = false;
  
  // Getters
  List<Character> get characters => _characters;
  List<Character> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get currentPage => _currentPage;
  bool get hasMorePages => _hasMorePages;
  String get currentSortBy => _currentSortBy;
  bool get isInitialized => _isInitialized;
  
  CharacterProvider() {
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    try {
      // Инициализируем Hive
      await _dbService.initHive();
      _isInitialized = true;
      
      // Загружаем данные
      await loadCharacters();
      await loadFavorites();
      
      // Прогреваем кэш статусов избранного
      _warmUpFavoriteCache();
    } catch (e) {
      _error = 'Error initializing app: ${e.toString()}';
      debugPrint(_error);
    }
  }
  
  // Прогреваем кэш статусов избранного для более быстрого отображения UI
  void _warmUpFavoriteCache() {
    try {
      final favorites = _dbService.getFavoriteCharacters();
      for (var character in favorites) {
        _favoriteStatus[character.id] = true;
      }
    } catch (e) {
      debugPrint('Error warming up favorite cache: $e');
    }
  }
  
  // Load characters from API or cache
  Future<void> loadCharacters({bool refresh = false}) async {
    if (_isLoading || !_isInitialized) return;
    
    _isLoading = true;
    _error = '';
    
    if (refresh) {
      _characters = [];
      _currentPage = 1;
      _hasMorePages = true;
    }
    
    notifyListeners();
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final bool isConnected = connectivityResult != ConnectivityResult.none;
      
      if (isConnected) {
        // Get data from API
        final response = await _apiService.getCharacters(page: _currentPage);
        final newCharacters = response.results;
        
        _characters.addAll(newCharacters);
        _totalPages = response.info.pages;
        _hasMorePages = _currentPage < _totalPages;
        
        // Cache characters
        await _dbService.cacheCharacters(
          newCharacters, 
          DateTime.now().millisecondsSinceEpoch
        );
        
        // Update favorite status cache
        for (var character in newCharacters) {
          if (!_favoriteStatus.containsKey(character.id)) {
            _favoriteStatus[character.id] = _dbService.isFavorite(character.id);
          }
        }
      } else {
        // Get data from cache
        final cachedCharacters = _dbService.getCachedCharacters();
        if (cachedCharacters.isNotEmpty) {
          _characters = cachedCharacters;
        } else {
          _error = 'No internet connection and no cached data available';
        }
        _hasMorePages = false;
      }
    } catch (e) {
      _error = 'Error loading characters: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load more characters (pagination)
  Future<void> loadMoreCharacters() async {
    if (_isLoading || !_hasMorePages || !_isInitialized) return;
    
    _currentPage++;
    await loadCharacters();
  }
  
  // Load favorites from database
  Future<void> loadFavorites({String? sortBy}) async {
    if (!_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      if (sortBy != null) {
        _currentSortBy = sortBy;
      }
      
      _favorites = _dbService.getFavoriteCharacters(sortBy: _currentSortBy);
      
      // Обновляем кэш статусов избранного
      for (var character in _favorites) {
        _favoriteStatus[character.id] = true;
      }
    } catch (e) {
      _error = 'Error loading favorites: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle favorite status
  Future<void> toggleFavorite(Character character) async {
    if (!_isInitialized) return;
    
    try {
      // Сохраняем персонажа в базе данных
      await _dbService.saveCharacter(character);
      
      // Проверяем, находится ли персонаж в избранном
      bool isFav = _dbService.isFavorite(character.id);
      
      if (isFav) {
        await _dbService.removeFromFavorites(character.id);
        _favoriteStatus[character.id] = false;
      } else {
        await _dbService.addToFavorites(character.id);
        _favoriteStatus[character.id] = true;
      }
      
      // Reload favorites to update UI
      await loadFavorites();
    } catch (e) {
      _error = 'Error toggling favorite: ${e.toString()}';
    }
    
    notifyListeners();
  }
  
  // Check if character is favorite
  bool isFavorite(int characterId) {
    if (!_isInitialized) return false;
    
    // Если в кэше есть информация о статусе, возвращаем ее
    if (_favoriteStatus.containsKey(characterId)) {
      return _favoriteStatus[characterId]!;
    }
    
    // Иначе запрашиваем из базы и обновляем кэш
    try {
      final status = _dbService.isFavorite(characterId);
      _favoriteStatus[characterId] = status;
      return status;
    } catch (e) {
      _error = 'Error checking favorite status: ${e.toString()}';
      return false;
    }
  }
  
  // Clear old cache (call this periodically)
  Future<void> clearOldCache() async {
    if (!_isInitialized) return;
    
    try {
      // Clear cache older than 24 hours
      final timestamp = DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
      await _dbService.clearOldCache(timestamp);
    } catch (e) {
      _error = 'Error clearing old cache: ${e.toString()}';
    }
  }
}
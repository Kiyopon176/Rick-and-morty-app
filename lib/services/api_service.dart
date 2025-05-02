import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character.dart';

class ApiService {
  static const String baseUrl = 'https://rickandmortyapi.com/api';
  static const String charactersEndpoint = '$baseUrl/character';

  Future<CharacterResponse> getCharacters({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$charactersEndpoint/?page=$page'));
      
      if (response.statusCode == 200) {
        return CharacterResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load characters: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Character> getCharacterById(int id) async {
    try {
      final response = await http.get(Uri.parse('$charactersEndpoint/$id'));
      
      if (response.statusCode == 200) {
        return Character.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load character: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
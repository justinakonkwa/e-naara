import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPreferencesService {
  static const String _recentSearchesKey = 'recent_searches';
  static const String _searchFiltersKey = 'search_filters';
  static const int _maxRecentSearches = 10;

  /// Sauvegarde les recherches récentes
  static Future<void> saveRecentSearches(List<String> searches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, searches);
  }

  /// Récupère les recherches récentes
  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  /// Ajoute une nouvelle recherche récente
  static Future<void> addRecentSearch(String search) async {
    final searches = await getRecentSearches();
    
    // Supprimer si déjà présent
    searches.remove(search);
    
    // Ajouter au début
    searches.insert(0, search);
    
    // Limiter le nombre
    if (searches.length > _maxRecentSearches) {
      searches.removeRange(_maxRecentSearches, searches.length);
    }
    
    await saveRecentSearches(searches);
  }

  /// Sauvegarde les filtres de recherche
  static Future<void> saveSearchFilters(Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    final filtersJson = jsonEncode(filters);
    await prefs.setString(_searchFiltersKey, filtersJson);
  }

  /// Récupère les filtres de recherche sauvegardés
  static Future<Map<String, dynamic>> getSearchFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filtersJson = prefs.getString(_searchFiltersKey);
    
    if (filtersJson != null) {
      try {
        final Map<String, dynamic> filters = jsonDecode(filtersJson);
        return filters;
      } catch (e) {
        print('Erreur lors du décodage des filtres: $e');
        return {};
      }
    }
    
    return {};
  }

  /// Efface toutes les préférences de recherche
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    await prefs.remove(_searchFiltersKey);
  }

  /// Efface uniquement les recherches récentes
  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  /// Efface uniquement les filtres sauvegardés
  static Future<void> clearSearchFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchFiltersKey);
  }
}

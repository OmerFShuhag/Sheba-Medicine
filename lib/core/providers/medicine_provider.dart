import 'package:flutter/foundation.dart';
import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicineProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Medicine> _medicines = [];
  Medicine? _selectedMedicine;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _hasMoreData = true;
  int _currentPage = 1;

  List<Medicine> get medicines => _medicines;
  Medicine? get selectedMedicine => _selectedMedicine;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get hasMoreData => _hasMoreData;

  List<Medicine> get filteredMedicines {
    List<Medicine> filtered = _medicines;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (medicine) =>
                medicine.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                medicine.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                medicine.manufacturer.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply client-side sorting as fallback
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case '-price':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    return filtered;
  }

  List<String> get categories {
    final categories = _medicines.map((m) => m.category).toSet().toList();
    categories.sort();
    return categories;
  }

  Future<void> loadMedicines({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _medicines.clear();
        _hasMoreData = true;
      }

      if (!_hasMoreData) return;

      _setLoading(true);
      _error = null;

      final response = await _apiService.getMedicines(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        ordering: _sortBy != 'name'
            ? _sortBy
            : null, 
        page: _currentPage,
        pageSize: 20,
      );


      List<dynamic> results = [];
      
      final data = response['data'] as Map<String, dynamic>;
      results = data['results'] as List<dynamic>;

      if (results.isEmpty) {
        if (refresh) {
          _medicines.clear();
        }
        _hasMoreData = false;
        return;
      }

      final newMedicines = results.map((json) {
        return Medicine.fromJson(json);
      }).toList();

      if (refresh) {
        _medicines = newMedicines;
      } else {
        _medicines.addAll(newMedicines);
      }

      _hasMoreData = results.length == 20;
      _currentPage++;

    } catch (e) {
      _error = e.toString();
      if (e.toString().contains('FormatException') ||
          e.toString().contains('HTML')) {
        _error =
            'Unable to load medicines. Please check your internet connection or try again later.';
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMedicineDetails(int id) async {
    try {
      _setLoading(true);
      _error = null;
      final response = await _apiService.getMedicineDetails(id);
      _selectedMedicine = Medicine.fromJson(response);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    loadMedicines(refresh: true);
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
    loadMedicines(refresh: true);
  }

  void clearFilters() {
    _searchQuery = '';
    _sortBy = 'name';
    notifyListeners();
    loadMedicines(refresh: true);
  }

  void clearFiltersWithoutReload() {
    _searchQuery = '';
    _sortBy = 'name';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

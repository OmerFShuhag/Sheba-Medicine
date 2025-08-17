import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://shebaai.pythonanywhere.com/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Set auth tokens
  Future<void> _setAuthTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // Clear auth tokens
  Future<void> clearAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Make authenticated request
  Future<http.Response> _makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$baseUrl$endpoint');

    final requestHeaders = {'Content-Type': 'application/json', ...?headers};

    if (token != null) {
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(url, headers: requestHeaders);
      case 'POST':
        return await http.post(
          url,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          url,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PATCH':
        return await http.patch(
          url,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(url, headers: requestHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Authentication Methods
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await _makeAuthenticatedRequest(
        '/accounts/auth/register/',
        'POST',
        body: userData,
      );

      // print('Register response status: ${response.statusCode}');
      // print('Register response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response structures
        if (data['access'] != null && data['refresh'] != null) {
          await _setAuthTokens(data['access'], data['refresh']);
        }

        // If user data is in the response, return it
        if (data['user'] != null) {
          return data;
        } else if (data['access'] != null) {
          // If no user data but we have tokens, try to get profile
          try {
            final profileData = await getProfile();
            return {
              'access': data['access'],
              'refresh': data['refresh'],
              'user': profileData,
            };
          } catch (e) {
            // Return the original response if profile fetch fails
            return data;
          }
        }

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registration failed';

        if (errorData is Map<String, dynamic>) {
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else {
            // Handle field-specific errors
            final errors = <String>[];
            errorData.forEach((key, value) {
              if (value is List) {
                errors.addAll(value.cast<String>());
              } else if (value is String) {
                errors.add(value);
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join(', ');
            }
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // print('Logging in with username: $username');

      final response = await _makeAuthenticatedRequest(
        '/accounts/auth/login/',
        'POST',
        body: {'username': username, 'password': password},
      );

      // print('Login response status: ${response.statusCode}');
      // print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response structures
        if (data['access'] != null && data['refresh'] != null) {
          await _setAuthTokens(data['access'], data['refresh']);
        }

        // If user data is in the response, return it
        if (data['user'] != null) {
          return data;
        } else if (data['access'] != null) {
          // If no user data but we have tokens, try to get profile
          try {
            final profileData = await getProfile();
            return {
              'access': data['access'],
              'refresh': data['refresh'],
              'user': profileData,
            };
          } catch (e) {
            // Return the original response if profile fetch fails
            return data;
          }
        }

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Login failed';

        if (errorData is Map<String, dynamic>) {
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['non_field_errors'] != null) {
            errorMessage = errorData['non_field_errors'].join(', ');
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _makeAuthenticatedRequest(
      '/accounts/auth/refresh/',
      'POST',
      body: {'refresh': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access'] != null) {
        await prefs.setString('access_token', data['access']);
      }
      return data;
    } else {
      await clearAuthTokens();
      throw Exception('Token refresh failed');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _makeAuthenticatedRequest(
      '/accounts/auth/profile/',
      'GET',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile: ${response.body}');
    }
  }

  Future<bool> hasValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      return false;
    }
  }


  // Medicine Methods
  Future<Map<String, dynamic>> getMedicines({
    String? search,
    String? ordering,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();

     
      final uri = Uri.parse(
        '$baseUrl/medicines/medicines/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to get medicines';

        if (errorData is Map<String, dynamic>) {
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // print('Medicine loading error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getMedicineDetails(int id) async {
    try {
      
      final response = await http.get(
        Uri.parse('$baseUrl/medicines/medicines/$id/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to get medicine details';

        if (errorData is Map<String, dynamic>) {
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // print('Medicine details error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Order Methods
  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    String? paymentStatus,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;

    final uri = Uri.parse(
      '$baseUrl/orders/',
    ).replace(queryParameters: queryParams);


    final response = await _makeAuthenticatedRequest(
      uri.toString().replaceFirst(baseUrl, ''),
      'GET',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> results = [];

      if (data is Map<String, dynamic>) {
        // Check if response has nested data structure (like {"success": true, "data": {"results": [...]}})
        if (data['data'] != null && data['data'] is Map<String, dynamic>) {
          final nestedData = data['data'] as Map<String, dynamic>;
          if (nestedData['results'] != null && nestedData['results'] is List) {
            results = nestedData['results'] as List<dynamic>;
          }
        }
        // Check if response has 'results' field directly
        else if (data['results'] != null && data['results'] is List) {
          results = data['results'] as List<dynamic>;
        }
        // If none of the above, try to use the data as is
        else {
          results = [data];
        }
      } else if (data is List) {
        // If the response is directly a list
        results = data;
      }

      // print('Extracted orders results: $results');
      return List<Map<String, dynamic>>.from(results);
    } else {
      // print('Orders request failed with status: ${response.statusCode}');
      // print('Orders response body: ${response.body}');
      throw Exception('Failed to get orders: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int id) async {
    final response = await _makeAuthenticatedRequest('/orders/$id/', 'GET');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get order details: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    // print('Creating order with data: $orderData');

    final response = await _makeAuthenticatedRequest(
      '/orders/create/',
      'POST',
      body: orderData,
    );

    // print('Create order response status: ${response.statusCode}');
    // print('Create order response body: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }
}

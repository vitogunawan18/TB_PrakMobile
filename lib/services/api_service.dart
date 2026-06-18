import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://35.255.129.123:8080/api/v1';

  final http.Client _client;
  String? _token;
  final void Function()? onUnauthorized;

  ApiService([http.Client? client, this.onUnauthorized]) : _client = client ?? http.Client();

  void updateToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(String name) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/me'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return _parseResponse(response);
  }

  Future<List<dynamic>> fetchCategories() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
    );
    final json = _parseResponse(response);
    return json['data'] as List<dynamic>;
  }

  Future<List<dynamic>> fetchEvents({
    int page = 1,
    int perPage = 10,
    String? query,
    int? categoryId,
    String? city,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (city != null && city.isNotEmpty) params['city'] = city;

    final uri = Uri.parse('$baseUrl/events').replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);
    final json = _parseResponse(response);
    return json['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchEventDetail(int id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: _headers,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> createOrder(int ticketTypeId, int quantity) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode({'ticket_type_id': ticketTypeId, 'quantity': quantity}),
    );
    return _parseResponse(response);
  }

  Future<List<dynamic>> fetchOrders({int page = 1, int perPage = 10}) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/orders?page=$page&per_page=$perPage'),
      headers: _headers,
    );
    final json = _parseResponse(response);
    return json['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchOrderDetail(int id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: _headers,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> cancelOrder(int id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/orders/$id/cancel'),
      headers: _headers,
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> payOrder(int id, String paymentMethod) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/orders/$id/pay'),
      headers: _headers,
      body: jsonEncode({'payment_method': paymentMethod}),
    );
    return _parseResponse(response);
  }

  Future<List<dynamic>> fetchTickets() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/tickets'),
      headers: _headers,
    );
    final json = _parseResponse(response);
    return json['data'] as List<dynamic>;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      // notify caller to clear local auth
      try {
        if (onUnauthorized != null) onUnauthorized!();
      } catch (_) {}
      throw UnauthorizedException(body['message'] ?? 'Unauthorized');
    }
    throw Exception(body['message'] ?? 'API error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchHealth() async {
    final response = await _client.get(Uri.parse('http://35.255.129.123:8080/health'));
    final body = response.body.isEmpty ? '{}' : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body as Map<String, dynamic>;
    throw Exception(body['message'] ?? 'Health check failed: ${response.statusCode}');
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => 'UnauthorizedException: $message';
}

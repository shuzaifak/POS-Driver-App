import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = "https://corsproxy.io/?https://thevillage-backend.onrender.com";

  // Common headers for all requests
  static Map<String, String> get _commonHeaders => {
    'Content-Type': 'application/json',
    'x-client-id': 'TVP',
  };

  static Future<Driver> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/login'),
        headers: _commonHeaders,
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Driver.fromJson(data['driver']);
      } else {
        throw Exception('Login failed with status: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  static Future<List<Order>> getTodayOrders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/today'),
        headers: _commonHeaders,
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final responseBody = response.body;
          if (responseBody.isEmpty) {
            return [];
          }

          final dynamic decodedData = jsonDecode(responseBody);

          if (decodedData is! List) {
            throw Exception('Expected list but got ${decodedData.runtimeType}');
          }

          final List<dynamic> data = decodedData;
          List<Order> orders = [];
          for (int i = 0; i < data.length; i++) {
            try {
              final orderData = data[i];

              // Create Order object first
              final order = Order.fromJson(orderData);

              // FIXED: Log the processed brand name, not the raw JSON
              print('📦 Processing order $i: ${order.orderId} - Brand: ${order.brandName} (isTVPOrder: ${order.isTVPOrder})');

              // Use the Order object's isTVPOrder property for filtering
              if (order.isTVPOrder) {
                orders.add(order);
                print('✅ Added TVP order: ${order.orderId}');
              } else {
                print('🚫 Skipped non-TVP order: ${order.orderId} (brand: ${order.brandName})');
              }

            } catch (e) {
//Silently
            }
          }
          return orders;

        } catch (e) {
          throw Exception('Failed to parse orders response: $e');
        }
      } else if (response.statusCode == 400) {
        throw Exception('Bad Request (400): ${response.body}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Order> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/details/$orderId'),
        headers: _commonHeaders,
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final order = Order.fromJson(data);

          // FIXED: Check the Order object's properties, not raw JSON
          if (!order.isTVPOrder) {
            throw Exception('Order does not belong to TVP brand');
          }
          return order;
        } catch (e) {
          throw Exception('Failed to parse order details: $e');
        }
      } else {
        throw Exception('Failed to load order details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateOrderStatus(
      int orderId,
      String status,
      int driverId,
      ) async {
    try {
      final requestBody = {
        'order_id': orderId,
        'status': status,
        'driver_id': driverId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/update-status'),
        headers: _commonHeaders,
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to update order status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> removeDriverFromOrder(int orderId) async {
    try {
      final requestBody = {
        'order_id': orderId,
        'status': 'green', // Keep status as green so it appears in "all orders"
        'driver_id': null, // Remove the driver assignment
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/update-status'),
        headers: _commonHeaders,
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Failed to remove driver from order: ${response.statusCode} - ${response.body}');
      }

      print('✅ Successfully removed driver from order');
    } catch (e) {
      print('❌ ApiService removeDriverFromOrder error: $e');
      rethrow;
    }
  }

  // Add a method to test API connectivity
  static Future<bool> testConnection() async {
    try {
      print('📡 Testing API connection...');

      final response = await http.get(
        Uri.parse('$baseUrl/test'), // Add a test endpoint if available
        headers: _commonHeaders,
      ).timeout(Duration(seconds: 5));

      print('📡 Connection test result: ${response.statusCode}');
      return response.statusCode < 500; // Accept any non-server error
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}
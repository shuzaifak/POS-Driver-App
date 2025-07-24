import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'https://thevillage-backend.onrender.com';

  static Future<Driver> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/drivers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Driver.fromJson(data['driver']);
    } else {
      throw Exception('Login failed');
    }
  }

  static Future<List<Order>> getTodayOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/today'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);

        List<Order> orders = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final order = Order.fromJson(data[i]);
            orders.add(order);
          } catch (e) {
            // Skip orders that fail to parse
          }
        }

        return orders;

      } catch (e) {
        throw Exception('Failed to parse orders response: $e');
      }
    } else {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  }

  static Future<Order> getOrderDetails(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/details/$orderId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final order = Order.fromJson(data);
        return order;
      } catch (e) {
        throw Exception('Failed to parse order details: $e');
      }
    } else {
      throw Exception('Failed to load order details: ${response.statusCode}');
    }
  }

  static Future<void> updateOrderStatus(
      int orderId,
      String status,
      int driverId,
      ) async {
    final requestBody = {
      'order_id': orderId,
      'status': status,
      'driver_id': driverId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders/update-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update order status: ${response.statusCode}');
    }
  }


  static Future<void> removeDriverFromOrder(int orderId) async {
    final requestBody = {
      'order_id': orderId,
      'status': 'green', // Keep status as green so it appears in "all orders"
      'driver_id': null, // Remove the driver assignment
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders/update-status'), // Use the correct endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove driver from order: ${response.statusCode}');
    }
  }
}
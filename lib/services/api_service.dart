import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'https://thevillage-backend.onrender.com';

  static Future<Driver> login(String username, String password) async {
    print('🔐 ApiService: Attempting login for user: $username');

    final response = await http.post(
      Uri.parse('$baseUrl/drivers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print('🔐 ApiService: Login response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ ApiService: Login successful');
      return Driver.fromJson(data['driver']);
    } else {
      print('❌ ApiService: Login failed with status: ${response.statusCode}');
      print('❌ ApiService: Login response body: ${response.body}');
      throw Exception('Login failed');
    }
  }

  static Future<List<Order>> getTodayOrders() async {
    print('📡 ApiService: Fetching today\'s orders...');
    print('📡 ApiService: Request URL: $baseUrl/orders/today');

    final response = await http.get(
      Uri.parse('$baseUrl/orders/today'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 ApiService: Response status code: ${response.statusCode}');
    print('📡 ApiService: Response headers: ${response.headers}');

    if (response.statusCode == 200) {
      print('✅ ApiService: Orders fetched successfully');

      // Log the raw response body
      print('📄 ApiService: Raw response body:');
      print(response.body);

      try {
        final List<dynamic> data = jsonDecode(response.body);
        print('📊 ApiService: Parsed JSON successfully');
        print('📊 ApiService: Number of orders in response: ${data.length}');

        // Log each order's basic info before parsing
        for (int i = 0; i < data.length; i++) {
          final orderData = data[i];
          print('📋 Raw Order ${i + 1}:');
          print('   - order_id: ${orderData['order_id']}');
          print('   - driver_id: ${orderData['driver_id']}');
          print('   - status: ${orderData['status']}');
          print('   - order_type: ${orderData['order_type']}');
          print('   - customer_name: ${orderData['customer_name']}');
          print('   - total_price: ${orderData['total_price']}');
          print('   ---');
        }

        // Parse orders
        List<Order> orders = [];
        for (int i = 0; i < data.length; i++) {
          try {
            final order = Order.fromJson(data[i]);
            orders.add(order);
            print('✅ ApiService: Successfully parsed order ${order.orderId}');
          } catch (e) {
            print('❌ ApiService: Failed to parse order ${i + 1}: $e');
            print('❌ ApiService: Problematic order data: ${data[i]}');
          }
        }

        print('📊 ApiService: Successfully parsed ${orders.length} orders out of ${data.length} total');
        return orders;

      } catch (e) {
        print('❌ ApiService: Failed to parse JSON response: $e');
        print('❌ ApiService: Response body that failed to parse: ${response.body}');
        throw Exception('Failed to parse orders response: $e');
      }
    } else {
      print('❌ ApiService: Failed to load orders');
      print('❌ ApiService: Status code: ${response.statusCode}');
      print('❌ ApiService: Response body: ${response.body}');
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  }

  static Future<Order> getOrderDetails(int orderId) async {
    print('📡 ApiService: Fetching order details for ID: $orderId');
    print('📡 ApiService: Request URL: $baseUrl/orders/details/$orderId');

    final response = await http.get(
      Uri.parse('$baseUrl/orders/details/$orderId'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 ApiService: Order details response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ ApiService: Order details fetched successfully');
      print('📄 ApiService: Raw order details response:');
      print(response.body);

      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('📊 ApiService: Parsed order details JSON successfully');

        final order = Order.fromJson(data);
        print('✅ ApiService: Successfully parsed order details for order ${order.orderId}');
        print('   - Status: ${order.status}');
        print('   - Driver ID: ${order.driverId}');
        print('   - Order Type: ${order.orderType}');

        return order;
      } catch (e) {
        print('❌ ApiService: Failed to parse order details JSON: $e');
        print('❌ ApiService: Response body that failed to parse: ${response.body}');
        throw Exception('Failed to parse order details: $e');
      }
    } else {
      print('❌ ApiService: Failed to load order details');
      print('❌ ApiService: Status code: ${response.statusCode}');
      print('❌ ApiService: Response body: ${response.body}');
      throw Exception('Failed to load order details: ${response.statusCode}');
    }
  }

  static Future<void> updateOrderStatus(
      int orderId,
      String status,
      int driverId,
      ) async {
    print('🔄 ApiService: Updating order status...');
    print('🔄 ApiService: Order ID: $orderId');
    print('🔄 ApiService: New Status: $status');
    print('🔄 ApiService: Driver ID: $driverId');

    final requestBody = {
      'order_id': orderId,
      'status': status,
      'driver_id': driverId,
    };

    print('🔄 ApiService: Request body: $requestBody');

    final response = await http.post(
      Uri.parse('$baseUrl/orders/update-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('🔄 ApiService: Update status response code: ${response.statusCode}');
    print('🔄 ApiService: Update status response body: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ ApiService: Failed to update order status');
      throw Exception('Failed to update order status: ${response.statusCode}');
    } else {
      print('✅ ApiService: Order status updated successfully');
    }
  }
}
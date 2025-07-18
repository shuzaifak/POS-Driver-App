import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _allOrders = [];
  List<Order> _myOrders = [];
  List<Order> _completedOrders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get allOrders => _allOrders;
  List<Order> get myOrders => _myOrders;
  List<Order> get completedOrders => _completedOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders() async {
    print('🔄 OrdersProvider: Starting to load orders...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📡 OrdersProvider: Calling API to fetch orders...');
      final orders = await ApiService.getTodayOrders();

      print('✅ OrdersProvider: API call successful');
      print('📊 OrdersProvider: Total orders received: ${orders.length}');

      // Log all orders for debugging
      for (int i = 0; i < orders.length; i++) {
        final order = orders[i];
        print('📋 Order ${i + 1}:');
        print('   - ID: ${order.orderId}');
        print('   - Driver ID: ${order.driverId}');
        print('   - Status: ${order.status}');
        print('   - Order Type: ${order.orderType}');
        print('   - Customer: ${order.customerName}');
        print('   - Total Price: ${order.orderTotalPrice}');
        print('   - Created At: ${order.createdAt}');
        print('   ---');
      }

      // Filter for All Orders (driver_id == null, status == 'green', order_type == 'delivery')
      print('🔍 OrdersProvider: Filtering for All Orders...');
      print('   Filter criteria: driver_id == null AND status == "green" AND order_type == "delivery"');

      _allOrders = orders.where((order) {
        bool matchesDriverId = order.driverId == null;
        bool matchesStatus = order.status == 'green';
        bool matchesOrderType = order.orderType == 'delivery';

        print('   Order ${order.orderId}: driverId=${order.driverId} (${matchesDriverId ? '✅' : '❌'}), status=${order.status} (${matchesStatus ? '✅' : '❌'}), orderType=${order.orderType} (${matchesOrderType ? '✅' : '❌'})');

        return matchesDriverId && matchesStatus && matchesOrderType;
      }).toList();

      print('📈 OrdersProvider: All Orders after filtering: ${_allOrders.length}');

      // Filter for My Orders (driver_id != null, status == 'green', order_type == 'delivery')
      print('🔍 OrdersProvider: Filtering for My Orders...');
      print('   Filter criteria: driver_id != null AND status == "green" AND order_type == "delivery"');

      _myOrders = orders.where((order) {
        bool matchesDriverId = order.driverId != null;
        bool matchesStatus = order.status == 'green';
        bool matchesOrderType = order.orderType == 'delivery';

        print('   Order ${order.orderId}: driverId=${order.driverId} (${matchesDriverId ? '✅' : '❌'}), status=${order.status} (${matchesStatus ? '✅' : '❌'}), orderType=${order.orderType} (${matchesOrderType ? '✅' : '❌'})');

        return matchesDriverId && matchesStatus && matchesOrderType;
      }).toList();

      print('📈 OrdersProvider: My Orders after filtering: ${_myOrders.length}');

      // Filter for Completed Orders (status == 'blue', order_type == 'delivery')
      print('🔍 OrdersProvider: Filtering for Completed Orders...');
      print('   Filter criteria: status == "blue" AND order_type == "delivery"');

      _completedOrders = orders.where((order) {
        bool matchesStatus = order.status == 'blue';
        bool matchesOrderType = order.orderType == 'delivery';

        print('   Order ${order.orderId}: status=${order.status} (${matchesStatus ? '✅' : '❌'}), orderType=${order.orderType} (${matchesOrderType ? '✅' : '❌'})');

        return matchesStatus && matchesOrderType;
      }).toList();

      print('📈 OrdersProvider: Completed Orders after filtering: ${_completedOrders.length}');

      _isLoading = false;
      print('✅ OrdersProvider: Loading completed successfully');
      notifyListeners();
    } catch (e) {
      print('❌ OrdersProvider: Error loading orders: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptOrder(int orderId, int driverId) async {
    print('🎯 OrdersProvider: Accepting order $orderId for driver $driverId');
    try {
      await ApiService.updateOrderStatus(orderId, 'green', driverId);
      print('✅ OrdersProvider: Order status updated successfully');

      // Move order from all orders to my orders
      final orderIndex = _allOrders.indexWhere(
            (order) => order.orderId == orderId,
      );

      if (orderIndex != -1) {
        final order = _allOrders[orderIndex];
        _allOrders.removeAt(orderIndex);
        _myOrders.add(order);
        print('📋 OrdersProvider: Order moved from All Orders to My Orders');
        print('   All Orders count: ${_allOrders.length}');
        print('   My Orders count: ${_myOrders.length}');
        notifyListeners();
      } else {
        print('⚠️ OrdersProvider: Order $orderId not found in All Orders');
      }
    } catch (e) {
      print('❌ OrdersProvider: Error accepting order: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeOrder(int orderId, int driverId) async {
    print('🏁 OrdersProvider: Completing order $orderId for driver $driverId');
    try {
      await ApiService.updateOrderStatus(orderId, 'blue', driverId);
      print('✅ OrdersProvider: Order status updated to completed');

      // Move order from my orders to completed orders
      final orderIndex = _myOrders.indexWhere(
            (order) => order.orderId == orderId,
      );

      if (orderIndex != -1) {
        final order = _myOrders[orderIndex];
        _myOrders.removeAt(orderIndex);
        _completedOrders.add(order);
        print('📋 OrdersProvider: Order moved from My Orders to Completed Orders');
        print('   My Orders count: ${_myOrders.length}');
        print('   Completed Orders count: ${_completedOrders.length}');
        notifyListeners();
      } else {
        print('⚠️ OrdersProvider: Order $orderId not found in My Orders');
      }
    } catch (e) {
      print('❌ OrdersProvider: Error completing order: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> handleSocketUpdate(Map<String, dynamic> data) async {
    print('🔌 OrdersProvider: Socket update received: $data');

    // Extract the relevant fields from socket data
    final newStatus = data['new_status'];
    final newDriverId = data['new_driver_id'];
    final orderId = data['order_id'];

    print('🔌 OrdersProvider: Socket data analysis:');
    print('   - Order ID: $orderId');
    print('   - New Status: $newStatus');
    print('   - New Driver ID: $newDriverId');

    // Check if this is a new order that should be added to "All Orders"
    if (newStatus == 'green' && newDriverId == null && orderId != null) {
      print('🔌 OrdersProvider: Socket update matches criteria for new order');
      print('🔌 OrdersProvider: Fetching order details for order ID: $orderId');

      try {
        // Fetch the complete order details
        final order = await ApiService.getOrderDetails(orderId);

        print('🔌 OrdersProvider: Order details fetched successfully');
        print('   - Order Type: ${order.orderType}');
        print('   - Status: ${order.status}');
        print('   - Driver ID: ${order.driverId}');

        // Check if this is a delivery order
        if (order.orderType == 'delivery') {
          print('🔌 OrdersProvider: Order is a delivery order, adding to All Orders');

          // Check if order already exists in any of our lists
          bool orderExists = _allOrders.any((existingOrder) => existingOrder.orderId == order.orderId) ||
              _myOrders.any((existingOrder) => existingOrder.orderId == order.orderId) ||
              _completedOrders.any((existingOrder) => existingOrder.orderId == order.orderId);

          if (!orderExists) {
            // Add to all orders since it's a new delivery order with green status and no driver
            _allOrders.add(order);
            print('✅ OrdersProvider: New delivery order added to All Orders');
            print('   All Orders count: ${_allOrders.length}');
            notifyListeners();
          } else {
            print('⚠️ OrdersProvider: Order already exists in one of the lists, skipping...');
          }
        } else {
          print('🔌 OrdersProvider: Order is not a delivery order (${order.orderType}), ignoring...');
        }
      } catch (e) {
        print('❌ OrdersProvider: Error fetching order details: $e');
        // If we can't fetch details, fall back to reloading all orders
        print('🔄 OrdersProvider: Falling back to full reload...');
        loadOrders();
      }
    } else {
      print('⚠️ OrdersProvider: Socket update does not match criteria for new order');
      print('   Expected: status=green, driver_id=null, order_id!=null');
      print('   Received: status=$newStatus, driver_id=$newDriverId, order_id=$orderId');

      // For other socket updates, we might want to reload orders to stay in sync
      // This handles cases like order status changes, driver assignments, etc.
      if (orderId != null) {
        print('🔄 OrdersProvider: Reloading orders to maintain sync...');
        loadOrders();
      }
    }
  }
}
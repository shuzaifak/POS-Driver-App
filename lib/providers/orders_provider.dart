import 'dart:async';

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
// Add these properties to OrdersProvider class
  Timer? _pollingTimer;
  bool _isPollingEnabled = false;

// Add this method to start smart polling
  void startSmartPolling() {
    if (_isPollingEnabled) {
      print('OrdersProvider: Polling already enabled');
      return;
    }

    print('OrdersProvider: Starting smart polling for live updates');
    _isPollingEnabled = true;

    // Poll every 10 seconds for live updates
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (!_isPollingEnabled) {
        timer.cancel();
        return;
      }

      try {
        await _performSmartUpdate();
      } catch (e) {
        print('OrdersProvider: Smart polling error: $e');
      }
    });
  }

// Smart update that only updates if there are actual changes
  Future<void> _performSmartUpdate() async {
    print('OrdersProvider: Performing smart update check...');

    try {
      final orders = await ApiService.getTodayOrders();

      // Sort orders by creation time (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Check if there are any new orders since last update
      bool hasChanges = _detectChanges(orders);

      if (hasChanges) {
        print('OrdersProvider: Changes detected, updating UI');
        _updateOrderLists(orders);
        notifyListeners();
      } else {
        print('OrdersProvider: No changes detected, UI update skipped');
      }

    } catch (e) {
      print('OrdersProvider: Smart update failed: $e');
    }
  }

// Detect changes in order lists
  bool _detectChanges(List<Order> newOrders) {
    // Filter new orders for comparison - only process TEST orders
    final newAllOrders = newOrders.where((order) {
      return order.driverId == null &&
          order.status == 'green' &&
          order.orderType == 'delivery' &&
          order.brandName == 'TEST';
    }).toList();

    final newMyOrders = newOrders.where((order) {
      return order.driverId != null &&
          order.status == 'green' &&
          order.orderType == 'delivery' &&
          order.brandName == 'TEST';
    }).toList();

    final newCompletedOrders = newOrders.where((order) {
      return order.status == 'blue' &&
          order.orderType == 'delivery' &&
          order.brandName == 'TEST';
    }).toList();

    // Check if counts changed
    if (newAllOrders.length != _allOrders.length ||
        newMyOrders.length != _myOrders.length ||
        newCompletedOrders.length != _completedOrders.length) {
      print('OrdersProvider: Order count changes detected');
      return true;
    }

    // Check if any order IDs are different
    final currentAllOrderIds = _allOrders.map((o) => o.orderId).toSet();
    final newAllOrderIds = newAllOrders.map((o) => o.orderId).toSet();

    if (!currentAllOrderIds.containsAll(newAllOrderIds) ||
        !newAllOrderIds.containsAll(currentAllOrderIds)) {
      print('OrdersProvider: Order ID changes detected in All Orders');
      return true;
    }

    return false;
  }

// Stop polling when not needed
  void stopSmartPolling() {
    print('OrdersProvider: Stopping smart polling');
    _isPollingEnabled = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

// Override dispose to clean up
  @override
  void dispose() {
    stopSmartPolling();
    super.dispose();
  }

// Update loadOrders method to work with polling
  Future<void> loadOrders({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final orders = await ApiService.getTodayOrders();

      // Sort orders by creation time (newest first) for better UX
      orders.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt); // Newest first
      });

      // Filter and update all order lists
      _updateOrderLists(orders);

      _isLoading = false;
      notifyListeners();

      // Start smart polling after successful load
      if (!_isPollingEnabled) {
        startSmartPolling();
      }

    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateOrderLists(List<Order> orders) {
    // Filter for All Orders (driver_id == null, status == 'green', order_type == 'delivery', brand_name == 'TEST')
    _allOrders = orders.where((order) {
      bool matchesDriverId = order.driverId == null;
      bool matchesStatus = order.status == 'green';
      bool matchesOrderType = order.orderType == 'delivery';
      bool matchesBrand = order.brandName == 'TEST';

      return matchesDriverId && matchesStatus && matchesOrderType && matchesBrand;
    }).toList();

    // Filter for My Orders (driver_id != null, status == 'green', order_type == 'delivery', brand_name == 'TEST')
    _myOrders = orders.where((order) {
      bool matchesDriverId = order.driverId != null;
      bool matchesStatus = order.status == 'green';
      bool matchesOrderType = order.orderType == 'delivery';
      bool matchesBrand = order.brandName == 'TEST';

      return matchesDriverId && matchesStatus && matchesOrderType && matchesBrand;
    }).toList();

    // Filter for Completed Orders (status == 'blue', order_type == 'delivery', brand_name == 'TEST')
    _completedOrders = orders.where((order) {
      bool matchesStatus = order.status == 'blue';
      bool matchesOrderType = order.orderType == 'delivery';
      bool matchesBrand = order.brandName == 'TEST';

      return matchesStatus && matchesOrderType && matchesBrand;
    }).toList();
  }

  void handleSocketUpdate(Map<String, dynamic> data) {
    print('OrdersProvider: Handling socket update: $data');

    try {
      // IGNORE TEST DATA to prevent unnecessary processing
      if (data['test'] == true || data['heartbeat'] == true) {
        print('OrdersProvider: Ignoring test/heartbeat socket data');
        return;
      }

      final orderId = data['order_id'];
      final newStatus = data['new_status'] ?? data['status'];
      final newDriverId = data['new_driver_id'] ?? data['driver_id'];
      final brandName = data['brand_name'];
      final isNewOrderEvent = data['_is_new_order_event'] == true;
      final shouldFetchDetails = data['_fetch_order_details'] == true;

      print('OrdersProvider: Socket update details:');
      print('   - Order ID: $orderId');
      print('   - New Status: $newStatus');
      print('   - New Driver ID: $newDriverId');
      print('   - Brand Name: $brandName');
      print('   - Is New Order Event: $isNewOrderEvent');
      print('   - Should Fetch Details: $shouldFetchDetails');

      // Filter: Only process TEST orders
      if (brandName != 'TEST') {
        print('OrdersProvider: Order not for TEST brand ($brandName), ignoring...');
        return;
      }

      // PRIORITY: Handle potential new order (status=green, driver_id=null)
      if (newStatus == 'green' && newDriverId == null && orderId != null) {
        print('OrdersProvider: Processing potential new TEST order: $orderId');
        _handlePotentialNewOrder(orderId);
        return;
      }

      // Handle order accepted by another driver
      if (newStatus == 'green' && newDriverId != null) {
        print('OrdersProvider: TEST Order accepted by driver $newDriverId');
        _handleOrderAcceptedByOther(orderId);
        return;
      }

      // Handle order completion
      if (newStatus == 'blue') {
        print('OrdersProvider: TEST Order completed');
        _handleOrderCompleted(orderId, newDriverId);
        return;
      }

      // Handle other status changes with minimal reload
      print('OrdersProvider: Other TEST status change, doing silent refresh...');
      _performSilentRefresh();

    } catch (e) {
      print('OrdersProvider: Error handling socket update: $e');
      print('Stack trace: ${StackTrace.current}');
      _performSilentRefresh(); // Fallback to silent refresh
    }
  }

// New method to handle potential new orders
  Future<void> _handlePotentialNewOrder(int orderId) async {
    print('OrdersProvider: Checking if order $orderId is a new TEST delivery order');

    try {
      // Check if order already exists to avoid duplicates
      bool orderExists = _allOrders.any((order) => order.orderId == orderId) ||
          _myOrders.any((order) => order.orderId == orderId) ||
          _completedOrders.any((order) => order.orderId == orderId);

      if (orderExists) {
        print('OrdersProvider: Order $orderId already exists, skipping');
        return;
      }

      print('OrdersProvider: Fetching order details for TEST order $orderId');

      // Fetch order details using the API
      final order = await ApiService.getOrderDetails(orderId);

      print('OrdersProvider: Retrieved order details:');
      print('   - Order ID: ${order.orderId}');
      print('   - Order Type: ${order.orderType}');
      print('   - Status: ${order.status}');
      print('   - Driver ID: ${order.driverId}');
      print('   - Customer: ${order.customerName}');
      print('   - Brand Name: ${order.brandName}');

      // Only add if it's a TEST delivery order with green status and no driver
      if (order.orderType == 'delivery' &&
          order.status == 'green' &&
          order.driverId == null &&
          order.brandName == 'TEST') {

        print('OrdersProvider: Adding new TEST delivery order to All Orders');

        // Add to beginning of all orders (newest first)
        _allOrders.insert(0, order);

        print('OrdersProvider: All Orders count: ${_allOrders.length}');

        // Notify listeners for immediate UI update
        notifyListeners();

        print('OrdersProvider: New TEST order added successfully and UI updated');

      } else {
        print('OrdersProvider: Order does not qualify for All Orders');
        print('   - Expected: orderType=delivery, status=green, driverId=null, brandName=TEST');
        print('   - Actual: orderType=${order.orderType}, status=${order.status}, driverId=${order.driverId}, brandName=${order.brandName}');
      }

    } catch (e) {
      print('OrdersProvider: Error fetching new order details: $e');
      print('Performing silent refresh as fallback');
      _performSilentRefresh();
    }
  }

// New method for silent refresh without showing loading
  Future<void> _performSilentRefresh() async {
    print('OrdersProvider: Performing silent refresh...');

    try {
      final orders = await ApiService.getTodayOrders();

      // Sort orders by creation time (newest first)
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Update all order lists
      _updateOrderLists(orders);

      // Notify listeners
      notifyListeners();

      print('OrdersProvider: Silent refresh completed');

    } catch (e) {
      print('OrdersProvider: Silent refresh failed: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

// Add debug method to check current state
  void debugPrintCurrentState() {
    print('OrdersProvider: Current State Debug:');
    print('   - All Orders: ${_allOrders.length}');
    print('   - My Orders: ${_myOrders.length}');
    print('   - Completed Orders: ${_completedOrders.length}');
    print('   - Is Loading: $_isLoading');
    print('   - Error: $_error');

    if (_allOrders.isNotEmpty) {
      print('All Orders Details:');
      for (var order in _allOrders.take(3)) { // Show first 3
        print('   - Order ${order.orderId}: ${order.customerName} - \$${order.orderTotalPrice} (${order.brandName})');
      }
    }
  }

  Future<void> acceptOrder(int orderId, int driverId) async {
    // First, optimistically update the UI immediately
    final orderIndex = _allOrders.indexWhere(
          (order) => order.orderId == orderId,
    );

    Order? acceptedOrder;

    if (orderIndex != -1) {
      acceptedOrder = _allOrders[orderIndex];

      // Create updated order with driver assigned
      final updatedOrder = Order(
        orderId: acceptedOrder.orderId,
        paymentType: acceptedOrder.paymentType,
        transactionId: acceptedOrder.transactionId,
        orderType: acceptedOrder.orderType,
        driverId: driverId,
        status: acceptedOrder.status,
        createdAt: acceptedOrder.createdAt,
        changeDue: acceptedOrder.changeDue,
        orderSource: acceptedOrder.orderSource,
        customerName: acceptedOrder.customerName,
        customerEmail: acceptedOrder.customerEmail,
        phoneNumber: acceptedOrder.phoneNumber,
        streetAddress: acceptedOrder.streetAddress,
        city: acceptedOrder.city,
        county: acceptedOrder.county,
        postalCode: acceptedOrder.postalCode,
        orderTotalPrice: acceptedOrder.orderTotalPrice,
        orderExtraNotes: acceptedOrder.orderExtraNotes,
        items: acceptedOrder.items,
        brandName: acceptedOrder.brandName, // Include brand name
      );

      // Immediately update UI
      _allOrders.removeAt(orderIndex);
      _myOrders.insert(0, updatedOrder); // Insert at top for newest first
      notifyListeners();
    }

    try {
      // Then make the API call
      await ApiService.updateOrderStatus(orderId, 'green', driverId);
    } catch (e) {
      // Rollback the optimistic update on error
      if (acceptedOrder != null) {
        _myOrders.removeWhere((order) => order.orderId == orderId);
        _allOrders.add(acceptedOrder);
        notifyListeners();
      }

      _error = e.toString();
      notifyListeners();
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  Future<void> _handleOrderAcceptedByOther(int orderId) async {
    print('OrdersProvider: TEST Order $orderId was accepted by another driver');

    // Remove from all orders if it exists
    final orderIndex = _allOrders.indexWhere((order) => order.orderId == orderId);
    if (orderIndex != -1) {
      _allOrders.removeAt(orderIndex);
      print('OrdersProvider: Order removed from All Orders');
      print('   All Orders count: ${_allOrders.length}');
      notifyListeners();
    }
  }

  Future<void> _handleOrderCompleted(int orderId, int? driverId) async {
    print('OrdersProvider: TEST Order $orderId was completed');

    // If it's in my orders, move to completed
    final myOrderIndex = _myOrders.indexWhere((order) => order.orderId == orderId);
    if (myOrderIndex != -1) {
      final order = _myOrders[myOrderIndex];

      // Create updated order with blue status
      final completedOrder = Order(
        orderId: order.orderId,
        paymentType: order.paymentType,
        transactionId: order.transactionId,
        orderType: order.orderType,
        driverId: order.driverId,
        status: 'blue', // Update status to completed
        createdAt: order.createdAt,
        changeDue: order.changeDue,
        orderSource: order.orderSource,
        customerName: order.customerName,
        customerEmail: order.customerEmail,
        phoneNumber: order.phoneNumber,
        streetAddress: order.streetAddress,
        city: order.city,
        county: order.county,
        postalCode: order.postalCode,
        orderTotalPrice: order.orderTotalPrice,
        orderExtraNotes: order.orderExtraNotes,
        items: order.items,
        brandName: order.brandName, // Include brand name
      );

      _myOrders.removeAt(myOrderIndex);
      _completedOrders.insert(0, completedOrder); // Insert at beginning for newest first
      print('OrdersProvider: Order moved from My Orders to Completed Orders');
      print('   My Orders count: ${_myOrders.length}');
      print('   Completed Orders count: ${_completedOrders.length}');
      notifyListeners();
    }
  }

  Future<void> completeOrder(int orderId, int driverId) async {
    print('OrdersProvider: Starting order completion for TEST order $orderId');

    // Find the order first
    final orderIndex = _myOrders.indexWhere((order) => order.orderId == orderId);
    if (orderIndex == -1) {
      print('OrdersProvider: Order not found in My Orders');
      throw Exception('Order not found');
    }

    final orderToComplete = _myOrders[orderIndex];

    // Create completed order with blue status
    final completedOrder = Order(
      orderId: orderToComplete.orderId,
      paymentType: orderToComplete.paymentType,
      transactionId: orderToComplete.transactionId,
      orderType: orderToComplete.orderType,
      driverId: orderToComplete.driverId,
      status: 'blue', // Update status to completed
      createdAt: orderToComplete.createdAt,
      changeDue: orderToComplete.changeDue,
      orderSource: orderToComplete.orderSource,
      customerName: orderToComplete.customerName,
      customerEmail: orderToComplete.customerEmail,
      phoneNumber: orderToComplete.phoneNumber,
      streetAddress: orderToComplete.streetAddress,
      city: orderToComplete.city,
      county: orderToComplete.county,
      postalCode: orderToComplete.postalCode,
      orderTotalPrice: orderToComplete.orderTotalPrice,
      orderExtraNotes: orderToComplete.orderExtraNotes,
      items: orderToComplete.items,
      brandName: orderToComplete.brandName, // Include brand name
    );

    // IMMEDIATELY update the UI for fast response
    _myOrders.removeAt(orderIndex);
    _completedOrders.insert(0, completedOrder);
    notifyListeners();

    print('OrdersProvider: UI updated optimistically');

    try {
      // Make API call in background
      print('OrdersProvider: Making API call...');
      await ApiService.updateOrderStatus(orderId, 'blue', driverId);
      print('OrdersProvider: API call successful');

    } catch (e) {
      print('OrdersProvider: API call failed: $e');

      // ROLLBACK the optimistic update
      _completedOrders.removeWhere((order) => order.orderId == orderId);
      _myOrders.insert(0, orderToComplete); // Put it back at the top

      // Set error for UI feedback
      _error = 'Failed to complete order. Please try again.';
      notifyListeners();

      // RETRY LOGIC - Try once more after a short delay
      print('OrdersProvider: Retrying API call in 2 seconds...');
      try {
        await Future.delayed(Duration(seconds: 2));
        await ApiService.updateOrderStatus(orderId, 'blue', driverId);

        print('OrdersProvider: Retry successful, re-applying completion...');

        // Re-apply the completion if retry succeeds
        final retryOrderIndex = _myOrders.indexWhere((order) => order.orderId == orderId);
        if (retryOrderIndex != -1) {
          _myOrders.removeAt(retryOrderIndex);
          _completedOrders.insert(0, completedOrder);
          _error = null; // Clear error
          notifyListeners();
        }

      } catch (retryError) {
        print('OrdersProvider: Retry also failed: $retryError');

        // Do a silent refresh to ensure consistency
        Timer(Duration(seconds: 1), () {
          _performSilentRefresh();
        });

        // Keep the error state for user feedback
        _error = 'Failed to complete order after retry. Order may complete shortly.';
        notifyListeners();
      }

      // Don't rethrow - let the UI show the error but don't crash
    }
  }

  Future<void> removeOrder(int orderId) async {
    try {
      // Update order status to remove driver assignment (set driver_id to null)
      await ApiService.removeDriverFromOrder(orderId);

      // Move order from my orders back to all orders
      final orderIndex = _myOrders.indexWhere(
            (order) => order.orderId == orderId,
      );

      if (orderIndex != -1) {
        final order = _myOrders[orderIndex];
        _myOrders.removeAt(orderIndex);

        // Create a new order object with driverId set to null
        final updatedOrder = Order(
          orderId: order.orderId,
          paymentType: order.paymentType,
          transactionId: order.transactionId,
          orderType: order.orderType,
          driverId: null, // Remove driver assignment
          status: order.status,
          createdAt: order.createdAt,
          changeDue: order.changeDue,
          orderSource: order.orderSource,
          customerName: order.customerName,
          customerEmail: order.customerEmail,
          phoneNumber: order.phoneNumber,
          streetAddress: order.streetAddress,
          city: order.city,
          county: order.county,
          postalCode: order.postalCode,
          orderTotalPrice: order.orderTotalPrice,
          orderExtraNotes: order.orderExtraNotes,
          items: order.items,
          brandName: order.brandName,
        );

        _allOrders.add(updatedOrder);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
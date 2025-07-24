class OrderItem {
  final String itemName;
  final String itemType;
  final int quantity;
  final String itemDescription;
  final double itemTotalPrice;

  OrderItem({
    required this.itemName,
    required this.itemType,
    required this.quantity,
    required this.itemDescription,
    required this.itemTotalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemName: json['item_name'] ?? '',
      itemType: json['item_type'] ?? '',
      quantity: json['quantity'] ?? 0,
      itemDescription: json['item_description'] ?? '',
      itemTotalPrice: _parseDouble(json['item_total_price']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

class Order {
  final int orderId;
  final String paymentType;
  final String? transactionId;
  final String orderType;
  late final int? driverId;
  late final String status;
  final DateTime createdAt;
  final double changeDue;
  final String orderSource;
  final String customerName;
  final String customerEmail;
  final String phoneNumber;
  final String streetAddress;
  final String city;
  final String county;
  final String postalCode;
  final double orderTotalPrice;
  final String? orderExtraNotes;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.paymentType,
    this.transactionId,
    required this.orderType,
    this.driverId,
    required this.status,
    required this.createdAt,
    required this.changeDue,
    required this.orderSource,
    required this.customerName,
    required this.customerEmail,
    required this.phoneNumber,
    required this.streetAddress,
    required this.city,
    required this.county,
    required this.postalCode,
    required this.orderTotalPrice,
    this.orderExtraNotes,
    required this.items, required String fullAddress,
  });

  String get fullAddress => '$streetAddress, $city, $county, $postalCode';

  factory Order.fromJson(Map<String, dynamic> json) {
    // Enhanced price parsing with multiple fallback strategies
    double totalPrice = _extractTotalPrice(json);

    // Parse items first to potentially calculate total from items if main total is 0
    List<OrderItem> orderItems = [];
    if (json['items'] != null && json['items'] is List) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    // If total price is 0 but we have items, calculate from items
    if (totalPrice == 0.0 && orderItems.isNotEmpty) {
      double calculatedTotal = orderItems.fold(0.0, (sum, item) => sum + item.itemTotalPrice);
      if (calculatedTotal > 0.0) {
        totalPrice = calculatedTotal;
      }
    }

    return Order(
      orderId: json['order_id'] ?? 0,
      paymentType: json['payment_type'] ?? '',
      transactionId: json['transaction_id'],
      orderType: json['order_type'] ?? '',
      driverId: json['driver_id'],
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      changeDue: _parseDouble(json['change_due']),
      orderSource: json['order_source'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      streetAddress: json['street_address'] ?? '',
      city: json['city'] ?? '',
      county: json['county'] ?? '',
      postalCode: json['postal_code'] ?? '',
      orderTotalPrice: totalPrice,
      orderExtraNotes: json['extra_notes'],
      items: orderItems, fullAddress: '',
    );
  }

  // Enhanced method to extract total price from JSON with multiple fallback strategies
  static double _extractTotalPrice(Map<String, dynamic> json) {
    // List of possible field names for total price
    final possibleFields = [
      'total_price',
      'order_total_price',
      'orderTotalPrice',
      'price',
      'total',
      'amount',
      'order_amount',
      'orderAmount',
      'totalPrice',
      'orderTotal'
    ];

    // Try each possible field
    for (String field in possibleFields) {
      if (json.containsKey(field)) {
        final parsed = _parseDouble(json[field]);
        if (parsed > 0.0) {
          return parsed;
        }
      }
    }

    return 0.0;
  }

  // Helper method to safely parse double values from dynamic input
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
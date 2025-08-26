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
  int? driverId; // Changed from late final to regular final
  String status; // Changed from late final to regular final
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
  final String brandName; // Keep as final String

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
    required this.items,
    required this.brandName,
  });

  String get fullAddress => '$streetAddress, $city, $county, $postalCode';

  // Helper method to check if this order belongs to TVP brand
  bool get isTVPOrder => brandName.toUpperCase() == 'TVP';

  // Helper method to get brand display name
  String get displayBrandName => brandName.isNotEmpty ? brandName : 'Unknown';

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // Enhanced price parsing with multiple fallback strategies
      double totalPrice = _extractTotalPrice(json);

      // Parse items first to potentially calculate total from items if main total is 0
      List<OrderItem> orderItems = [];
      if (json['items'] != null && json['items'] is List) {
        try {
          orderItems = (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList();
        } catch (e) {
          print('Error parsing order items: $e');
          orderItems = [];
        }
      }

      // If total price is 0 but we have items, calculate from items
      if (totalPrice == 0.0 && orderItems.isNotEmpty) {
        double calculatedTotal = orderItems.fold(0.0, (sum, item) => sum + item.itemTotalPrice);
        if (calculatedTotal > 0.0) {
          totalPrice = calculatedTotal;
        }
      }

      String brandName = _extractBrandName(json);

      return Order(
        orderId: json['order_id'],
        paymentType: json['payment_type']?.toString() ?? '',
        transactionId: json['transaction_id']?.toString(),
        orderType: json['order_type']?.toString() ?? '',
        driverId: _parseInt(json['driver_id']),
        status: json['status']?.toString() ?? '',
        createdAt: _parseDateTime(json['created_at']),
        changeDue: _parseDouble(json['change_due']),
        orderSource: json['order_source']?.toString() ?? '',
        customerName: json['customer_name']?.toString() ?? '',
        customerEmail: json['customer_email']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        streetAddress: json['street_address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        county: json['county']?.toString() ?? '',
        postalCode: json['postal_code']?.toString() ?? '',
        orderTotalPrice: totalPrice,
        orderExtraNotes: json['extra_notes']?.toString(),
        items: orderItems,
        brandName: brandName,
      );
    } catch (e) {
      print('Error creating Order from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper method to extract brand name from JSON
  static String _extractBrandName(Map<String, dynamic> json) {
    // List of possible field names for brand name
    final possibleFields = [
      'brand_name',
      'brandName',
      'brand',
      'client_id',
      'clientId',
    ];

    for (String field in possibleFields) {
      if (json.containsKey(field) && json[field] != null) {
        String value = json[field].toString().trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    // Default to TVP if no brand found (since this is a TVP driver app)
    return 'TVP';
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

  // Helper method to safely parse integer values
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    return null;
  }

  // Helper method to safely parse DateTime values
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  // Method to update order status (useful for real-time updates)
  Order copyWith({
    int? orderId,
    String? paymentType,
    String? transactionId,
    String? orderType,
    int? driverId,
    String? status,
    DateTime? createdAt,
    double? changeDue,
    String? orderSource,
    String? customerName,
    String? customerEmail,
    String? phoneNumber,
    String? streetAddress,
    String? city,
    String? county,
    String? postalCode,
    double? orderTotalPrice,
    String? orderExtraNotes,
    List<OrderItem>? items,
    String? brandName,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      paymentType: paymentType ?? this.paymentType,
      transactionId: transactionId ?? this.transactionId,
      orderType: orderType ?? this.orderType,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      changeDue: changeDue ?? this.changeDue,
      orderSource: orderSource ?? this.orderSource,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      county: county ?? this.county,
      postalCode: postalCode ?? this.postalCode,
      orderTotalPrice: orderTotalPrice ?? this.orderTotalPrice,
      orderExtraNotes: orderExtraNotes ?? this.orderExtraNotes,
      items: items ?? this.items,
      brandName: brandName ?? this.brandName,
    );
  }

  @override
  String toString() {
    return 'Order(orderId: $orderId, status: $status, brand: $brandName, customer: $customerName)';
  }
}
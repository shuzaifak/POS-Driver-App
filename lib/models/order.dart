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
  final int? driverId;
  final String status;
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
    required this.items,
  });

  String get fullAddress => '$streetAddress, $city, $county, $postalCode';

  factory Order.fromJson(Map<String, dynamic> json) {
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
      orderTotalPrice: _parseDouble(json['total_price']),
      orderExtraNotes: json['extra_notes'],
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
    );
  }

  // Helper method to safely parse double values from dynamic input
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
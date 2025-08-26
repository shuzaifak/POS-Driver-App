import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../utils/theme.dart';
import 'order_details_modal.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String orderType;
  final int? deliveryNumber; // Add this new parameter

  const OrderCard({
    super.key,
    required this.order,
    required this.orderType,
    this.deliveryNumber, // Add this optional parameter
  });

  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => OrderDetailsModal(order: order),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    if (orderType == 'completed' && deliveryNumber != null)
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFAF97CD),
                              Color(0xFFC2A0DA),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.surgeColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$deliveryNumber',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Order ID and Status
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: orderType == 'my' ? 16 : 14, // Larger for picked orders
                              vertical: orderType == 'my' ? 10 : 8,    // Larger for picked orders
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '#${order.orderId}',
                              style: GoogleFonts.poppins(
                                fontSize: orderType == 'my' ? 23 : 18,  // Larger for picked orders
                                fontWeight: FontWeight.w800,
                                color: AppTheme.surgeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                    ),

                    // Action Button (only for non-completed orders)
                    if (orderType != 'completed')
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getActionColor(orderType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getActionColor(orderType).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleActionTap(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Icon(
                              _getActionIcon(orderType),
                              size: 22,
                              color: _getActionColor(orderType),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // PROMINENT TOTAL AMOUNT AND PAYMENT TYPE SECTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.surgeColor.withOpacity(0.08),
                        AppTheme.surgeColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.surgeColor.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Amount - Moderately Large and Bold
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.surgeColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '£${order.orderTotalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.surgeColor,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),

                      // Payment Type - Moderate Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: (order.paymentType.toLowerCase() == 'cash' ||
                              order.paymentType.toLowerCase() == 'cod')
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (order.paymentType.toLowerCase() == 'cash' ||
                                order.paymentType.toLowerCase() == 'cod')
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (order.paymentType.toLowerCase() == 'cash' ||
                                  order.paymentType.toLowerCase() == 'cod')
                                  ? Icons.money_rounded
                                  : Icons.credit_card_rounded,
                              size: 18,
                              color: (order.paymentType.toLowerCase() == 'cash' ||
                                  order.paymentType.toLowerCase() == 'cod')
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              order.paymentType.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: (order.paymentType.toLowerCase() == 'cash' ||
                                    order.paymentType.toLowerCase() == 'cod')
                                    ? Colors.red.shade600
                                    : Colors.green.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Customer and Address Info - Aligned Icons
                Column(
                  children: [
                    // Customer Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrayColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.customerName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.phoneNumber,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Address - Conditionally Clickable
                    orderType == 'my'
                        ? Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openInGoogleMaps(context, order.fullAddress),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGrayColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.fullAddress,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppTheme.subtitleColor,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.navigation_rounded,
                                          size: 14,
                                          color: AppTheme.surgeColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap for directions',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.surgeColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                  color: AppTheme.surgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        : // Non-clickable address for ALL section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.lightGrayColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              order.fullAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.subtitleColor,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: AppTheme.lightGrayColor,
                ),

                const SizedBox(height: 16),

                // Bottom Row - Items Count (centered)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrayColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${order.items.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Method to open Google Maps with directions - Direct Navigation
  void _openInGoogleMaps(BuildContext context, String address) async {
    try {
      // Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening Google Maps...',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.surgeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Encode the address for URL
      final encodedAddress = Uri.encodeComponent(address);

      // Different URL schemes to try (in order of preference)
      final List<String> mapUrls = [
        // Google Maps app with directions (most preferred)
        'google.navigation:q=$encodedAddress',
        // Google Maps app fallback
        'comgooglemaps://?q=$encodedAddress',
        // Google Maps web with directions
        'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress',
        // Google Maps web search
        'https://maps.google.com/?q=$encodedAddress',
        // Generic geo intent (Android)
        'geo:0,0?q=$encodedAddress',
      ];

      bool mapOpened = false;

      // Try each URL scheme
      for (String urlString in mapUrls) {
        try {
          final uri = Uri.parse(urlString);

          // Check if this URL can be launched
          bool canLaunch = await canLaunchUrl(uri);

          if (canLaunch) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            mapOpened = true;
            debugPrint('Successfully opened maps with: $urlString');
            break;
          }
        } catch (e) {
          debugPrint('Failed to open with $urlString: $e');
          continue;
        }
      }

      // If no URL worked, show fallback dialog
      if (!mapOpened) {
        _showMapFallbackDialog(context, address);
      }

    } catch (e) {
      debugPrint('Error in _openInGoogleMaps: $e');
      _showMapFallbackDialog(context, address);
    }
  }

  void _showMapFallbackDialog(BuildContext context, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Open in Maps',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please install Google Maps or use your device\'s default maps app with this address:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.subtitleColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrayColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.surgeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // Copy to clipboard
                      Clipboard.setData(ClipboardData(text: address));
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Address copied to clipboard!'),
                          backgroundColor: AppTheme.surgeColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Text(
                      'Copy Address',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.surgeColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.surgeColor,
                          AppTheme.surgeColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'green':
        color = AppTheme.greenColor;
        text = 'Ready';
        icon = Icons.check_circle_outline;
        break;
      case 'yellow':
        color = AppTheme.yellowColor;
        text = 'Preparing';
        icon = Icons.schedule_rounded;
        break;
      case 'blue':
        color = AppTheme.blueColor;
        text = 'Delivered';
        icon = Icons.delivery_dining_rounded;
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12, // Increased from 10 to 12
        vertical: 8,    // Increased from 6 to 8
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18, // Increased from 14 to 18
            color: color,
          ),
          const SizedBox(width: 6), // Increased spacing from 4 to 6
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14, // Increased from 12 to 14
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String orderType) {
    switch (orderType) {
      case 'all':
        return AppTheme.surgeColor;
      case 'my':
        return AppTheme.greenColor;
      default:
        return AppTheme.surgeColor;
    }
  }

  IconData _getActionIcon(String orderType) {
    switch (orderType) {
      case 'all':
        return Icons.add_rounded;
      case 'my':
        return Icons.check_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  void _handleActionTap(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final ordersProvider = context.read<OrdersProvider>();

    if (authProvider.driver != null) {
      if (orderType == 'all') {
        // Accept order and move to my orders
        ordersProvider.acceptOrder(order.orderId, authProvider.driver!.id);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${order.orderId} accepted successfully!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.greenColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (orderType == 'my') {
        // Show dialog to choose between Mark as Delivered or Remove Order
        _showMyOrderActionsDialog(context, authProvider, ordersProvider);
      }
    }
  }

  void _showMyOrderActionsDialog(BuildContext context, AuthProvider authProvider, OrdersProvider ordersProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.surgeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Order Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'What would you like to do with order #${order.orderId}?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.subtitleColor,
            ),
          ),
          actions: [
            // Delivered Button - Primary action at top
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ordersProvider.completeOrder(order.orderId, authProvider.driver!.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order #${order.orderId} marked as delivered!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: AppTheme.blueColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delivered', // Changed from "Mark as Delivered"
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Remove Order Button - Secondary action at bottom, smaller
            Container(
              width: double.infinity,
              height: 44, // Smaller height
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEF4444),
                    Color(0xFFDC2626),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ordersProvider.removeOrder(order.orderId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order #${order.orderId} removed and returned to available orders!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 8), // Smaller padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white,
                      size: 18, // Slightly smaller icon
                    ),
                    const SizedBox(width: 6), // Smaller spacing
                    Text(
                      'Remove Order',
                      style: GoogleFonts.poppins(
                        fontSize: 13, // Smaller font size
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../utils/theme.dart';
import 'order_details_modal.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final String orderType;

  const OrderCard({
    Key? key,
    required this.order,
    required this.orderType,
  }) : super(key: key);

  @override
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
                    // Order ID and Status
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surgeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#${order.orderId}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.surgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                    ),

                    // Action Button
                    if (orderType != 'completed')
                      Container(
                        width: 36,
                        height: 36,
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
                              size: 18,
                              color: _getActionColor(orderType),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer Info
                Row(
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

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: AppTheme.lightGrayColor,
                ),

                const SizedBox(height: 16),

                // Bottom Row - Price and Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '£${order.orderTotalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.surgeColor,
                          ),
                        ),
                      ],
                    ),

                    // Items Count and Payment
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrayColor,
                            borderRadius: BorderRadius.circular(6),
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
                        const SizedBox(height: 4),
                        Text(
                          order.paymentType.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
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
        // Mark as delivered and move to completed
        ordersProvider.completeOrder(order.orderId, authProvider.driver!.id);

        // Show success snackbar
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
      }
    }
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../services/socket_service.dart';
import '../widgets/order_card.dart';
import '../utils/theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../widgets/order_details_modal.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late SocketService _socketService;
  bool _isScreenInitialized = false;
  bool _isShowingNewOrderPopup = false;
  late OrdersProvider _ordersProvider;
  final Set<int> _allSeenOrderIds = <int>{};
  final List<OverlayEntry> _activePopups = [];
  Timer? _popupResetTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Get socket service reference
    _socketService = context.read<SocketService>();

    // CRITICAL: Setup socket callback BEFORE connecting
    _setupSocketCallback();

    // Connect socket service
    _socketService.connect();

    // Initial load and setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ordersProvider = context.read<OrdersProvider>();
        _ordersProvider.loadOrders().then((_) {
          // Mark screen as initialized after first load
          if (mounted) {
            setState(() {
              _isScreenInitialized = true;

              // Initialize seen order IDs with all current orders
              _allSeenOrderIds.addAll(_ordersProvider.allOrders.map((o) => o.orderId));
              _allSeenOrderIds.addAll(_ordersProvider.myOrders.map((o) => o.orderId));
              _allSeenOrderIds.addAll(_ordersProvider.completedOrders.map((o) => o.orderId));
            });
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ordersProvider = context.read<OrdersProvider>();
  }


  @override
  void dispose() {
    _tabController.dispose();

    // Cancel popup reset timer
    _popupResetTimer?.cancel();

    // Remove all active popups
    for (final popup in _activePopups) {
      popup.remove();
    }
    _activePopups.clear();

    // Clear the active popups set
    _ordersWithActivePopups.clear();

    // Use the saved provider reference instead of context.read
    _ordersProvider.stopSmartPolling();
    // Keep socket connected for background notifications
    super.dispose();
  }

  void _setupSocketCallback() {
    print('🔗 OrdersScreen: Setting up socket callback...');

    _socketService.setOnOrderStatusChanged((data) {
      print('🔔 OrdersScreen: Socket event received, forwarding to OrdersProvider');
      print('🔔 Event data: $data');

      if (mounted) {
        context.read<OrdersProvider>().handleSocketUpdate(data);
      } else {
        print('❌ OrdersScreen: Widget not mounted, ignoring socket update');
      }
    });

    print('✅ OrdersScreen: Socket callback setup complete');
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.surgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Surge Driver',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
        actions: [
          // Day End Report Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  size: 20,
                  color: AppTheme.surgeColor,
                ),
              ),
              onPressed: () => _generateDayEndReport(),
            ),
          ),

          // Refresh Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrayColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppTheme.textColor,
                ),
              ),
              onPressed: () async {
                // Force reconnect socket if not connected
                if (!_socketService.isConnected) {
                  print('🔌 OrdersScreen: Reconnecting socket...');
                  _socketService.connect();
                  await Future.delayed(const Duration(milliseconds: 500));
                }

                // Force reload orders (this will restart smart polling)
                print('🔄 OrdersScreen: Force reloading orders...');
                final ordersProvider = context.read<OrdersProvider>();
                await ordersProvider.loadOrders();

                // Show feedback to user
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Orders refreshed'),
                      duration: Duration(seconds: 1),
                      backgroundColor: AppTheme.surgeColor,
                    ),
                  );
                }
              },
            ),
          ),

          // Logout Button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Colors.red.shade600,
                ),
              ),
              onPressed: () {
                _showLogoutDialog(context);
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrayColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.surgeColor,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.subtitleColor,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    labelPadding: EdgeInsets.zero,
                    tabs: [
                      Container(
                        height: 42,
                        child: Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.list_alt_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'All',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 42,
                        child: Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Mine',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 42,
                        child: Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Done',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, _) {
          // Check for new orders ONLY when screen is initialized and not already showing popup
          if (_isScreenInitialized &&
              ordersProvider.allOrders.isNotEmpty &&
              !_isShowingNewOrderPopup) {

            // Use addPostFrameCallback to avoid navigation during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkForNewOrders(ordersProvider.allOrders);
              }
            });
          }

          if (ordersProvider.isLoading) {
            return _buildLoadingState();
          }

          if (ordersProvider.error != null) {
            return _buildErrorState(ordersProvider.error!, ordersProvider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(ordersProvider.allOrders, 'all'),
              _buildOrdersList(ordersProvider.myOrders, 'my'),
              _buildOrdersList(ordersProvider.completedOrders, 'completed'),
            ],
          );
        },
      )
    );
    }


  List _getTodaysCompletedOrders(List completedOrders) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    return completedOrders.where((order) {
      // Since we only have createdAt field, we'll use that for filtering
      // This assumes that orders in completedOrders list are already filtered by status
      final orderDate = order.createdAt;
      final orderDateOnly = DateTime(orderDate.year, orderDate.month, orderDate.day);
      return orderDateOnly.isAtSameMomentAs(todayDateOnly);
    }).toList();
  }

// Replace the _generateDayEndReport method with this corrected version
  Future<void> _generateDayEndReport() async {
    try {
      // Use the saved provider reference instead of context.read
      final ordersProvider = _ordersProvider;

      // Filter only today's completed orders
      final todaysCompletedOrders = _getTodaysCompletedOrders(ordersProvider.completedOrders);

      if (todaysCompletedOrders.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No completed orders found for today',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.surgeColor),
                const SizedBox(height: 16),
                Text(
                  'Generating report...',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm');

      // Calculate totals for today only
      double totalAmount = 0;
      int totalDeliveries = todaysCompletedOrders.length;

      for (var order in todaysCompletedOrders) {
        totalAmount += order.orderTotalPrice ?? 0;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SURGE DRIVER',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple,
                            ),
                          ),
                          pw.Text(
                            'Day End Report - ${dateFormatter.format(now)}',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Date: ${dateFormatter.format(now)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            'Generated: ${timeFormatter.format(now)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 2, color: PdfColors.purple),
                  pw.SizedBox(height: 20),
                ],
              ),

              // Summary Section
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'Today\'s Deliveries',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$totalDeliveries',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.purple,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Total Amount',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'Average Order',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '\$${totalDeliveries > 0 ? (totalAmount / totalDeliveries).toStringAsFixed(2) : '0.00'}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Orders Table
              pw.Text(
                'Today\'s Completed Orders Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.purple,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Order #',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Customer',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Address',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Payment',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Data Rows - using today's completed orders only
                  ...todaysCompletedOrders.map((order) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '#${order.orderId}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            order.customerName ?? 'N/A',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${order.streetAddress ?? ''}, ${order.city ?? ''}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            order.paymentType ?? 'N/A',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '\$${(order.orderTotalPrice ?? 0).toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Text(
                'Report generated on ${dateFormatter.format(now)} at ${timeFormatter.format(now)}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            ];
          },
        ),
      );

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show PDF preview and download options
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'surge_driver_report_${dateFormatter.format(now).replaceAll('/', '_')}.pdf',
        );
      }

    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating report: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Add this new Set to track orders whose popups are currently showing
  final Set<int> _ordersWithActivePopups = <int>{};

  void _checkForNewOrders(List<dynamic> currentOrders) {
    // Don't check if already showing a popup
    if (_isShowingNewOrderPopup) {
      print('🚫 Already showing popup, skipping check');
      return;
    }

    // Get NEW orders that haven't been seen before (only from the "All Orders" tab)
    final newOrders = <dynamic>[];

    // Check only current "All Orders" tab for truly new orders
    for (var order in currentOrders) {
      // Only consider orders that are not completed/delivered/cancelled and haven't been seen
      if (!['completed', 'delivered', 'cancelled'].contains(order.status?.toLowerCase()) &&
          !_allSeenOrderIds.contains(order.orderId)) {
        newOrders.add(order);
      }
    }

    // Sort new orders by orderId to ensure consistent order (oldest first)
    newOrders.sort((a, b) => a.orderId.compareTo(b.orderId));

    // Fix: Create Set<int> properly
    final newOrderIds = newOrders.map((order) => order.orderId as int).toSet();

    print('🔍 Checking for new orders:');
    print('   New order IDs found: $newOrderIds');
    print('   Previously seen IDs count: ${_allSeenOrderIds.length}');

    if (newOrders.isNotEmpty && mounted) {
      print('🆕 Found ${newOrders.length} new orders to show popup for');

      // CRITICAL: IMMEDIATELY mark these orders as seen and hide their cards
      // This prevents them from showing in the UI before the popup
      _allSeenOrderIds.addAll(newOrderIds);
      _ordersWithActivePopups.addAll(newOrderIds);

      // IMMEDIATELY trigger a rebuild to hide the cards
      setState(() {
        _isShowingNewOrderPopup = true;
      });

      // Cancel any existing reset timer
      _popupResetTimer?.cancel();

      print('🚀 Showing popup for new orders: ${newOrders.map((o) => o.orderId).toList()}');

      // Show popup for each new order with staggered timing (in correct order)
      for (int i = 0; i < newOrders.length; i++) {
        Timer(Duration(seconds: i * 10), () { // 10 seconds between popups
          if (mounted) {
            print('📱 Showing popup for order: ${newOrders[i].orderId}');
            _showNewOrderPopup(newOrders[i], i);
          }
        });
      }

      // Vibrate to alert driver
      HapticFeedback.mediumImpact();

      // Reset flag after reasonable time
      // Each popup shows for 8 seconds + 10 second gaps between them
      int totalTimeMs = (newOrders.length * 10 * 1000) + (8 * 1000);

      _popupResetTimer = Timer(Duration(milliseconds: totalTimeMs), () {
        if (mounted) {
          _isShowingNewOrderPopup = false;
          print('🔄 Reset popup flag - ready for new orders');
        }
      });
    }

    // Update seen orders with ALL current orders to keep track
    final allCurrentOrderIds = <int>{};

    // Add from current orders (All Orders tab)
    allCurrentOrderIds.addAll(currentOrders.map((o) => o.orderId as int));

    // Also add from other tabs to maintain complete tracking
    final ordersProvider = context.read<OrdersProvider>();
    allCurrentOrderIds.addAll(ordersProvider.myOrders.map((o) => o.orderId as int));
    allCurrentOrderIds.addAll(ordersProvider.completedOrders.map((o) => o.orderId as int));

    _allSeenOrderIds.addAll(allCurrentOrderIds);

    print('📝 Updated seen order IDs count: ${_allSeenOrderIds.length}');
  }

  void _showNewOrderPopup(dynamic order, int index) {
    if (!mounted) return;

    print('📱 Showing popup for order: ${order.orderId}');

    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    late AnimationController animationController;

    // Function to handle popup dismissal
    void dismissPopup() {
      // Remove from active popups set to show the card
      _ordersWithActivePopups.remove(order.orderId);
      _removePopupWithAnimation(overlayEntry, animationController);

      // Trigger rebuild to show the order card
      if (mounted) {
        setState(() {});
      }
    }

    // Create animation controller
    animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0 + (index * 130.0), // Stack popups vertically with more space
        right: 16.0,
        left: 16.0,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.2, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animationController,
                curve: Curves.elasticOut,
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animationController,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppTheme.surgeColor.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.surgeColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Header with pulsing effect
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFAF97CD),
                                Color(0xFFC2A0DA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.surgeColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '🚀 New Order Alert!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.surgeColor.withOpacity(0.1),
                                      AppTheme.surgeColor.withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Order #${order.orderId}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.surgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: dismissPopup,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.subtitleColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Order Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrayColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (order.customerName != null) ...[
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    order.customerName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (order.orderTotalPrice != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '£${order.orderTotalPrice.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Address info if available
                          if (order.streetAddress != null) ...[
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${order.streetAddress}${order.city != null ? ', ${order.city}' : ''}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.subtitleColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: dismissPopup,
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    'Dismiss',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFAF97CD),
                                  Color(0xFFC2A0DA),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.surgeColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  dismissPopup();
                                  // Open order details modal
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => OrderDetailsModal(order: order),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'View Details',
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Add to active popups list
    _activePopups.add(overlayEntry);

    // Insert the overlay
    overlay.insert(overlayEntry);

    // Start animation
    animationController.forward();

    // Auto dismiss after 8 seconds
    Timer(const Duration(seconds: 2), () {
      dismissPopup();
    });
  }

  void _removePopupWithAnimation(OverlayEntry overlayEntry, AnimationController animationController) {
    if (_activePopups.contains(overlayEntry)) {
      // Animate out
      animationController.reverse().then((_) {
        if (_activePopups.contains(overlayEntry)) {
          overlayEntry.remove();
          _activePopups.remove(overlayEntry);
          animationController.dispose();
        }
      });
    }
  }

  Widget _buildOrdersList(List orders, String type) {
    // Filter out orders with active popups only for "all" tab
    List filteredOrders = orders;
    if (type == 'all') {
      filteredOrders = orders.where((order) =>
      !_ordersWithActivePopups.contains(order.orderId)
      ).toList();
    }

    if (filteredOrders.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getEmptyStateIcon(type),
                    size: 60,
                    color: AppTheme.subtitleColor,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _getEmptyStateTitle(type),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _getEmptyStateSubtitle(type),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<OrdersProvider>().loadOrders();
        },
        color: AppTheme.surgeColor,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            // For completed orders, calculate delivery number (newest = highest number)
            int? deliveryNumber;
            if (type == 'completed') {
              deliveryNumber = filteredOrders.length - index; // Reverse numbering so newest is highest
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OrderCard(
                order: filteredOrders[index],
                orderType: type,
                deliveryNumber: deliveryNumber, // Pass the delivery number
              ),
            );
          },
        ),
      ),
    );
  }




  Widget _buildLoadingState() {
    return Container(
      color: AppTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.surgeColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.surgeColor,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading orders...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we fetch your orders',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, OrdersProvider ordersProvider) {
    return Container(
      color: AppTheme.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Colors.red.shade100,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFFA855F7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.surgeColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  ordersProvider.loadOrders();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Try Again',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  IconData _getEmptyStateIcon(String type) {
    switch (type) {
      case 'all':
        return Icons.inbox_rounded;
      case 'my':
        return Icons.assignment_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.inbox_rounded;
    }
  }

  String _getEmptyStateTitle(String type) {
    switch (type) {
      case 'all':
        return 'No orders available';
      case 'my':
        return 'No active orders';
      case 'completed':
        return 'No completed orders';
      default:
        return 'No orders found';
    }
  }

  String _getEmptyStateSubtitle(String type) {
    switch (type) {
      case 'all':
        return 'New orders will appear here when they\'re available for pickup';
      case 'my':
        return 'Orders you accept will appear here';
      case 'completed':
        return 'Your completed deliveries will be shown here';
      default:
        return 'Check back later for new orders';
    }
  }

  void _showLogoutDialog(BuildContext context) {
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.subtitleColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.subtitleColor,
                ),
              ),
            ),
            Container(
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
                  context.read<AuthProvider>().logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
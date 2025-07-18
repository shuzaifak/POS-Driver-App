import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../services/socket_service.dart';
import '../widgets/order_card.dart';
import '../utils/theme.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _socketService = context.read<SocketService>();
    _socketService.connect();
    _socketService.setOnOrderStatusChanged((data) {
      context.read<OrdersProvider>().handleSocketUpdate(data);
    });

    // Load orders on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socketService.disconnect();
    super.dispose();
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
              onPressed: () {
                context.read<OrdersProvider>().loadOrders();
              },
            ),
          ),
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

  Widget _buildOrdersList(List orders, String type) {
    if (orders.isEmpty) {
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OrderCard(order: orders[index], orderType: type),
            );
          },
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Add these variables to track field-specific errors
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Method to handle authentication errors
  void _handleAuthError(String error) {
    setState(() {
      // Clear previous errors
      _usernameError = null;
      _passwordError = null;

      // Check error type and assign to appropriate field
      if (error.toLowerCase().contains('username') ||
          error.toLowerCase().contains('user not found') ||
          error.toLowerCase().contains('invalid username')) {
        _usernameError = 'Invalid username';
      } else if (error.toLowerCase().contains('password') ||
          error.toLowerCase().contains('incorrect password') ||
          error.toLowerCase().contains('invalid password')) {
        _passwordError = 'Invalid password';
      } else if (error.toLowerCase().contains('invalid credentials') ||
          error.toLowerCase().contains('login failed')) {
        // If it's a general authentication error, show it under password field
        _passwordError = 'Invalid username or password';
      } else {
        // For any other error, show under password field
        _passwordError = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB7A8D5),// Purple from design
              Color(0xFFC4ADE4),// Purple // Light purple background
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container - Increased size and optimized spacing
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/sLogo.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subtitle only - removed "Surge Driver" title
                      Text(
                        'Sign in to start delivering',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Login Form Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Text
                              Text(
                                'Welcome back!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please enter your credentials to continue',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Username Field
                              Text(
                                'Username',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your username',
                                  hintStyle: GoogleFonts.poppins(
                                    color: AppTheme.subtitleColor,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.person_outline,
                                      color: AppTheme.surgeColor,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.lightGrayColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.surgeColor,
                                      width: 2,
                                    ),
                                  ),
                                  // Add error border styling
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  // Return username-specific error if exists
                                  if (_usernameError != null) {
                                    return _usernameError;
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Clear username error when user starts typing
                                  if (_usernameError != null) {
                                    setState(() {
                                      _usernameError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              Text(
                                'Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: GoogleFonts.poppins(
                                    color: AppTheme.subtitleColor,
                                  ),
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      color: AppTheme.surgeColor,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.subtitleColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.lightGrayColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.surgeColor,
                                      width: 2,
                                    ),
                                  ),
                                  // Add error border styling
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  // Return password-specific error if exists
                                  if (_passwordError != null) {
                                    return _passwordError;
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Clear password error when user starts typing
                                  if (_passwordError != null) {
                                    setState(() {
                                      _passwordError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return Container(
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
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : () => _login(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: authProvider.isLoading
                                          ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.login_rounded,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Sign In',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Remove the error message container since errors now show under fields
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _login(BuildContext context) {
    // Clear previous errors
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      // Store the current error state
      String? previousError = authProvider.error;

      authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // Listen for auth changes to handle errors
      authProvider.addListener(() {
        if (authProvider.error != null && authProvider.error != previousError) {
          _handleAuthError(authProvider.error!);
          // Trigger form validation to show the error
          _formKey.currentState!.validate();
        }
      });
    }
  }
}
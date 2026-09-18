import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';

enum TaskerAuthScreenView { welcome, signIn, signUp }

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double w = size.width;
    final double h = size.height;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, -0.6, 1.2, false, bluePaint);
    canvas.drawArc(rect, 0.6, 1.6, false, greenPaint);
    canvas.drawArc(rect, 2.2, 1.6, false, yellowPaint);
    canvas.drawArc(rect, 3.8, 1.6, false, redPaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.44, h * 0.40, w * 0.96, h * 0.60),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GreenWaveSpherePainter extends CustomPainter {
  const GreenWaveSpherePainter({this.isHeaderOnly = false});

  final bool isHeaderOnly;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;
    if (w.isNaN || h.isNaN || w.isInfinite || h.isInfinite) return;

    // 1. Base Gradient Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF03221A),
          Color(0xFF00382B),
          Color(0xFF005844),
          Color(0xFF02362A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Fluid Wave 1 (Deep Emerald wave)
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.40, 0)
      ..cubicTo(w * 0.25, h * 0.18, w * 0.92, h * 0.15, w * 0.85, h * 0.40)
      ..cubicTo(w * 0.78, h * 0.65, w * 0.25, h * 0.55, w * 0.20, h * 0.85)
      ..cubicTo(w * 0.18, h * 0.92, w * 0.30, h * 0.98, w * 0.40, h)
      ..lineTo(0, h)
      ..close();

    final wavePaint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF004D3B).withValues(alpha: 0.90),
          const Color(0xFF007A5E).withValues(alpha: 0.75),
          const Color(0xFF00382B).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path1, wavePaint1);

    // 3. Fluid Wave 2 (Luminous Mint accent wave)
    final path2 = Path()
      ..moveTo(w, 0)
      ..lineTo(w * 0.52, 0)
      ..cubicTo(w * 0.58, h * 0.12, w * 0.95, h * 0.20, w * 0.82, h * 0.45)
      ..cubicTo(w * 0.65, h * 0.70, w * 0.95, h * 0.80, w, h * 0.90)
      ..close();

    final wavePaint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFF50FFC7).withValues(alpha: 0.35),
          const Color(0xFF00B37E).withValues(alpha: 0.60),
          const Color(0xFF004D3B).withValues(alpha: 0.20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path2, wavePaint2);

    // Helper: Draw realistic 3D sphere with radial gradient lighting and ambient shadow
    void drawSphere({
      required Offset center,
      required double radius,
      required Color lightColor,
      required Color midColor,
      required Color darkColor,
      double shadowBlur = 24,
    }) {
      if (radius <= 0 || radius.isNaN || radius.isInfinite) return;
      if (center.dx.isNaN || center.dy.isNaN) return;

      // Soft Ambient Drop Shadow
      final safeBlur = shadowBlur > 0 ? shadowBlur : 1.0;
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, safeBlur);
      canvas.drawCircle(
        center.translate(safeBlur * 0.2, safeBlur * 0.35),
        radius,
        shadowPaint,
      );

      // 3D Sphere Body
      final lightOffset = Offset(center.dx - radius * 0.35, center.dy - radius * 0.35);
      final spherePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 1.15,
          colors: [
            lightColor,
            midColor,
            darkColor,
            darkColor.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, spherePaint);

      // Specular Highlight
      final gleamPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0),
          radius: 0.6,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: lightOffset, radius: radius * 0.45));
      canvas.drawCircle(lightOffset, radius * 0.45, gleamPaint);
    }

    // 1. Top Left Dark Sphere
    drawSphere(
      center: Offset(w * 0.16, h * 0.12),
      radius: w * 0.12,
      lightColor: const Color(0xFF007558),
      midColor: const Color(0xFF00382B),
      darkColor: const Color(0xFF011A14),
      shadowBlur: 16,
    );

    // 2. Top Right Bright Luminous Sphere
    drawSphere(
      center: Offset(w * 0.72, h * (isHeaderOnly ? 0.45 : 0.23)),
      radius: w * 0.17,
      lightColor: const Color(0xFFFFFFFF),
      midColor: const Color(0xFFB5FFE4),
      darkColor: const Color(0xFF00A877),
      shadowBlur: 26,
    );

    if (!isHeaderOnly) {
      // 3. Mid-Bottom Left Medium Sphere
      drawSphere(
        center: Offset(w * 0.18, h * 0.64),
        radius: w * 0.085,
        lightColor: const Color(0xFFE8FFF7),
        midColor: const Color(0xFF88F6CE),
        darkColor: const Color(0xFF00805C),
        shadowBlur: 14,
      );

      // 4. Bottom Right Large Sphere
      drawSphere(
        center: Offset(w * 0.50, h * 0.76),
        radius: w * 0.20,
        lightColor: const Color(0xFF00E6A3),
        midColor: const Color(0xFF008F67),
        darkColor: const Color(0xFF013023),
        shadowBlur: 32,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TaskerAuthScreen extends StatefulWidget {
  const TaskerAuthScreen({
    super.key,
    required this.onAuthenticated,
  });

  final ValueChanged<TaskerProfile> onAuthenticated;

  @override
  State<TaskerAuthScreen> createState() => _TaskerAuthScreenState();
}

class _TaskerAuthScreenState extends State<TaskerAuthScreen> {
  TaskerAuthScreenView _currentView = TaskerAuthScreenView.welcome;

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscurePassword = true;
  bool _rememberMe = false;

  // Signup controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  String _selectedCategory = 'Cleaning';
  String _selectedCounty = 'Nairobi';
  String _selectedLocation = 'Westlands';
  bool _signupObscurePassword = true;
  bool _signupObscureConfirmPassword = true;
  bool _agreeDataProcessing = false;

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  String? _successMessage;

  static const List<String> _skillCategories = [
    'Cleaning',
    'Handyman',
    'Cooking',
    'Babysitting',
    'Moving',
    'Laundry',
    'Deliveries',
    'Errands',
  ];

  StreamSubscription<AuthState>? _authSubscription;
  bool _authHandled = false;

  @override
  void initState() {
    super.initState();
    _rememberMe = false;
    _agreeDataProcessing = false;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      if (!_authHandled && (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) && session != null) {
        _authHandled = true;
        _onGoogleTaskerAuthenticated(session.user, session);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'TP';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    try {
      final res = await ApiService.login(
        phoneOrEmail: email,
        password: password,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final defaultName = email.contains('@')
            ? email.split('@').first
            : 'Pro Tasker';
        final profile = TaskerProfile(
          name: defaultName,
          avatar: _getInitials(defaultName),
          skill: '$_selectedCategory Specialist',
          rating: 0.0,
          distance: '0 km',
          matchScore: 0,
          completionRate: 0,
          reviews: 0,
          verified: false,
        );

        widget.onAuthenticated(profile);
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Sign in failed. Please check your credentials.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred during sign in. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) {
      final email = _signupEmailController.text.trim();
      final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      setState(() {
        if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
          _errorMessage = 'Invalid email address. Please enter a valid email (e.g. name@example.com).';
        } else {
          _errorMessage = 'Please fix the errors highlighted below to continue.';
        }
      });
      return;
    }
    if (!_agreeDataProcessing) {
      setState(() {
        _errorMessage = 'Please agree to the processing of personal data to proceed.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final rawPhone = _signupPhoneController.text.trim();
    final phone = rawPhone.startsWith('+')
        ? rawPhone
        : (rawPhone.startsWith('0') ? '+254${rawPhone.substring(1)}' : '+254$rawPhone');
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    try {
      final res = await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        idNumber: '12345678',
        categories: [_selectedCategory],
        city: _selectedCounty,
        area: _selectedLocation,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _loginEmailController.text = email;
        _signupPasswordController.clear();
        _signupConfirmPasswordController.clear();
        _loginPasswordController.clear();

        final successMsg = res['message'] ?? 'Pro account created successfully! Please sign in to continue.';
        setState(() {
          _successMessage = successMsg;
          _errorMessage = null;
          _currentView = TaskerAuthScreenView.signIn;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    successMsg,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00B37E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Sign up failed. Please check your details.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to connect. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onGoogleTaskerAuthenticated(User user, Session session) async {
    final email = user.email ?? '';
    final fullName = (user.userMetadata?['full_name'] as String?) ??
        (user.userMetadata?['name'] as String?) ??
        (email.contains('@') ? email.split('@').first : 'Pro Tasker');
    final avatar = _getInitials(fullName);

    final googleTasker = TaskerProfile(
      name: fullName,
      avatar: avatar,
      skill: '$_selectedCategory Specialist',
      rating: 0.0,
      distance: '0 km',
      matchScore: 0,
      completionRate: 0,
      reviews: 0,
      verified: false,
    );

    // Sync with backend PostgreSQL database as tasker
    try {
      await ApiService.googleSignIn(
        email: email,
        name: fullName,
        photoUrl: user.userMetadata?['avatar_url'] as String?,
        idToken: session.accessToken,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Signed in as Pro Tasker: $fullName')),
          ],
        ),
        backgroundColor: const Color(0xFF00B37E),
        behavior: SnackBarBehavior.floating,
      ),
    );

    widget.onAuthenticated(googleTasker);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/'
          : 'io.supabase.flutter://login-callback/';

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );

      // Check if session became available immediately
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && !_authHandled) {
        _authHandled = true;
        await _onGoogleTaskerAuthenticated(session.user, session);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Supabase Google Sign-In error: ${e.message}';
        _isGoogleLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Google Sign-In failed: $e';
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: switch (_currentView) {
          TaskerAuthScreenView.welcome => _buildWelcomeScreen(),
          TaskerAuthScreenView.signIn => _buildSignInScreen(),
          TaskerAuthScreenView.signUp => _buildSignUpScreen(),
        },
      ),
    );
  }

  // ==========================================
  // SCREEN 1: ONBOARDING / WELCOME SCREEN
  // ==========================================
  Widget _buildWelcomeScreen() {
    return Stack(
      key: const ValueKey('tasker_welcome_screen'),
      children: [
        // 3D Wave and Sphere Background
        Positioned.fill(
          child: CustomPaint(
            painter: const GreenWaveSpherePainter(isHeaderOnly: false),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              const Spacer(flex: 3),

              // Centered Title (White Taskly Logo + PRO badge) & Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/tasklylogo.png',
                          height: 56,
                          fit: BoxFit.contain,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFF00B37E),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter personal details to access your\nTasker Pro workforce account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 4),

              // Bottom Segmented Nav Bar (Sign in / Sign up)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Sign in Button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _errorMessage = null;
                                _currentView = TaskerAuthScreenView.signIn;
                              });
                            },
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                            child: const Center(
                              child: Text(
                                'Sign in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Sign up Pill Button
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.isDarkMode ? const Color(0xFF1E2622) : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _errorMessage = null;
                                  _currentView = TaskerAuthScreenView.signUp;
                                });
                              },
                              borderRadius: BorderRadius.circular(28),
                              child: const Center(
                                child: Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Color(0xFF00B37E),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 2: SIGN IN / LOGIN SCREEN
  // ==========================================
  Widget _buildSignInScreen() {
    final isDark = AppColors.isDarkMode;
    final surfaceColor = isDark ? const Color(0xFF131A17) : Colors.white;

    return Stack(
      key: const ValueKey('tasker_signin_screen'),
      children: [
        // Top 260px Wave Header Background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 260,
          child: CustomPaint(
            painter: const GreenWaveSpherePainter(isHeaderOnly: true),
          ),
        ),

        // Foreground Layout: Back button on top + Scrollable Form Card below
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(),
                ),
              ),
              const SizedBox(height: 50),

              // Bottom Sheet Form Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Form(
                            key: _loginFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo & Title
                                Center(
                                  child: Image.asset(
                                    'assets/images/tasklylogo.png',
                                    height: 42,
                                    fit: BoxFit.contain,
                                    color: AppColors.isDarkMode ? Colors.white : null,
                                    colorBlendMode: AppColors.isDarkMode ? BlendMode.srcIn : null,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Center(
                                  child: Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      color: Color(0xFF00B37E),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Success Banner
                                if (_successMessage != null) ...[
                                  _buildSuccessBanner(_successMessage!),
                                  const SizedBox(height: 16),
                                ],

                                // Error Banner
                                if (_errorMessage != null) ...[
                                  _buildErrorBanner(_errorMessage!),
                                  const SizedBox(height: 16),
                                ],

                                // Email Field
                                _buildFloatingField(
                                  label: 'Email or Phone',
                                  hint: 'kristin.watson@example.com',
                                  controller: _loginEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your email or phone';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Password Field
                                _buildFloatingField(
                                  label: 'Password',
                                  hint: '••••••••••••',
                                  controller: _loginPasswordController,
                                  obscureText: _loginObscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _loginObscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: isDark ? Colors.white60 : Colors.black45,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _loginObscurePassword = !_loginObscurePassword),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Remember Me & Forgot Password Row
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                activeColor: const Color(0xFF00B37E),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(5)),
                                                onChanged: (val) =>
                                                    setState(() => _rememberMe = val ?? false),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Remember me',
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Pro password reset link sent to your email.'),
                                            backgroundColor: Color(0xFF00B37E),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          color: Color(0xFF00B37E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),

                                // Sign in Button
                                _buildPrimaryButton(
                                  label: 'Sign in',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _handleLogin,
                                ),
                                const SizedBox(height: 22),

                                // Social Divider
                                _buildSocialDivider('Sign in with'),
                                const SizedBox(height: 18),

                                // Social Buttons Row
                                _buildSocialButtonsRow(),
                                const SizedBox(height: 22),

                                // Switch to Sign Up
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _errorMessage = null;
                                          _currentView = TaskerAuthScreenView.signUp;
                                        });
                                      },
                                      child: const Text(
                                        'Sign up',
                                        style: TextStyle(
                                          color: Color(0xFF00B37E),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 3: SIGN UP SCREEN
  // ==========================================
  Widget _buildSignUpScreen() {
    final isDark = AppColors.isDarkMode;
    final surfaceColor = isDark ? const Color(0xFF131A17) : Colors.white;

    return Stack(
      key: const ValueKey('tasker_signup_screen'),
      children: [
        // Top 260px Wave Header Background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 260,
          child: CustomPaint(
            painter: const GreenWaveSpherePainter(isHeaderOnly: true),
          ),
        ),

        // Foreground Layout: Back button on top + Scrollable Form Card below
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(),
                ),
              ),
              const SizedBox(height: 50),

              // Bottom Sheet Form Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Form(
                            key: _signupFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo & Title
                                Center(
                                  child: Image.asset(
                                    'assets/images/tasklylogo.png',
                                    height: 42,
                                    fit: BoxFit.contain,
                                    color: AppColors.isDarkMode ? Colors.white : null,
                                    colorBlendMode: AppColors.isDarkMode ? BlendMode.srcIn : null,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Center(
                                  child: Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Color(0xFF00B37E),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Error Banner
                                if (_errorMessage != null) ...[
                                  _buildErrorBanner(_errorMessage!),
                                  const SizedBox(height: 16),
                                ],

                                // Full Name Field
                                _buildFloatingField(
                                  label: 'Full Name',
                                  hint: 'e.g. Kristin Watson',
                                  controller: _signupNameController,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Email Field
                                _buildFloatingField(
                                  label: 'Email',
                                  hint: 'kristin.watson@example.com',
                                  controller: _signupEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
                                    if (!emailRegex.hasMatch(val.trim())) {
                                      return 'Please enter a valid email (e.g. name@example.com)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Phone Number Field
                                _buildFloatingField(
                                  label: 'Phone Number',
                                  hint: '0712 345 678',
                                  controller: _signupPhoneController,
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 14, right: 8, top: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '🇰🇪 +254',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: Color(0xFF00B37E),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '|',
                                          style: TextStyle(color: Colors.black26),
                                        ),
                                      ],
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    if (val.trim().length < 9) {
                                      return 'Please enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Primary Service Skill Dropdown
                                _buildSkillDropdown(),
                                const SizedBox(height: 18),

                                // County & Location Dynamic Dropdown Pickers
                                _buildLocationSelectors(isDark),
                                const SizedBox(height: 18),

                                // Password Field
                                _buildFloatingField(
                                  label: 'Password',
                                  hint: '••••••••••••',
                                  controller: _signupPasswordController,
                                  obscureText: _signupObscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _signupObscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: isDark ? Colors.white60 : Colors.black45,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _signupObscurePassword = !_signupObscurePassword),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Confirm Password Field
                                _buildFloatingField(
                                  label: 'Confirm Password',
                                  hint: '••••••••••••',
                                  controller: _signupConfirmPasswordController,
                                  obscureText: _signupObscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _signupObscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: isDark ? Colors.white60 : Colors.black45,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _signupObscureConfirmPassword = !_signupObscureConfirmPassword),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (val != _signupPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Processing of Personal Data Checkbox
                                InkWell(
                                  onTap: () => setState(() => _agreeDataProcessing = !_agreeDataProcessing),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: Checkbox(
                                            value: _agreeDataProcessing,
                                            activeColor: const Color(0xFF00B37E),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5)),
                                            onChanged: (val) =>
                                                setState(() => _agreeDataProcessing = val ?? false),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color:
                                                    isDark ? Colors.white70 : const Color(0xFF475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              children: const [
                                                TextSpan(text: 'I agree to the processing of '),
                                                TextSpan(
                                                  text: 'Personal data',
                                                  style: TextStyle(
                                                    color: Color(0xFF00B37E),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Sign up Button
                                _buildPrimaryButton(
                                  label: 'Sign up',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _handleSignup,
                                ),
                                const SizedBox(height: 22),

                                // Social Divider
                                _buildSocialDivider('Sign up with'),
                                const SizedBox(height: 18),

                                // Social Buttons Row
                                _buildSocialButtonsRow(),
                                const SizedBox(height: 22),

                                // Switch to Sign In
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _errorMessage = null;
                                          _currentView = TaskerAuthScreenView.signIn;
                                        });
                                      },
                                      child: const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: Color(0xFF00B37E),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SHARED UI HELPER WIDGETS
  // ==========================================

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _errorMessage = null;
            _currentView = TaskerAuthScreenView.welcome;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isDark = AppColors.isDarkMode;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            validator: validator,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              filled: true,
              fillColor: isDark ? const Color(0xFF1B231F) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2B3A33) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2B3A33) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF00B37E),
                  width: 1.8,
                ),
              ),
            ),
          ),
        ),

        // Floating label pill at top left
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: isDark ? const Color(0xFF131A17) : Colors.white,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B231F) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2B3A33) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF00B37E),
                size: 22,
              ),
              dropdownColor: isDark ? const Color(0xFF1B231F) : Colors.white,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: isDark ? const Color(0xFF131A17) : Colors.white,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelectors(bool isDark) {
    final locationsList = kenyaCountiesAndLocations[_selectedCounty] ?? ['General / CBD'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // County Dropdown
        Expanded(
          child: _buildDropdownField(
            label: 'County',
            value: _selectedCounty,
            items: kenyaCountiesAndLocations.keys.toList(),
            onChanged: (newCounty) {
              if (newCounty != null && newCounty != _selectedCounty) {
                setState(() {
                  _selectedCounty = newCounty;
                  final available = kenyaCountiesAndLocations[newCounty] ?? ['General / CBD'];
                  _selectedLocation = available.first;
                });
              }
            },
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 14),

        // Location / Sub-County Dropdown
        Expanded(
          child: _buildDropdownField(
            label: 'Location',
            value: locationsList.contains(_selectedLocation)
                ? _selectedLocation
                : locationsList.first,
            items: locationsList,
            onChanged: (newLoc) {
              if (newLoc != null) {
                setState(() {
                  _selectedLocation = newLoc;
                });
              }
            },
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillDropdown() {
    final isDark = AppColors.isDarkMode;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: isDark ? const Color(0xFF1A2420) : Colors.white,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              filled: true,
              fillColor: isDark ? const Color(0xFF1B231F) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2B3A33) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF2B3A33) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF00B37E),
                  width: 1.8,
                ),
              ),
            ),
            items: _skillCategories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text('$cat Service Specialist'),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
        ),

        // Floating label pill
        Positioned(
          left: 14,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: isDark ? const Color(0xFF131A17) : Colors.white,
            child: Text(
              'Primary Skill Specialty',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C78C), Color(0xFF00B37E), Color(0xFF008A61)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B37E).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider(String text) {
    final isDark = AppColors.isDarkMode;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF26332C) : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? const Color(0xFF26332C) : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtonsRow() {
    final isDark = AppColors.isDarkMode;

    return Center(
      child: InkWell(
        onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2822) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3C34) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGoogleLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                CustomPaint(
                  size: const Size(20, 20),
                  painter: GoogleLogoPainter(),
                ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google Pro',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B37E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00B37E).withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read_rounded, color: Color(0xFF00B37E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF00B37E),
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFF87171), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFF87171),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

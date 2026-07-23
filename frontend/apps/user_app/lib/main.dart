import 'package:ai_mock/ai_mock.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_components/shared_components.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_ui/shared_ui.dart';

const _heroPeople = 'public/images/people.jpg';
const _cleaningHero = 'public/images/cleaner.jpg';
const _cookingHero = 'public/images/cook.jpg';
const _movingHero = 'public/images/movers.jpg';
const _babysittingHero = 'public/images/babysitter.jpg';
const _deliveryHero = 'public/images/delivery.jpg';

final ValueNotifier<TasklyUser?> currentUserNotifier =
    ValueNotifier<TasklyUser?>(null);

void main() => runApp(const TasklyUserApp());

class TasklyUserApp extends StatelessWidget {
  const TasklyUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Taskly AI',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: AppAnimations.slow,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              _heroPeople,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.heroGradient),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.25),
                  AppColors.darkGreen.withOpacity(0.9),
                ],
              ),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.88, end: 1.0),
              duration: AppAnimations.slow,
              curve: AppAnimations.easeInOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TasklyLogo(size: 96),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'TASKLY AI',
                    style: context.type.displayMedium?.copyWith(
                      color: Colors.white,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Premium local help, matched by AI.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool register = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgBorder,
                boxShadow: AppShadows.card,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.lgBorder,
                child: SizedBox(
                  height: 250,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const PremiumImage(
                        url: _heroPeople,
                        height: 250,
                        radius: AppRadius.lg,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        top: 20,
                        child: TasklyLogo(size: 48),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              register ? 'Create your account' : 'Welcome back',
                              style: context.type.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Book trusted services with a premium AI concierge.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TasklySurface(
              child: Column(
                children: [
                  if (register) ...[
                    _InputField(
                      label: 'Full name',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _InputField(
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                    controller: _emailController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (register) ...[
                    _InputField(
                      label: 'Phone number',
                      icon: Icons.phone_android_rounded,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _InputField(
                    label: 'Password',
                    obscure: true,
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                  ),
                  if (register) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InputField(
                      label: 'Confirm password',
                      obscure: true,
                      icon: Icons.lock_outline_rounded,
                      controller: _confirmPasswordController,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  TasklyButton(
                    label: register ? 'Create account' : 'Log in',
                    icon: AppIcons.home,
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      // Show loading spinner
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );

                      if (register) {
                        final name = _nameController.text.trim();
                        final phone = _phoneController.text.trim();
                        final confirmPassword = _confirmPasswordController.text.trim();
                        if (name.isEmpty || phone.isEmpty || confirmPassword.isEmpty) {
                          Navigator.pop(context); // Dismiss spinner
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (password != confirmPassword) {
                          Navigator.pop(context); // Dismiss spinner
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final result = await ApiService.register(
                          name: name,
                          email: email,
                          phone: phone,
                          password: password,
                        );

                        Navigator.pop(context); // Dismiss spinner

                        if (result['success'] == true) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Check your Email', style: TextStyle(fontWeight: FontWeight.w900)),
                              content: Text(result['message'] ?? 'An activation link has been sent to your email.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      register = false;
                                    });
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Registration failed.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } else {
                        final result = await ApiService.login(
                          phoneOrEmail: email,
                          password: password,
                        );

                        Navigator.pop(context); // Dismiss spinner

                        if (result['success'] == true) {
                          // Create TasklyUser local session object
                          final userMap = result['user'];
                          final name = userMap != null ? userMap['full_name'] as String : 'User';
                          final emailStr = userMap != null ? userMap['email'] as String : email;
                          final initials = name
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase();

                          currentUserNotifier.value = TasklyUser(
                            name: name,
                            email: emailStr,
                            password: password,
                            initials: initials.isNotEmpty ? initials : 'U',
                            location: userMap != null ? '${userMap['location_city']}, ${userMap['location_area']}' : 'Nairobi, Kenya',
                            rating: userMap != null ? (userMap['rating'] as num).toDouble() : 5.0,
                            tasksCount: userMap != null ? (userMap['total_jobs'] as int) : 0,
                            savedCount: 0,
                          );

                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const UserShell(),
                              transitionsBuilder: (_, animation, __, child) =>
                                  FadeTransition(opacity: animation, child: child),
                              transitionDuration: AppAnimations.medium,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Invalid credentials.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TasklyButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata_rounded,
                          secondary: true,
                          compact: true,
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 1000));
                            if (mounted) {
                              Navigator.pop(context); // Dismiss spinner

                              currentUserNotifier.value = const TasklyUser(
                                name: 'Google User',
                                email: 'google.user@gmail.com',
                                password: '',
                                initials: 'GU',
                                location: 'Nairobi, Kenya',
                                rating: 5.0,
                                tasksCount: 0,
                                savedCount: 0,
                              );

                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const UserShell(),
                                  transitionsBuilder: (_, animation, __, child) =>
                                      FadeTransition(opacity: animation, child: child),
                                  transitionDuration: AppAnimations.medium,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TasklyButton(
                          label: 'Apple',
                          icon: Icons.apple_rounded,
                          secondary: true,
                          compact: true,
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );

                            await Future.delayed(const Duration(milliseconds: 1000));
                            if (mounted) {
                              Navigator.pop(context); // Dismiss spinner

                              currentUserNotifier.value = const TasklyUser(
                                name: 'Apple User',
                                email: 'apple.user@icloud.com',
                                password: '',
                                initials: 'AU',
                                location: 'Nairobi, Kenya',
                                rating: 5.0,
                                tasksCount: 0,
                                savedCount: 0,
                              );

                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const UserShell(),
                                  transitionsBuilder: (_, animation, __, child) =>
                                      FadeTransition(opacity: animation, child: child),
                                  transitionDuration: AppAnimations.medium,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => setState(() => register = !register),
                child: Text(
                  register
                      ? 'Already have an account? Log in'
                      : 'New to Taskly? Create account',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const TrackingScreen(),
      const MessagesScreen(),
      const UserProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
        ),
        elevation: 12,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.aiGlow,
          ),
          child: Container(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            alignment: Alignment.center,
            child: const Icon(AppIcons.ai, color: Colors.black, size: 24),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: TasklyBottomNav(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(AppIcons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.near_me_rounded), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(AppIcons.chat), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeAiBriefCard extends StatelessWidget {
  const _HomeAiBriefCard({required this.preview});

  final AiTaskPreview preview;

  @override
  Widget build(BuildContext context) {
    // Filter matching taskers based on AI parsed category
    final category = preview.category.toLowerCase();
    var matchingTaskers = taskers.where((t) {
      final skill = t.skill.toLowerCase();
      if (category.contains('clean') && skill.contains('clean')) return true;
      if (category.contains('handy') &&
          (skill.contains('handy') || skill.contains('assembly'))) return true;
      if ((category.contains('child') ||
              category.contains('baby') ||
              category.contains('errand')) &&
          (skill.contains('child') || skill.contains('errand'))) return true;
      if (category.contains('mov') && skill.contains('mov')) return true;
      if (category.contains('cook') && skill.contains('chef')) return true;
      if (category.contains('laund') && skill.contains('laund')) return true;
      return false;
    }).toList();

    if (matchingTaskers.isEmpty) {
      matchingTaskers = taskers;
    }

    String getTaskerImage(TaskerProfile tasker) {
      final index = taskers.indexOf(tasker);
      if (index != -1) {
        return _taskerImages[index % _taskerImages.length];
      }
      return _taskerImages[0];
    }

    return Container(
      padding: AppSpacing.cardLarge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Task Brief & Matches',
                      style: context.type.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Text(
                      'Brief generated & taskers matching your query',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            preview.title,
            style: context.type.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview.description,
            style: const TextStyle(
                color: Color(0xFF475569), height: 1.5, fontSize: 13.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetaChip(
                label: preview.category,
                icon: Icons.category_rounded,
                backgroundColor: const Color(0xFFF8FAFC),
                borderColor: const Color(0xFFE2E8F0),
                textColor: const Color(0xFF475569),
              ),
              MetaChip(
                label: preview.suggestedBudget,
                icon: Icons.payments_rounded,
                backgroundColor: const Color(0xFFF8FAFC),
                borderColor: const Color(0xFFE2E8F0),
                textColor: const Color(0xFF475569),
              ),
              MetaChip(
                label: preview.duration,
                icon: Icons.schedule_rounded,
                backgroundColor: const Color(0xFFF8FAFC),
                borderColor: const Color(0xFFE2E8F0),
                textColor: const Color(0xFF475569),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Recommended Taskers',
            style: context.type.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Top-rated specialists in your area who match this task:',
            style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 350,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: matchingTaskers.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final tasker = matchingTaskers[i];
                return PremiumTaskerCard(
                  key: ValueKey(tasker.name),
                  tasker: tasker,
                  imageUrl: getTaskerImage(tasker),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TasklyButton(
            label: "Confirm Task & Publish",
            icon: AppIcons.ai,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MatchingScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ai = AiMockService();
  AiTaskPreview? preview;
  bool loading = false;

  final _homeScrollController = ScrollController();
  final _featuredServicesKey = GlobalKey();

  final _serviceInputController = TextEditingController();
  final _locationInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _locationInputController.text =
        currentUserNotifier.value?.location ?? 'Nairobi, Kenya';
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _serviceInputController.dispose();
    _locationInputController.dispose();
    super.dispose();
  }

  Future<void> _askAi(String service, String location) async {
    setState(() => loading = true);

    // Update logged in user location dynamically
    if (currentUserNotifier.value != null) {
      final user = currentUserNotifier.value!;
      currentUserNotifier.value = TasklyUser(
        name: user.name,
        email: user.email,
        password: user.password,
        initials: user.initials,
        location: location,
        rating: user.rating,
        tasksCount: user.tasksCount,
        savedCount: user.savedCount,
      );
    }

    final result = await ai.generateTaskPreview(service);
    if (mounted) {
      setState(() {
        preview = result;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _homeScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TasklyAvatar(
                            initials:
                                currentUserNotifier.value?.initials ?? 'U',
                            size: 52,
                            verified: true),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Morning, ${currentUserNotifier.value?.name.split(' ').first ?? 'User'} 👋',
                                style: context.type.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      color: AppColors.primary, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    currentUserNotifier.value?.location ??
                                        'Nairobi, Kenya',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: ValueListenableBuilder<ThemeMode>(
                            valueListenable: AppTheme.themeModeNotifier,
                            builder: (context, mode, child) {
                              return IconButton(
                                onPressed: () {
                                  AppTheme.themeModeNotifier.value =
                                      mode == ThemeMode.dark
                                          ? ThemeMode.light
                                          : ThemeMode.dark;
                                },
                                icon: Icon(
                                  mode == ThemeMode.dark
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  color: AppColors.textPrimary,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(AppIcons.notifications,
                                color: AppColors.textPrimary, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lgBorder,
                        boxShadow: AppShadows.card,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.lgBorder,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                _cleaningHero,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.92),
                                    Colors.black.withOpacity(0.35),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.18),
                                            borderRadius: AppRadius.smBorder,
                                            border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.35)),
                                          ),
                                          child: Text(
                                            'VERIFIED PROFESSIONALS',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.primary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Need help today?',
                                          style: context.type.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Find trusted taskers near you instantly.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: 150,
                                          child: TasklyButton(
                                            label: 'Explore now',
                                            icon: AppIcons.search,
                                            compact: true,
                                            onPressed: () {
                                              Scrollable.ensureVisible(
                                                _featuredServicesKey
                                                    .currentContext!,
                                                duration: const Duration(
                                                    milliseconds: 500),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(flex: 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _serviceInputController,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14.5),
                            decoration: const InputDecoration(
                              labelText: 'What do you need help with today?',
                              prefixIcon: Icon(AppIcons.search, size: 20),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _locationInputController,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14.5),
                            decoration: const InputDecoration(
                              labelText: 'Your exact location',
                              prefixIcon:
                                  Icon(Icons.location_on_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TasklyButton(
                            label: 'Ask Taskly AI',
                            icon: AppIcons.ai,
                            onPressed: () {
                              final service =
                                  _serviceInputController.text.trim();
                              final location =
                                  _locationInputController.text.trim();
                              if (service.isNotEmpty && location.isNotEmpty) {
                                _askAi(service, location);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please enter both your task and exact location.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final chip in [
                            'Cleaning',
                            'Babysitting',
                            'Moving',
                            'Cooking',
                            'Laundry'
                          ])
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.xs),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(AppIcons.ai,
                                        size: 13, color: Color(0xFF6366F1)),
                                    const SizedBox(width: 5),
                                    Text(chip),
                                  ],
                                ),
                                selected: false,
                                onSelected: (_) {
                                  _serviceInputController.text = chip;
                                  final location =
                                      _locationInputController.text.trim();
                                  _askAi(
                                      chip,
                                      location.isNotEmpty
                                          ? location
                                          : 'Nairobi, Kenya');
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const SkeletonBox(height: 180),
                    ] else if (preview != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _HomeAiBriefCard(preview: preview!),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                key: _featuredServicesKey,
                title: 'Featured services',
                action: 'See all',
                onTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 382,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, index) => ServiceCard(
                    title: _featuredServices[index].title,
                    category: _featuredServices[index].category,
                    imageUrl: _featuredServices[index].imageUrl,
                    price: _featuredServices[index].price,
                    rating: _featuredServices[index].rating,
                    reviews: _featuredServices[index].reviews,
                    distance: _featuredServices[index].distance,
                  ),
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemCount: _featuredServices.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Popular categories',
                action: 'Browse',
                onTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 154,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: serviceCategories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => CategoryFeatureCard(
                    category: serviceCategories[i],
                    index: i,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Recommended taskers',
                action: 'View all',
                onTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 350,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: taskers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) => PremiumTaskerCard(
                    tasker: taskers[i],
                    imageUrl: _taskerImages[i % _taskerImages.length],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Trending services',
                action: 'See all',
                onTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 248,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _trendingServices.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) =>
                      TrendingServiceCard(item: _trendingServices[i]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Recently viewed',
                action: 'Clear',
                onTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: demoTasks
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: RecentTaskCard(
                            task: task,
                            imageUrl: _recentTaskImages[
                                demoTasks.indexOf(task) %
                                    _recentTaskImages.length],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TaskDetailsScreen(task: task),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? customWidget;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.customWidget,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI matches',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lgBorder,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      _babysittingHero,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INTELLIGENT MATCHING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Verified Professionals',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Ranked by rating, distance, availability, and completion history.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...taskers.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: PremiumTaskerCard(
                    tasker: entry.value,
                    imageUrl: _taskerImages[entry.key % _taskerImages.length],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.task});

  final TasklyTask task;

  @override
  Widget build(BuildContext context) {
    final timeline = [
      'Posted',
      'Matched',
      'Accepted',
      'On the way',
      'In progress',
      'Completed'
    ];
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            title: const Text('Task details',
                style: TextStyle(fontWeight: FontWeight.w900)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PremiumImage(
                    url: task.category == 'Cleaning'
                        ? _cleaningHero
                        : _movingHero,
                    height: 280,
                    radius: 0,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.92)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: context.type.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Status timeline and booking details',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                children: [
                  TasklySurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: context.type.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const _Pill(
                                text: 'Booked', icon: Icons.lock_rounded),
                          ],
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(
                                text: task.budget,
                                icon: Icons.payments_rounded),
                            _Pill(
                                text: task.date, icon: Icons.schedule_rounded),
                            const _Pill(
                                text: '1.2 mi', icon: Icons.near_me_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (task.tasker != null)
                    PremiumTaskerCard(
                      tasker: task.tasker!,
                      imageUrl: _taskerImages.first,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  TasklySurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status timeline',
                          style: context.type.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final item in timeline)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item == 'Completed'
                                        ? AppColors.border
                                        : AppColors.primary,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2.5,
                                    ),
                                    boxShadow: item == 'Completed'
                                        ? null
                                        : AppShadows.glow,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: item == 'Completed'
                                          ? AppColors.textMuted
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                if (item == 'On the way')
                                  const AiTypingIndicator(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'Searching',
      'Accepted',
      'On The Way',
      'Arrived',
      'In Progress',
      'Completed'
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live tracking',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              boxShadow: AppShadows.card,
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lgBorder,
              child: SizedBox(
                height: 340,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PremiumImage(
                      url: _movingHero,
                      height: 340,
                    ),
                    CustomPaint(painter: _MapOverlayPainter()),
                    Positioned(
                      left: 18,
                      right: 18,
                      top: 18,
                      child: Row(
                        children: [
                          _Pill(
                            text: 'Maya is 12 min away',
                            icon: Icons.electric_moped_rounded,
                            color: AppColors.primary,
                          ),
                          const Spacer(),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(AppIcons.chat,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      left: 40,
                      bottom: 50,
                      child: _MapMarker(
                        label: 'You',
                        icon: Icons.person_pin_circle_rounded,
                      ),
                    ),
                    const Positioned(
                      right: 48,
                      top: 122,
                      child: _MapMarker(
                        label: 'Tasker',
                        icon: Icons.electric_moped_rounded,
                      ),
                    ),
                    const Positioned(
                      left: 140,
                      bottom: 110,
                      child: _MapMarker(
                        label: 'Task',
                        icon: Icons.home_work_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TasklySurface(
            child: Column(
              children: [
                for (final (i, status) in statuses.indexed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          i < 3 ? AppColors.primary : AppColors.elevated,
                      child: Icon(
                        i < 3 ? Icons.check_rounded : Icons.circle,
                        size: 11,
                        color: Colors.black,
                      ),
                    ),
                    title: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: i < 3 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    trailing: i == 2 ? const AiTypingIndicator() : null,
                  ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TasklyButton(
                        label: 'Chat',
                        icon: AppIcons.chat,
                        secondary: true,
                        compact: true,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TasklyButton(
                        label: 'Call',
                        icon: AppIcons.call,
                        secondary: true,
                        compact: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final replies = AiMockService().quickReplies();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.page,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: TasklySurface(
                gradient: AppColors.heroGradient,
                child: Row(
                  children: [
                    const TasklyAvatar(
                        initials: 'MJ', size: 52, verified: true),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maya Johnson',
                            style: context.type.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Cleaning specialist',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _Pill(
                      text: 'Online',
                      icon: Icons.circle,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              children: [
                AiChatBubble(
                  text:
                      'Hi ${currentUserNotifier.value?.name.split(' ').first ?? 'User'}, I will arrive in 12 minutes and bring eco-friendly supplies.',
                ),
                const AiChatBubble(
                  text: 'Great, the access code is 4821.',
                  fromAi: false,
                ),
                const AiChatBubble(
                  text: 'Perfect, thank you.',
                  fromAi: true,
                ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.page.copyWith(top: 0),
            child: Column(
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: replies
                      .map((reply) => ActionChip(
                            label: Text(reply),
                            onPressed: () {},
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Expanded(
                        child: _InputField(
                            label: 'Message Maya',
                            icon: Icons.message_outlined)),
                    const SizedBox(width: AppSpacing.sm),
                    FloatingActionButton(
                      onPressed: () {},
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child:
                          const Icon(Icons.send_rounded, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: BouncingScrollPhysics(),
        children: [
          TasklySurface(
            gradient: AppColors.heroGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking summary',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  r'$154.80',
                  style: context.type.displayMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Secure checkout for your scheduled task.',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PriceRow(label: 'Service cost', value: r'$145.00'),
          const _PriceRow(label: 'Platform fee', value: r'$9.80'),
          const Divider(height: 32),
          const _PriceRow(label: 'Total', value: r'$154.80', strong: true),
          const SizedBox(height: AppSpacing.lg),
          const _MethodCard(
            icon: Icons.phone_iphone_rounded,
            title: 'M-Pesa',
            subtitle: 'Mobile money checkout',
          ),
          const SizedBox(height: AppSpacing.md),
          const _MethodCard(
            icon: Icons.credit_card_rounded,
            title: 'Card',
            subtitle: 'Visa ending 4242',
          ),
          const SizedBox(height: AppSpacing.xl),
          TasklyButton(
            label: 'Confirm payment',
            icon: Icons.lock_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review tasker',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          TasklySurface(
            gradient: AppColors.heroGradient,
            child: Row(
              children: [
                const TasklyAvatar(initials: 'MJ', size: 72, verified: true),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How was Maya?',
                        style: context.type.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your feedback helps the marketplace stay premium.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: AppColors.warning, size: 42),
              Icon(Icons.star_rounded, color: AppColors.warning, size: 42),
              Icon(Icons.star_rounded, color: AppColors.warning, size: 42),
              Icon(Icons.star_rounded, color: AppColors.warning, size: 42),
              Icon(Icons.star_half_rounded, color: AppColors.warning, size: 42),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const _InputField(
            label: 'Write your feedback',
            minLines: 5,
            maxLines: 7,
            icon: Icons.reviews_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          TasklyButton(
            label: 'Submit review',
            icon: Icons.check_rounded,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          TasklySurface(
            gradient: AppColors.heroGradient,
            child: Column(
              children: [
                TasklyAvatar(
                    initials: currentUserNotifier.value?.initials ?? 'U',
                    size: 92,
                    verified: true),
                const SizedBox(height: AppSpacing.md),
                Text(
                  currentUserNotifier.value?.name ?? 'User Name',
                  style: context.type.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Verified customer',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                          value: currentUserNotifier.value?.rating
                                  .toStringAsFixed(2) ??
                              '5.00',
                          label: 'Rating'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileStat(
                          value: currentUserNotifier.value?.tasksCount
                                  .toString() ??
                              '0',
                          label: 'Tasks'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileStat(
                          value: currentUserNotifier.value?.savedCount
                                  .toString() ??
                              '0',
                          label: 'Saved'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTile(
            icon: Icons.home_rounded,
            title: 'Saved addresses',
          ),
          _ProfileTile(
            icon: Icons.payments_rounded,
            title: 'Payment methods',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentScreen()),
            ),
          ),
          _ProfileTile(
            icon: Icons.reviews_rounded,
            title: 'Reviews',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReviewsScreen()),
            ),
          ),
          const _ProfileTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
          ),
          _ProfileTile(
            icon: Icons.logout_rounded,
            title: 'Log out',
            onTap: () {
              currentUserNotifier.value = null;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taskly AI',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.page,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgBorder,
                  border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      width: 1.2),
                  boxShadow: AppShadows.aiGlow,
                ),
                child: TasklySurface(
                  gradient: AppColors.heroGradient,
                  child: Row(
                    children: [
                      const TasklyLogo(size: 52),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi ${currentUserNotifier.value?.name.split(' ').first ?? 'User'} 👋',
                              style: context.type.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'What can I help you with today?',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                physics: const BouncingScrollPhysics(),
                children: const [
                  AiChatBubble(
                    text:
                        'Tell me what you need done and I will turn it into a task brief, budget range, and ranked tasker shortlist.',
                  ),
                  AiChatBubble(
                    text: 'I need someone to clean my apartment tomorrow.',
                    fromAi: false,
                  ),
                  AiChatBubble(
                    text:
                        r'I recommend Cleaning, a 3 hour booking, and a budget between $120 and $160.',
                    fromAi: true,
                  ),
                  SizedBox(height: AppSpacing.md),
                  AiTypingIndicator(),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.page,
              child: Row(
                children: [
                  const Expanded(
                    child: TasklySearchBar(hint: 'Ask Taskly AI anything...'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FloatingActionButton(
                    onPressed: () {},
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.type.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(action,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    this.obscure = false,
    this.minLines = 1,
    this.maxLines,
    this.icon,
    this.controller,
  });
  final String label;
  final bool obscure;
  final int minLines;
  final int? maxLines;
  final IconData? icon;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      minLines: obscure ? 1 : minLines,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: AppColors.textSecondary)
            : null,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: context.type.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
      );
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({super.key, required this.fields, required this.icon});
  final List<String> fields;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Essential details'),
        const SizedBox(height: AppSpacing.sm),
        TasklySurface(
          child: Column(
            children: [
              for (final field in fields) ...[
                _InputField(label: field, icon: icon),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetSurface extends StatelessWidget {
  const _BudgetSurface({super.key});
  @override
  Widget build(BuildContext context) {
    return TasklySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('AI suggested budget'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            r'$145',
            style: context.type.displaySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: 145,
            min: 60,
            max: 240,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

class _PublishSurface extends StatelessWidget {
  _PublishSurface({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgBorder,
        border:
            Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.2),
        boxShadow: AppShadows.glow,
      ),
      child: TasklySurface(
        gradient: AppColors.heroGradient,
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 62),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ready to publish',
              style: context.type.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Taskly AI will notify the best nearby taskers instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetailsPreview extends StatelessWidget {
  const TaskDetailsPreview({super.key, required this.task});
  final TasklyTask task;
  @override
  Widget build(BuildContext context) {
    return TasklySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: context.type.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            task.description,
            style: TextStyle(
                color: AppColors.textSecondary, height: 1.45, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon, this.color});
  final String text;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.surface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: effectiveColor.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color == AppColors.surface ? AppColors.primary : color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: AppRadius.smBorder,
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _MapOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = AppColors.border.withOpacity(0.25);
    for (double x = 28; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x + 42, size.height), grid);
    }
    for (double y = 42; y < size.height; y += 54) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 18), grid);
    }
    final route = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(44, 82)
      ..quadraticBezierTo(size.width * .48, size.height * .34, size.width - 80,
          size.height - 104);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(
      {required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                fontSize: strong ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 22 : 15,
              fontWeight: FontWeight.w900,
              color: strong ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5)),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          trailing:
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _TaskData {
  const _TaskData(
      {required this.title,
      required this.category,
      required this.imageUrl,
      required this.price,
      required this.rating,
      required this.reviews,
      required this.distance});
  final String title;
  final String category;
  final String imageUrl;
  final String price;
  final double rating;
  final int reviews;
  final String distance;
}

class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.distance,
  });

  final String title;
  final String category;
  final String imageUrl;
  final String price;
  final double rating;
  final int reviews;
  final String distance;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool isFavorited = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PremiumImage(url: widget.imageUrl, height: 188),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.18),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.pill)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isFavorited = !isFavorited;
                      });
                    },
                    child: Icon(
                      isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 26,
                      color: isFavorited ? Colors.red : Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingStars(rating: widget.rating),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.reviews} reviews',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        widget.distance,
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Text(
                        widget.price,
                        style: context.type.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 120,
                        child: TasklyButton(
                          label: 'Book now',
                          compact: true,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryFeatureCard extends StatelessWidget {
  const CategoryFeatureCard(
      {super.key, required this.category, required this.index});
  final ServiceCategory category;
  final int index;

  String _getCategoryImage(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('clean')) return _cleaningHero;
    if (normalized.contains('baby') || normalized.contains('child'))
      return _babysittingHero;
    if (normalized.contains('cook') || normalized.contains('restaurant'))
      return _cookingHero;
    if (normalized.contains('mov') || normalized.contains('shipping'))
      return _movingHero;
    if (normalized.contains('deliver')) return _deliveryHero;
    return _heroPeople;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getCategoryImage(category.name);
    return SizedBox(
      width: 210,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumImage(
              url: imageUrl,
              height: double.infinity,
              radius: AppRadius.lg,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.18),
                      borderRadius: AppRadius.mdBorder,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      tasklyIcon(category.icon),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.name,
                    style: context.type.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Starting ${category.averagePrice}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumTaskerCard extends StatefulWidget {
  const PremiumTaskerCard({
    super.key,
    required this.tasker,
    required this.imageUrl,
  });

  final TaskerProfile tasker;
  final String imageUrl;

  @override
  State<PremiumTaskerCard> createState() => _PremiumTaskerCardState();
}

class _PremiumTaskerCardState extends State<PremiumTaskerCard> {
  bool isFavorited = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PremiumImage(url: widget.imageUrl, height: 160),
                if (widget.tasker.verified)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: const BorderRadius.all(
                            Radius.circular(AppRadius.pill)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppColors.primary, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isFavorited = !isFavorited;
                      });
                    },
                    child: Icon(
                      isFavorited
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 26,
                      color: isFavorited ? Colors.red : Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.tasker.name,
                          style: context.type.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: AppColors.primary, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            'Online',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.tasker.skill,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaItem(text: '${widget.tasker.reviews} jobs'),
                      _MetaItem(
                          text:
                              '${widget.tasker.rating.toStringAsFixed(2)} rating'),
                      _MetaItem(
                        text: currentUserNotifier.value?.location != null &&
                                currentUserNotifier.value!.location !=
                                    'Nairobi, Kenya'
                            ? '${widget.tasker.distance} from ${currentUserNotifier.value!.location.split(',').first}'
                            : widget.tasker.distance,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'From \$42/hr',
                          style: context.type.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: TasklyButton(
                          label: 'Book',
                          compact: true,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class TrendingServiceCard extends StatelessWidget {
  const TrendingServiceCard({super.key, required this.item});
  final _TaskData item;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PremiumImage(url: item.imageUrl, height: 148),
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.18),
                      borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.pill)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingStars(rating: item.rating),
                      const Spacer(),
                      Text(
                        item.distance,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentTaskCard extends StatelessWidget {
  const RecentTaskCard(
      {super.key, required this.task, required this.imageUrl, this.onTap});
  final TasklyTask task;
  final String imageUrl;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: PremiumImage(url: imageUrl, height: 112),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.type.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.budget,
                          style: context.type.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetaItem(text: task.category),
                        const SizedBox(width: 8),
                        const _MetaItem(text: '★ 4.9'),
                      ],
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
}

class _TaskDataView {
  const _TaskDataView(
      {required this.title,
      required this.category,
      required this.imageUrl,
      required this.price,
      required this.rating,
      required this.reviews,
      required this.distance});
  final String title;
  final String category;
  final String imageUrl;
  final String price;
  final double rating;
  final int reviews;
  final String distance;
}

const _featuredServices = [
  _TaskDataView(
    title: 'Deep clean apartment',
    category: 'Cleaning',
    imageUrl: _cleaningHero,
    price: r'$145',
    rating: 4.98,
    reviews: 324,
    distance: '1.2 mi',
  ),
  _TaskDataView(
    title: 'Home cooking session',
    category: 'Cooking',
    imageUrl: _cookingHero,
    price: r'$96',
    rating: 4.92,
    reviews: 188,
    distance: '2.0 mi',
  ),
  _TaskDataView(
    title: 'Move furniture',
    category: 'Moving',
    imageUrl: _movingHero,
    price: r'$120',
    rating: 4.91,
    reviews: 212,
    distance: '2.7 mi',
  ),
];

const _taskerImages = [_heroPeople, _babysittingHero, _deliveryHero];
const _recentTaskImages = [_cleaningHero, _movingHero];

const _trendingServices = [
  _TaskData(
    title: 'Babysitting tonight',
    category: 'Babysitting',
    imageUrl: _babysittingHero,
    price: r'$30/hr',
    rating: 4.97,
    reviews: 180,
    distance: '0.8 mi',
  ),
  _TaskData(
    title: 'Same-day delivery',
    category: 'Delivery',
    imageUrl: _deliveryHero,
    price: r'$18',
    rating: 4.89,
    reviews: 166,
    distance: '1.5 mi',
  ),
  _TaskData(
    title: 'Handyman repair',
    category: 'Handyman',
    imageUrl: _movingHero,
    price: r'$55/hr',
    rating: 4.95,
    reviews: 249,
    distance: '2.3 mi',
  ),
];

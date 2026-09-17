import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_components/shared_components.dart';
import 'package:ai_mock/ai_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'api_service.dart';

const String supabaseUrl = 'https://qnwjqdiwtxunjooiunsf.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFud2pxZGl3dHh1bmpvb2l1bnNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1NjA1MjgsImV4cCI6MjA5OTEzNjUyOH0.JwquBu_bqARoddPSnraEytFDdV-9GwL5jgcYl5-4zZ4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }
  runApp(const TasklyUserApp());
}

class TasklyUserApp extends StatefulWidget {
  const TasklyUserApp({super.key});

  @override
  State<TasklyUserApp> createState() => _TasklyUserAppState();
}

class _TasklyUserAppState extends State<TasklyUserApp> {
  TasklyUser? _authenticatedUser;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _setupSupabaseAuthListener();
    _loadSavedSession();
  }

  void _setupSupabaseAuthListener() {
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final user = session?.user;
        if (user != null && _authenticatedUser == null) {
          final email = user.email ?? '';
          final fullName = (user.userMetadata?['full_name'] as String?) ??
              (user.userMetadata?['name'] as String?) ??
              (email.contains('@') ? email.split('@').first : 'User');
          final parts = fullName.trim().split(RegExp(r'\s+'));
          final initials = parts.isNotEmpty
              ? parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
              : 'U';

          final authedUser = TasklyUser(
            name: fullName,
            email: email,
            password: '',
            initials: initials.isNotEmpty ? initials : 'U',
            location: 'Nairobi, Kenya',
            rating: 0.0,
            tasksCount: 0,
            savedCount: 0,
            isVerified: false,
          );

          try {
            ApiService.googleSignIn(
              email: email,
              name: fullName,
              photoUrl: user.userMetadata?['avatar_url'] as String?,
              idToken: session?.accessToken,
            );
          } catch (_) {}

          _handleLoginSuccess(authedUser);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('user_is_logged_in') ?? false;
      if (isLoggedIn) {
        final name = prefs.getString('user_name') ?? 'Client';
        final email = prefs.getString('user_email') ?? '';
        final location = prefs.getString('user_location') ?? 'Nairobi, Kenya';
        final initials = prefs.getString('user_initials') ?? (name.isNotEmpty ? name[0].toUpperCase() : 'U');
        final rating = prefs.getDouble('user_rating') ?? 0.0;
        final tasksCount = prefs.getInt('user_tasks_count') ?? 0;
        final isVerified = prefs.getBool('user_is_verified') ?? false;
        final idNumber = prefs.getString('user_id_number');
        final photoUrl = prefs.getString('user_profile_photo');

        setState(() {
          _authenticatedUser = TasklyUser(
            name: name,
            email: email,
            password: '',
            initials: initials,
            location: location,
            rating: rating,
            tasksCount: tasksCount,
            savedCount: 0,
            isVerified: isVerified,
            idNumber: idNumber,
            profilePictureUrl: photoUrl,
          );
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _checkingSession = false);
      }
    }
  }

  Future<void> _handleLoginSuccess(TasklyUser user) async {
    setState(() {
      _authenticatedUser = user;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_is_logged_in', true);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_location', user.location);
      await prefs.setString('user_initials', user.initials);
      await prefs.setDouble('user_rating', user.rating);
      await prefs.setInt('user_tasks_count', user.tasksCount);
      await prefs.setBool('user_is_verified', user.isVerified);
      if (user.idNumber != null) await prefs.setString('user_id_number', user.idNumber!);
      if (user.profilePictureUrl != null) await prefs.setString('user_profile_photo', user.profilePictureUrl!);
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    setState(() {
      _authenticatedUser = null;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_is_logged_in');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_location');
      await prefs.remove('user_initials');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Taskly - Customer',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: _checkingSession
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _authenticatedUser == null
                  ? UserAuthScreen(
                      onAuthenticated: _handleLoginSuccess,
                    )
                  : UserMainNavigationScreen(
                      currentUser: _authenticatedUser!,
                      onLogout: _handleLogout,
                    ),
        );
      },
    );
  }
}

class UserMainNavigationScreen extends StatefulWidget {
  const UserMainNavigationScreen({
    super.key,
    required this.currentUser,
    this.onLogout,
  });

  final TasklyUser currentUser;
  final VoidCallback? onLogout;

  @override
  State<UserMainNavigationScreen> createState() => _UserMainNavigationScreenState();
}

class _UserMainNavigationScreenState extends State<UserMainNavigationScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Active bookings state
  late List<TasklyTask> _myTasks;
  late TasklyUser _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _myTasks = List<TasklyTask>.from(demoTasks);
  }

  @override
  void didUpdateWidget(covariant UserMainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _currentUser = widget.currentUser;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _bookTask(TasklyTask newTask) {
    setState(() {
      _myTasks.insert(0, newTask);
      _currentIndex = 2; // Switch to bookings tab
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Task "${newTask.title}" booked successfully!')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildExploreScreen(),
      _buildAiConciergeScreen(),
      _buildBookingsScreen(),
      _buildMessagesScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: TasklyBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'AI Concierge'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildExploreScreen() {
    final filteredCategories = serviceCategories.where((c) {
      if (_selectedCategory == 'All') return true;
      return c.name.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final filteredTaskers = taskers.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.skill.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App bar header
                  Row(
                    children: [
                      const TasklyLogo(size: 40),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          AppTheme.themeModeNotifier.value =
                              AppColors.isDarkMode ? ThemeMode.light : ThemeMode.dark;
                        },
                        icon: Icon(
                          AppColors.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TasklyAvatar(
                        initials: _currentUser.initials,
                        imageUrl: _currentUser.profilePictureUrl,
                        size: 38,
                        verified: _currentUser.isVerified,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Greeting & headline
                  Text(
                    'Need a hand, ${_currentUser.name.split(' ').first}?',
                    style: context.type.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Book top-rated vetted service pros in minutes',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Search bar
                  TasklySearchBar(
                    hint: 'Search cleaning, moving, handyman...',
                    controller: _searchController,
                    onSubmitted: (query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                  const SizedBox(height: 20),

                  // AI Concierge Banner
                  InkWell(
                    onTap: () => setState(() => _currentIndex = 1),
                    borderRadius: AppRadius.lgBorder,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.aiGradient,
                        borderRadius: AppRadius.lgBorder,
                        boxShadow: AppShadows.aiGlow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Taskly AI Concierge',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Describe what you need in plain words & get matched instantly',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Header: Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Projects',
                        style: context.type.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedCategory = 'All'),
                        child: Text(
                          _selectedCategory == 'All' ? 'View All' : 'Show All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Categories Horizontal Slider
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: filteredCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final cat = filteredCategories[index];
                  return CategoryCard(
                    category: cat,
                    index: index,
                    onTap: () {
                      _showQuickBookDialog(cat.name, cat.averagePrice);
                    },
                  );
                },
              ),
            ),
          ),

          // Section Header: Featured Taskers
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Top Taskers',
                    style: context.type.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${filteredTaskers.length} available',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Taskers List
          if (filteredTaskers.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  decoration: AppCards.surface(radius: AppRadius.lg),
                  child: Column(
                    children: [
                      Icon(Icons.person_search_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No Taskers Registered Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'As service providers register and get verified on Taskly, their profiles will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tasker = filteredTaskers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TaskerCard(
                        tasker: tasker,
                        onTap: () => _showTaskerDetailModal(tasker),
                      ),
                    );
                  },
                  childCount: filteredTaskers.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiConciergeScreen() {
    return const AiConciergeTab();
  }

  Widget _buildBookingsScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Bookings',
                  style: context.type.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_myTasks.length} Active',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_myTasks.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.calendar_today_rounded,
                  title: 'No Active Bookings',
                  message: 'Explore services or ask Taskly AI to schedule your first task.',
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _myTasks.length,
                  itemBuilder: (context, index) {
                    final task = _myTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TaskCard(
                        task: task,
                        onTap: () => _showBookingDetailsSheet(task),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesScreen() {
    final List<Map<String, dynamic>> mockChats = [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: context.type.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Direct chat with your booked service providers',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: mockChats.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No Messages Yet',
                      message: 'Direct conversations with your booked service providers will appear here.',
                    )
                  : ListView.separated(
                      itemCount: mockChats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final chat = mockChats[index];
                        final isUnread = chat['unread'] as bool;
                        return InkWell(
                          onTap: () => _openChatModal(
                            chat['name'] as String,
                            chat['avatar'] as String,
                            chat['task'] as String,
                          ),
                          borderRadius: AppRadius.lgBorder,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppCards.surface(radius: AppRadius.lg),
                            child: Row(
                              children: [
                                TasklyAvatar(initials: chat['avatar'] as String, size: 50, verified: false),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            chat['name'] as String,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            chat['time'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isUnread ? AppColors.primary : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        chat['task'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat['lastMessage'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                          color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile & Account',
              style: context.type.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 20),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppCards.surface(radius: AppRadius.lg),
              child: Row(
                children: [
                  TasklyAvatar(
                    initials: _currentUser.initials,
                    imageUrl: _currentUser.profilePictureUrl,
                    size: 64,
                    verified: _currentUser.isVerified,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _currentUser.name,
                                style: context.type.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_currentUser.isVerified)
                              const Icon(Icons.verified_rounded, color: Color(0xFF00B37E), size: 18)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Unverified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentUser.email,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            RatingStars(rating: _currentUser.rating),
                            const SizedBox(width: 12),
                            Text(
                              '${_currentUser.tasksCount} tasks completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
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
            const SizedBox(height: 16),

            // Identity Verification Card
            if (!_currentUser.isVerified)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: AppRadius.lgBorder,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Verification Required',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Upload your profile photo and confirm your National ID details to get verified.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showVerificationModal,
                        icon: const Icon(Icons.verified_user_rounded, size: 16),
                        label: const Text('Complete Verification', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B37E).withValues(alpha: 0.08),
                  borderRadius: AppRadius.lgBorder,
                  border: Border.all(color: const Color(0xFF00B37E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF00B37E), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Identity Verified Account',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF00B37E)),
                          ),
                          Text(
                            'National ID: ${_currentUser.idNumber ?? "Verified"} • Full verified client access',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Account Options
            _buildProfileOption(
              icon: Icons.dark_mode_rounded,
              title: 'Appearance / Theme',
              subtitle: AppColors.isDarkMode ? 'Dark Mode' : 'Light Mode',
              trailing: Switch(
                value: AppColors.isDarkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (val) {
                  AppTheme.themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              icon: Icons.location_on_rounded,
              title: 'Saved Addresses',
              subtitle: _currentUser.location,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              icon: Icons.payment_rounded,
              title: 'Payment Methods',
              subtitle: 'Add M-Pesa or Card',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildProfileOption(
              icon: Icons.help_outline_rounded,
              title: 'Taskly AI Support',
              subtitle: '24/7 Client Help Center',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            // Log Out Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out of Taskly?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onLogout?.call();
                          },
                          child: const Text('Log Out', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                ),
                title: Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.danger,
                  ),
                ),
                subtitle: Text(
                  'Sign out of ${_currentUser.email}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 24),

            // Version info
            Center(
              child: Text(
                'Taskly AI Customer App • v1.0.0 (Web & Mobile)',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: AppCards.surface(radius: AppRadius.md),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  void _showQuickBookDialog(String categoryName, String price) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Book $categoryName',
                  style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rates starting from $price. Top-rated verified taskers ready to help today.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            TasklyButton(
              label: 'Generate AI Task Plan',
              icon: Icons.auto_awesome_rounded,
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 10),
            TasklyButton(
              label: 'Quick Instant Booking ($price)',
              secondary: true,
              onPressed: () {
                Navigator.pop(context);
                _bookTask(
                  TasklyTask(
                    title: '$categoryName Service',
                    category: categoryName,
                    description: 'Standard booking requested by ${_currentUser.name}.',
                    budget: price,
                    date: 'Today, within 2 hours',
                    status: 'Tasker on the way',
                    tasker: taskers.first,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTaskerDetailModal(TaskerProfile tasker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TasklyAvatar(initials: tasker.avatar, size: 60, verified: tasker.verified),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tasker.name,
                        style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        tasker.skill,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      RatingStars(rating: tasker.rating),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetaChip(label: '${tasker.reviews} completed jobs', icon: Icons.work_rounded),
                MetaChip(label: tasker.distance, icon: Icons.near_me_rounded),
                MetaChip(label: '${tasker.completionRate}% completion rate', icon: Icons.done_all_rounded),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TasklyButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    secondary: true,
                    onPressed: () {
                      Navigator.pop(context);
                      _openChatModal(tasker.name, tasker.avatar, tasker.skill);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TasklyButton(
                    label: 'Book Tasker',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      _bookTask(
                        TasklyTask(
                          title: '${tasker.skill} Booking',
                          category: 'Direct Hire',
                          description: 'Direct task assignment to ${tasker.name}.',
                          budget: r'$42/hr',
                          date: 'Tomorrow, 10:00 AM',
                          status: 'Scheduled',
                          tasker: tasker,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBookingDetailsSheet(TasklyTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                task.status,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              task.description,
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                MetaChip(label: task.budget, icon: Icons.payments_rounded),
                MetaChip(label: task.date, icon: Icons.schedule_rounded),
              ],
            ),
            if (task.tasker != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  TasklyAvatar(initials: task.tasker!.avatar, size: 44, verified: task.tasker!.verified),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.tasker!.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          task.tasker!.skill,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_rounded, color: AppColors.primary),
                    onPressed: () {
                      Navigator.pop(context);
                      _openChatModal(task.tasker!.name, task.tasker!.avatar, task.title);
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            TasklyButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVerificationModal() {
    final nameController = TextEditingController(text: _currentUser.name);
    final idController = TextEditingController(text: _currentUser.idNumber ?? '');
    final locationController = TextEditingController(text: _currentUser.location);
    String selectedPhoto = _currentUser.profilePictureUrl ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80';
    bool confirmedDocs = false;

    final avatarPresets = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=256&q=80',
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=256&q=80',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identity Verification',
                          style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload photo & confirm National ID details',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      // Photo Upload Section
                      Text(
                        '1. PROFILE PHOTO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TasklyAvatar(
                            initials: _currentUser.initials,
                            imageUrl: selectedPhoto,
                            size: 68,
                            verified: false,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Choose Profile Photo',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select a preset avatar photo to verify your user profile.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: avatarPresets.map((preset) {
                          final isSelected = selectedPhoto == preset;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedPhoto = preset),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(preset),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Personal Details
                      Text(
                        '2. PERSONAL & ID DETAILS',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Legal Name',
                          hintText: 'e.g. Zipporah Wambui',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: idController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Kenyan National ID / Passport Number',
                          hintText: 'e.g. 12345678 or A1234567',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'County & Location',
                          hintText: 'e.g. Westlands, Nairobi',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Agreement checkbox
                      CheckboxListTile(
                        value: confirmedDocs,
                        onChanged: (val) => setModalState(() => confirmedDocs = val ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'I confirm that all provided details and identity credentials are authentic and belong to me.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final id = idController.text.trim();
                      final loc = locationController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your full legal name.')),
                        );
                        return;
                      }
                      if (id.length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid National ID or Passport number.')),
                        );
                        return;
                      }
                      if (!confirmedDocs) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please check the confirmation box to proceed.')),
                        );
                        return;
                      }

                      // Update local state
                      final updatedUser = _currentUser.copyWith(
                        name: name,
                        idNumber: id,
                        profilePictureUrl: selectedPhoto,
                        location: loc.isNotEmpty ? loc : _currentUser.location,
                        isVerified: true,
                      );

                      setState(() {
                        _currentUser = updatedUser;
                      });

                      // Persist to SharedPreferences
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('user_is_verified', true);
                        await prefs.setString('user_id_number', id);
                        await prefs.setString('user_profile_photo', selectedPhoto);
                        await prefs.setString('user_name', name);
                        if (loc.isNotEmpty) await prefs.setString('user_location', loc);
                      } catch (_) {}

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('Identity verified successfully! Verified badge activated.'),
                              ),
                            ],
                          ),
                          backgroundColor: Color(0xFF00B37E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: const Text(
                      'Confirm & Verify Account',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openChatModal(String taskerName, String initials, String taskTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChatModalWidget(
        taskerName: taskerName,
        initials: initials,
        taskTitle: taskTitle,
      ),
    );
  }
}

class AiConciergeTab extends StatefulWidget {
  const AiConciergeTab({super.key});

  @override
  State<AiConciergeTab> createState() => _AiConciergeTabState();
}

class _AiConciergeTabState extends State<AiConciergeTab> {
  final TextEditingController _promptController = TextEditingController();
  final AiMockService _aiService = AiMockService();
  bool _isLoading = false;
  AiTaskPreview? _currentPreview;
  final List<Map<String, dynamic>> _messages = [
    {
      'isAi': true,
      'text':
          'Hi! I am your Taskly AI Concierge. Describe whatever help you need (e.g. "I need someone to deep clean my 2-bedroom home tomorrow morning" or "Assemble my new Ikea closet"), and I will formulate a plan and estimate!',
    },
  ];

  Future<void> _handlePrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _messages.add({'isAi': false, 'text': prompt});
      _isLoading = true;
    });
    _promptController.clear();

    final preview = await _aiService.generateTaskPreview(prompt);

    setState(() {
      _isLoading = false;
      _currentPreview = preview;
      _messages.add({
        'isAi': true,
        'text':
            'I analyzed your request for "${preview.title}". Here is the recommended task specification and budget:',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.aiGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Task Concierge',
                      style: context.type.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Instant scoping, price estimation & task matching',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Messages & Previews List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final msg in _messages)
                  AiChatBubble(
                    text: msg['text'] as String,
                    fromAi: msg['isAi'] as bool,
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AiTypingIndicator(),
                    ),
                  ),
                if (_currentPreview != null && !_isLoading) ...[
                  const SizedBox(height: 12),
                  AiSuggestionCard(preview: _currentPreview!),
                  const SizedBox(height: 16),
                  TasklyButton(
                    label: 'Book This Task (${_currentPreview!.suggestedBudget})',
                    icon: Icons.flash_on_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Task "${_currentPreview!.title}" booked via AI!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // Quick prompts
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _quickPromptChip('Deep clean apartment'),
                const SizedBox(width: 8),
                _quickPromptChip('Move furniture and boxes'),
                const SizedBox(width: 8),
                _quickPromptChip('Private dinner chef'),
                const SizedBox(width: 8),
                _quickPromptChip('Laundry wash and fold'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    onSubmitted: _handlePrompt,
                    decoration: InputDecoration(
                      hintText: 'Tell AI what you need done...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: () => _handlePrompt(_promptController.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickPromptChip(String prompt) {
    return ActionChip(
      label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      onPressed: () => _handlePrompt(prompt),
    );
  }
}

class _ChatModalWidget extends StatefulWidget {
  const _ChatModalWidget({
    required this.taskerName,
    required this.initials,
    required this.taskTitle,
  });

  final String taskerName;
  final String initials;
  final String taskTitle;

  @override
  State<_ChatModalWidget> createState() => _ChatModalWidgetState();
}

class _ChatModalWidgetState extends State<_ChatModalWidget> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _chatMessages.addAll([
      {
        'isMe': false,
        'text': 'Hello! I am ready to help with "${widget.taskTitle}". Let me know any specific instructions.',
        'time': '10:02 AM',
      },
    ]);
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({
        'isMe': true,
        'text': text,
        'time': 'Just now',
      });
    });
    _msgController.clear();

    // Simulated tasker response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _chatMessages.add({
          'isMe': false,
          'text': 'Got it! Working on that right away.',
          'time': 'Just now',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TasklyAvatar(initials: widget.initials, size: 42, verified: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.taskerName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        'Active for: ${widget.taskTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: isMe ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        color: isMe ? Colors.black : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message to ${widget.taskerName}...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_components/shared_components.dart';
import 'package:ai_mock/ai_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('user_is_logged_in') ?? false;
      if (isLoggedIn) {
        final name = prefs.getString('user_name') ?? 'Zipporah Wambui';
        final email = prefs.getString('user_email') ?? 'zipporah@taskly.com';
        final location = prefs.getString('user_location') ?? 'Nairobi, Kenya';
        final initials = prefs.getString('user_initials') ?? 'ZW';
        final rating = prefs.getDouble('user_rating') ?? 4.96;
        final tasksCount = prefs.getInt('user_tasks_count') ?? 32;

        setState(() {
          _authenticatedUser = TasklyUser(
            name: name,
            email: email,
            password: '',
            initials: initials,
            location: location,
            rating: rating,
            tasksCount: tasksCount,
            savedCount: 8,
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
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    setState(() {
      _authenticatedUser = null;
    });

    try {
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
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TASKLY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CLIENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF00B37E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                _currentUser.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                      TasklyAvatar(initials: _currentUser.initials, size: 38, verified: true),
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
                        'Popular Categories',
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
    final mockChats = [
      {
        'name': 'Maya Johnson',
        'avatar': 'MJ',
        'task': 'Deep clean 3-bedroom apartment',
        'lastMessage': 'I have arrived at the gate, please buzz me in.',
        'time': '2m ago',
        'unread': true,
      },
      {
        'name': 'Daniel Kim',
        'avatar': 'DK',
        'task': 'Assemble standing desk',
        'lastMessage': 'Bringing the electric screwdriver as requested!',
        'time': '1h ago',
        'unread': false,
      },
      {
        'name': 'Chef Grace',
        'avatar': 'CG',
        'task': 'Private chef meal prep',
        'lastMessage': 'The menu is ready. See you on Saturday!',
        'time': 'Yesterday',
        'unread': false,
      },
    ];

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
              child: ListView.separated(
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
                          TasklyAvatar(initials: chat['avatar'] as String, size: 50, verified: true),
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
                  TasklyAvatar(initials: _currentUser.initials, size: 64, verified: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.name,
                          style: context.type.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
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
            const SizedBox(height: 24),

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
              subtitle: 'Visa ending in 4242 & M-Pesa',
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
                  TasklyAvatar(initials: task.tasker!.avatar, size: 44, verified: true),
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
                TasklyAvatar(initials: widget.initials, size: 42, verified: true),
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
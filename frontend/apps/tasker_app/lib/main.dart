import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_components/shared_components.dart';
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
  runApp(const TasklyTaskerApp());
}

class TasklyTaskerApp extends StatefulWidget {
  const TasklyTaskerApp({super.key});

  @override
  State<TasklyTaskerApp> createState() => _TasklyTaskerAppState();
}

class _TasklyTaskerAppState extends State<TasklyTaskerApp> {
  TaskerProfile? _authenticatedTasker;
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
        if (user != null && _authenticatedTasker == null) {
          final email = user.email ?? '';
          final fullName = (user.userMetadata?['full_name'] as String?) ??
              (user.userMetadata?['name'] as String?) ??
              (email.contains('@') ? email.split('@').first : 'Pro Tasker');
          final parts = fullName.trim().split(RegExp(r'\s+'));
          final avatar = parts.isNotEmpty
              ? parts.map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
              : 'PT';

          final tasker = TaskerProfile(
            name: fullName,
            avatar: avatar.isNotEmpty ? avatar : 'PT',
            skill: 'General Specialist',
            rating: 0.0,
            distance: '0 km',
            matchScore: 0,
            completionRate: 0,
            reviews: 0,
            verified: false,
          );

          try {
            ApiService.googleSignIn(
              email: email,
              name: fullName,
              photoUrl: user.userMetadata?['avatar_url'] as String?,
              idToken: session?.accessToken,
            );
          } catch (_) {}

          _handleLoginSuccess(tasker);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('tasker_is_logged_in') ?? false;
      if (isLoggedIn) {
        final name = prefs.getString('tasker_name') ?? 'Pro Tasker';
        final skill = prefs.getString('tasker_skill') ?? 'General Specialist';
        final avatar = prefs.getString('tasker_avatar') ?? 'PT';
        final rating = prefs.getDouble('tasker_rating') ?? 0.0;
        final reviews = prefs.getInt('tasker_reviews') ?? 0;
        final verified = prefs.getBool('tasker_verified') ?? false;
        final idNumber = prefs.getString('tasker_id_number');
        final photoUrl = prefs.getString('tasker_profile_photo');

        setState(() {
          _authenticatedTasker = TaskerProfile(
            name: name,
            avatar: avatar,
            skill: skill,
            rating: rating,
            distance: '0 km',
            matchScore: 0,
            completionRate: 0,
            reviews: reviews,
            verified: verified,
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

  Future<void> _handleLoginSuccess(TaskerProfile tasker) async {
    setState(() {
      _authenticatedTasker = tasker;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tasker_is_logged_in', true);
      await prefs.setString('tasker_name', tasker.name);
      await prefs.setString('tasker_skill', tasker.skill);
      await prefs.setString('tasker_avatar', tasker.avatar);
      await prefs.setDouble('tasker_rating', tasker.rating);
      await prefs.setInt('tasker_reviews', tasker.reviews);
      await prefs.setBool('tasker_verified', tasker.verified);
      if (tasker.idNumber != null) await prefs.setString('tasker_id_number', tasker.idNumber!);
      if (tasker.profilePictureUrl != null) await prefs.setString('tasker_profile_photo', tasker.profilePictureUrl!);
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    setState(() {
      _authenticatedTasker = null;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tasker_is_logged_in');
      await prefs.remove('tasker_name');
      await prefs.remove('tasker_skill');
      await prefs.remove('tasker_avatar');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Taskly - Tasker Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: _checkingSession
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _authenticatedTasker == null
                  ? TaskerAuthScreen(
                      onAuthenticated: _handleLoginSuccess,
                    )
                  : TaskerMainNavigationScreen(
                      currentTasker: _authenticatedTasker!,
                      onLogout: _handleLogout,
                    ),
        );
      },
    );
  }
}

class TaskerMainNavigationScreen extends StatefulWidget {
  const TaskerMainNavigationScreen({
    super.key,
    required this.currentTasker,
    this.onLogout,
  });

  final TaskerProfile currentTasker;
  final VoidCallback? onLogout;

  @override
  State<TaskerMainNavigationScreen> createState() => _TaskerMainNavigationScreenState();
}

class _TaskerMainNavigationScreenState extends State<TaskerMainNavigationScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  late TaskerProfile _currentTasker;

  // Available jobs state
  late List<AvailableJob> _jobsFeed;
  
  // Active/Scheduled tasks state with workflow stages
  late List<Map<String, dynamic>> _activeJobs;

  @override
  void initState() {
    super.initState();
    _currentTasker = widget.currentTasker;
    _jobsFeed = List<AvailableJob>.from(availableJobs);
    _activeJobs = [];
  }

  @override
  void didUpdateWidget(covariant TaskerMainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTasker != widget.currentTasker) {
      setState(() {
        _currentTasker = widget.currentTasker;
      });
    }
  }

  void _acceptJob(AvailableJob job) {
    setState(() {
      _jobsFeed.remove(job);
      _activeJobs.insert(0, {
        'title': job.title,
        'customer': job.customer,
        'address': 'Westlands Area, ${job.distance} away',
        'budget': job.budget,
        'time': 'Today, ${job.duration}',
        'stage': 'Accepted',
        'notes': job.instructions,
        'customerPhone': '+254 700 123 456',
      });
      _currentIndex = 1; // Switch to Schedule / Active tab
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Accepted "${job.title}"! Added to your schedule.')),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _declineJob(AvailableJob job) {
    setState(() {
      _jobsFeed.remove(job);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Declined "${job.title}". New jobs will appear shortly.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _advanceJobStage(int index) {
    final job = _activeJobs[index];
    final currentStage = job['stage'] as String;
    String nextStage = currentStage;

    if (currentStage == 'Accepted') {
      nextStage = 'En Route';
    } else if (currentStage == 'En Route') {
      nextStage = 'Arrived';
    } else if (currentStage == 'Arrived') {
      nextStage = 'In Progress';
    } else if (currentStage == 'In Progress') {
      nextStage = 'Completed';
    }

    setState(() {
      job['stage'] = nextStage;
    });

    if (nextStage == 'Completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Job Completed! Payout of ${job['budget']} credited to your earnings.'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildJobsFeedScreen(),
      _buildActiveScheduleScreen(),
      _buildEarningsScreen(),
      _buildClientChatsScreen(),
      _buildTaskerProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: TasklyBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_rounded), label: 'Jobs Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_rounded), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Clients'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Pro Profile'),
        ],
      ),
    );
  }

  Widget _buildJobsFeedScreen() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header
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
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO TASKER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isOnline ? AppColors.primary : AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isOnline ? 'Online • Ready for jobs' : 'Offline • Paused',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isOnline ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Online / Offline Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: AppCards.surface(radius: AppRadius.pill),
                        child: Row(
                          children: [
                            Text(
                              _isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _isOnline ? AppColors.danger : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Switch(
                              value: _isOnline,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => setState(() => _isOnline = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Today Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.lgBorder,
                      boxShadow: AppShadows.glow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Welcome, ${_currentTasker.name}!',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '★ ${_currentTasker.rating}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_jobsFeed.length} AI-matched tasks available near you (${_currentTasker.skill}). Tap to accept and start earning.',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Requests (${_jobsFeed.length})',
                        style: context.type.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (!_isOnline)
                        const Text(
                          'Offline Mode Active',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Jobs Feed List
          if (_jobsFeed.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'All caught up!',
                message: 'No new job requests right now. New customer tasks will pop up automatically.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final job = _jobsFeed[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: AppCards.surface(radius: AppRadius.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    job.title,
                                    style: context.type.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.aiGradient,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${job.match}% MATCH',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.instructions,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                MetaChip(label: job.budget, icon: Icons.payments_rounded),
                                MetaChip(label: job.distance, icon: Icons.near_me_rounded),
                                MetaChip(label: job.duration, icon: Icons.schedule_rounded),
                                MetaChip(label: 'Client: ${job.customer}', icon: Icons.person_rounded),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: TasklyButton(
                                    label: 'Decline',
                                    icon: Icons.close_rounded,
                                    secondary: true,
                                    compact: true,
                                    onPressed: () => _declineJob(job),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TasklyButton(
                                    label: 'Accept Job',
                                    icon: Icons.check_rounded,
                                    compact: true,
                                    onPressed: () => _acceptJob(job),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _jobsFeed.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveScheduleScreen() {
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
                  'My Schedule',
                  style: context.type.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_activeJobs.length} Jobs in Progress',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Manage your active bookings and update job stages in real-time',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),

            Expanded(
              child: _activeJobs.isEmpty
                  ? const EmptyState(
                      icon: Icons.calendar_today_rounded,
                      title: 'No Active Tasks',
                      message: 'Accept jobs from the feed to start working.',
                    )
                  : ListView.builder(
                      itemCount: _activeJobs.length,
                      itemBuilder: (context, index) {
                        final job = _activeJobs[index];
                        final stage = job['stage'] as String;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: AppCards.surface(radius: AppRadius.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['title'] as String,
                                            style: context.type.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Client: ${job['customer']}',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStageBadge(stage),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        job['address'] as String,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      job['time'] as String,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      job['budget'] as String,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Workflow Action Button
                                _buildWorkflowButton(stage, index),
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

  Widget _buildStageBadge(String stage) {
    Color bg = AppColors.elevated;
    Color fg = AppColors.textPrimary;

    if (stage == 'Accepted') {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blue;
    } else if (stage == 'En Route') {
      bg = Colors.orange.withValues(alpha: 0.15);
      fg = Colors.orange;
    } else if (stage == 'Arrived') {
      bg = Colors.purple.withValues(alpha: 0.15);
      fg = Colors.purpleAccent;
    } else if (stage == 'In Progress') {
      bg = AppColors.primary.withValues(alpha: 0.15);
      fg = AppColors.primary;
    } else if (stage == 'Completed') {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        stage.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }

  Widget _buildWorkflowButton(String stage, int index) {
    if (stage == 'Accepted') {
      return TasklyButton(
        label: 'Start Navigation / En Route',
        icon: Icons.navigation_rounded,
        compact: true,
        onPressed: () => _advanceJobStage(index),
      );
    } else if (stage == 'En Route') {
      return TasklyButton(
        label: 'Mark as Arrived at Location',
        icon: Icons.location_on_rounded,
        compact: true,
        onPressed: () => _advanceJobStage(index),
      );
    } else if (stage == 'Arrived') {
      return TasklyButton(
        label: 'Start Working on Task',
        icon: Icons.play_arrow_rounded,
        compact: true,
        onPressed: () => _advanceJobStage(index),
      );
    } else if (stage == 'In Progress') {
      return TasklyButton(
        label: 'Complete Task & Request Payout',
        icon: Icons.check_circle_rounded,
        compact: true,
        onPressed: () => _advanceJobStage(index),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '✓ Completed & Paid',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800),
          ),
        ),
      );
    }
  }

  Widget _buildEarningsScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings & Payouts',
              style: context.type.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your weekly income and performance statistics',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Earnings Balance Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance This Week',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Clean Slate • KES 0.00',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r'$0.00',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TasklyButton(
                          label: 'Cash Out Instantly',
                          icon: Icons.account_balance_wallet_rounded,
                          compact: true,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Instant Payout'),
                                content: const Text(
                                  'Current balance is \$0.00. Accept and complete customer jobs to earn payouts directly to M-Pesa or Bank.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Chart
            Text(
              'Weekly Breakdown',
              style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppCards.surface(radius: AppRadius.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final point in earnings)
                        Column(
                          children: [
                            Text(
                              '\$${point.amount.toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 24,
                              height: point.amount > 0 ? (point.amount / 310) * 110 : 6.0,
                              decoration: BoxDecoration(
                                gradient: point.amount > 200
                                    ? AppColors.primaryGradient
                                    : AppColors.aiGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              point.label,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Performance KPIs
            Text(
              'Pro Performance Stats',
              style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Completed Jobs',
                    value: '${_currentTasker.reviews}',
                    icon: Icons.done_all_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Completion Rate',
                    value: '${_currentTasker.completionRate}%',
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Client Rating',
                    value: '${_currentTasker.rating} ★',
                    icon: Icons.star_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Match Quality',
                    value: '${_currentTasker.matchScore}%',
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCards.surface(radius: AppRadius.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildClientChatsScreen() {
    final List<Map<String, String>> clients = [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client Messages',
              style: context.type.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chat with clients for your active and scheduled tasks',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: clients.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No Client Messages Yet',
                      message: 'When clients book your services, direct conversations will appear here.',
                    )
                  : ListView.separated(
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return InkWell(
                          onTap: () => _openTaskerChatModal(
                            client['name']!,
                            client['avatar']!,
                            client['task']!,
                          ),
                          borderRadius: AppRadius.lgBorder,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppCards.surface(radius: AppRadius.lg),
                            child: Row(
                              children: [
                                TasklyAvatar(initials: client['avatar']!, size: 50, verified: false),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            client['name']!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            client['time']!,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        client['task']!,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        client['lastMsg']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
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

  Widget _buildTaskerProfileScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pro Profile & Settings',
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
                    initials: _currentTasker.avatar,
                    imageUrl: _currentTasker.profilePictureUrl,
                    size: 64,
                    verified: _currentTasker.verified,
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
                                _currentTasker.name,
                                style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_currentTasker.verified)
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
                        Text(
                          _currentTasker.skill,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            RatingStars(rating: _currentTasker.rating),
                            const SizedBox(width: 8),
                            Text(
                              '(${_currentTasker.reviews} reviews)',
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

            // Pro Identity Verification Card
            if (!_currentTasker.verified)
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
                                'Pro Identity Verification Required',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Upload your profile photo and confirm your National ID details to earn the verified badge.',
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
                        onPressed: _showTaskerVerificationModal,
                        icon: const Icon(Icons.verified_user_rounded, size: 16),
                        label: const Text('Complete Pro Verification', style: TextStyle(fontWeight: FontWeight.w700)),
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
                            'Taskly Pro Verified Tasker',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF00B37E)),
                          ),
                          Text(
                            'National ID: ${_currentTasker.idNumber ?? "Verified"} • Verified badge active on client feed',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Settings Options
            Container(
              decoration: AppCards.surface(radius: AppRadius.md),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.dark_mode_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text('Theme / Appearance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: Text(AppColors.isDarkMode ? 'Dark Mode' : 'Light Mode'),
                trailing: Switch(
                  value: AppColors.isDarkMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) {
                    AppTheme.themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: AppCards.surface(radius: AppRadius.md),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.attach_money_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text('Base Hourly Rate', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: const Text(r'$42.00 / hour (Adjust in service settings)'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ),
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
                      content: const Text('Are you sure you want to log out of Taskly Tasker Pro?'),
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
                  'Sign out of ${_currentTasker.name}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                'Taskly AI Tasker Pro • v1.0.0 (Web & Mobile)',
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

  void _openTaskerChatModal(String clientName, String initials, String taskTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskerChatWidget(
        clientName: clientName,
        initials: initials,
        taskTitle: taskTitle,
      ),
    );
  }

  void _showTaskerVerificationModal() {
    final nameController = TextEditingController(text: _currentTasker.name);
    final idController = TextEditingController(text: _currentTasker.idNumber ?? '');
    final skillController = TextEditingController(text: _currentTasker.skill);
    String selectedPhoto = _currentTasker.profilePictureUrl ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80';
    bool confirmedDeclaration = false;

    final avatarPresets = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=256&q=80',
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=256&q=80',
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
                          'Pro Verification',
                          style: context.type.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Upload photo & verify National ID credentials',
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
                        '1. PRO PROFILE PHOTO',
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
                            initials: _currentTasker.avatar,
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
                                  'A clear face photo helps clients recognize and trust you on bookings.',
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

                      // Personal & Professional Details
                      Text(
                        '2. PERSONAL & CREDENTIAL DETAILS',
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
                          hintText: 'e.g. Maya Johnson',
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
                        controller: skillController,
                        decoration: const InputDecoration(
                          labelText: 'Primary Trade or Skill',
                          hintText: 'e.g. Deep Cleaning & Sanitization',
                          prefixIcon: Icon(Icons.handyman_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Agreement checkbox
                      CheckboxListTile(
                        value: confirmedDeclaration,
                        onChanged: (val) => setModalState(() => confirmedDeclaration = val ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'I declare that my National ID and professional skill information are accurate, authentic, and free of criminal records.',
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
                      final skill = skillController.text.trim();

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
                      if (!confirmedDeclaration) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please accept the background declaration to proceed.')),
                        );
                        return;
                      }

                      // Update local state
                      final updatedTasker = _currentTasker.copyWith(
                        name: name,
                        idNumber: id,
                        profilePictureUrl: selectedPhoto,
                        skill: skill.isNotEmpty ? skill : _currentTasker.skill,
                        verified: true,
                      );

                      setState(() {
                        _currentTasker = updatedTasker;
                      });

                      // Persist to SharedPreferences
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('tasker_verified', true);
                        await prefs.setString('tasker_id_number', id);
                        await prefs.setString('tasker_profile_photo', selectedPhoto);
                        await prefs.setString('tasker_name', name);
                        if (skill.isNotEmpty) await prefs.setString('tasker_skill', skill);
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
                                child: Text('Pro Identity verified successfully! Verified badge activated.'),
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
                      'Confirm & Activate Pro Verification',
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
}

class _TaskerChatWidget extends StatefulWidget {
  const _TaskerChatWidget({
    required this.clientName,
    required this.initials,
    required this.taskTitle,
  });

  final String clientName;
  final String initials;
  final String taskTitle;

  @override
  State<_TaskerChatWidget> createState() => _TaskerChatWidgetState();
}

class _TaskerChatWidgetState extends State<_TaskerChatWidget> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      {
        'isMe': false,
        'text': 'Hi Maya! Looking forward to the booking today.',
        'time': '10:00 AM',
      },
      {
        'isMe': true,
        'text': 'Hello! On my way now, should be there in about 15 minutes.',
        'time': '10:05 AM',
      },
    ]);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'time': 'Just now',
      });
    });
    _msgController.clear();
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
                        widget.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        'Client for: ${widget.taskTitle}',
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
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
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

          // Quick Action Responses
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _quickReplyChip('On my way!'),
                const SizedBox(width: 8),
                _quickReplyChip('Arrived at the location.'),
                const SizedBox(width: 8),
                _quickReplyChip('Task completed!'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: (val) => _sendMessage(val),
                    decoration: InputDecoration(
                      hintText: 'Message ${widget.clientName}...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _sendMessage(_msgController.text),
                  icon: Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickReplyChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: AppColors.border),
      onPressed: () => _sendMessage(text),
    );
  }
}
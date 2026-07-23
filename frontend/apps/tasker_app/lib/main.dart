import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_ui/shared_ui.dart';

const _taskerHero =
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=1200&q=80';
const _workspaceHero = 'public/images/movers.jpg';
const _jobHero = 'public/images/cleaner.jpg';
const _cleaningHero = 'public/images/cleaner.jpg';
const _movingHero = 'public/images/movers.jpg';
const _babysittingHero = 'public/images/babysitter.jpg';

void main() => runApp(const TasklyTaskerApp());

class TasklyTaskerApp extends StatelessWidget {
  const TasklyTaskerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Taskly Tasker',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const TaskerWelcomeScreen(),
        );
      },
    );
  }
}

class TaskerWelcomeScreen extends StatelessWidget {
  const TaskerWelcomeScreen({super.key});

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
                  height: 320,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const PremiumImage(url: _taskerHero, height: 320),
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
                          left: 20, top: 20, child: TasklyLogo(size: 48)),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.18),
                                borderRadius: AppRadius.smBorder,
                                border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                              ),
                              child: Text(
                                'PARTNER PROGRAM',
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
                              'Earn more with Taskly',
                              style: context.type.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Flexible work, premium customers, intelligent job recommendations, and clear earnings tools.',
                              style: TextStyle(
                                color: AppColors.textSecondary, 
                                height: 1.45,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
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
            const _Benefit(
              icon: Icons.schedule_rounded,
              title: 'Flexible work',
              text: 'Choose jobs that fit your day, complete tasks on your own terms.',
            ),
            const _Benefit(
              icon: Icons.payments_rounded,
              title: 'High-quality earnings',
              text: 'See budgets, distance, and duration upfront before accepting.',
            ),
            const _Benefit(
              icon: Icons.trending_up_rounded,
              title: 'Growth tools',
              text: 'Track ratings, completion, and repeat customers in a clean dashboard.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TasklyButton(
              label: 'Become a Tasker',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final titles = const [
    'Personal info',
    'ID upload',
    'Profile photo',
    'Skills',
    'Experience',
    'Availability',
    'Payment',
    'Review'
  ];

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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        _workspaceHero,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.92),
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TASKER ONBOARDING',
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  titles[step], 
                                  style: context.type.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                  ),
                                ),
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
            const SizedBox(height: AppSpacing.lg),
            TasklySurface(
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      titles.length,
                      (i) => Expanded(
                        child: AnimatedContainer(
                          duration: AppAnimations.medium,
                          height: 6,
                          margin: EdgeInsets.only(
                              right: i == titles.length - 1 ? 0 : 6),
                          decoration: BoxDecoration(
                            color: i <= step
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: AppRadius.pillBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedSwitcher(
                      duration: AppAnimations.medium,
                      child: _bodyForStep(step)),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (step > 0)
                        Expanded(
                          child: TasklyButton(
                            label: 'Back',
                            icon: Icons.arrow_back_rounded,
                            secondary: true,
                            compact: true,
                            onPressed: () => setState(() => step--),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TasklyButton(
                          label:
                              step == titles.length - 1 ? 'Submit' : 'Continue',
                          icon: Icons.arrow_forward_rounded,
                          compact: true,
                          onPressed: () {
                            if (step == titles.length - 1) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (_) => const TaskerShell()),
                              );
                            } else {
                              setState(() => step++);
                            }
                          },
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

  Widget _bodyForStep(int step) {
    return switch (step) {
      0 => const _Fields(
          key: ValueKey('personal'),
          labels: ['Full name', 'Phone number', 'City'],
          icon: Icons.person_rounded,
        ),
      1 => const _UploadCard(
          key: ValueKey('id'),
          icon: Icons.badge_rounded,
          title: 'Upload government ID',
          imageUrl: _workspaceHero,
        ),
      2 => const _UploadCard(
          key: ValueKey('photo'),
          icon: Icons.add_a_photo_rounded,
          title: 'Add profile photo',
          imageUrl: _taskerHero,
        ),
      3 => _SkillSelector(key: const ValueKey('skills')),
      4 => const _Fields(
          key: ValueKey('experience'),
          labels: ['Years of experience', 'About your services', 'Languages'],
          icon: Icons.workspace_premium_rounded,
        ),
      5 => const _AvailabilityCard(key: ValueKey('availability')),
      6 => const _Fields(
          key: ValueKey('payment'),
          labels: ['M-Pesa number', 'Account name'],
          icon: Icons.account_balance_wallet_rounded,
        ),
      _ => _ReviewCard(key: ValueKey('review')),
    };
  }
}

class TaskerShell extends StatefulWidget {
  const TaskerShell({super.key});

  @override
  State<TaskerShell> createState() => _TaskerShellState();
}

class _TaskerShellState extends State<TaskerShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const JobsFeedScreen(),
      const MyJobsScreen(),
      const EarningsScreen(),
      const TaskerProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: TasklyBottomNav(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.work_rounded), label: 'Jobs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded), label: 'Mine'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Earn'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                const _CirclePhoto(url: _taskerHero),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, Maya',
                        style: context.type.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'You are online and accepting jobs',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppTheme.themeModeNotifier,
                    builder: (context, mode, child) {
                      return IconButton(
                        onPressed: () {
                          AppTheme.themeModeNotifier.value =
                              mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                        },
                        icon: Icon(
                          mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
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
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              boxShadow: AppShadows.glow,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.2),
            ),
            child: TasklySurface(
              gradient: AppColors.heroGradient,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S EARNINGS',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          r'$240',
                          style: context.type.displayMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          r'$620 away from weekly goal',
                          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(painter: _MiniChartPainter()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Weekly',
                  value: r'$1,180',
                  icon: Icons.calendar_view_week_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Monthly',
                  value: r'$4,620',
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Rating',
                  value: '4.98',
                  icon: Icons.star_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Completion',
                  value: '99%',
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Recommended jobs', action: 'See all'),
          const SizedBox(height: AppSpacing.md),
          ...availableJobs.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: JobCard(job: job, imageUrl: _jobHero),
            ),
          ),
        ],
      ),
    );
  }
}

class JobsFeedScreen extends StatelessWidget {
  const JobsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available jobs', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView.separated(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        itemCount: availableJobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final job = availableJobs[index];
          return JobCard(
            job: job,
            imageUrl: index == 0
                ? _cleaningHero
                : index == 1
                    ? _movingHero
                    : _babysittingHero,
            onDetails: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
            ),
          );
        },
      ),
    );
  }
}

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  int tab = 0;
  final tabs = const ['Upcoming', 'Active', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My jobs', style: TextStyle(fontWeight: FontWeight.w900)),
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
                      _workspaceHero,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.92),
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Manage bookings with a polished queue.',
                            style: context.type.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Row(
              children: [
                for (final (i, label) in tabs.indexed)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => tab = i),
                      borderRadius: AppRadius.mdBorder,
                      child: AnimatedContainer(
                        duration: AppAnimations.medium,
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: tab == i ? AppColors.elevated : Colors.transparent,
                          borderRadius: AppRadius.mdBorder,
                          border: tab == i ? Border.all(color: AppColors.border, width: 1.0) : null,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: tab == i ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...demoTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: TaskCard(
                jobTitle: task.title,
                category: task.category,
                description: task.description,
                budget: task.budget,
                status: task.status,
                imageUrl: _jobHero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({super.key, required this.job});

  final AvailableJob job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            title: const Text('Job details', style: TextStyle(fontWeight: FontWeight.w900)),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PremiumImage(
                    url: job.title.contains('Move')
                        ? _movingHero
                        : _cleaningHero,
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
                          job.title, 
                          style: context.type.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          job.customer,
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
                  JobCard(job: job, imageUrl: _jobHero, showActions: false),
                  const SizedBox(height: AppSpacing.lg),
                  TasklySurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer profile', 
                          style: context.type.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const _CirclePhoto(url: _taskerHero),
                          title: Text(
                            job.customer, 
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          subtitle: Text(
                            '4.96 rating • 32 tasks booked',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TasklyButton(
                          label: 'Start Job',
                          icon: Icons.play_arrow_rounded,
                          secondary: true,
                          compact: true,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TasklyButton(
                          label: 'Complete',
                          icon: Icons.check_rounded,
                          compact: true,
                          onPressed: () {},
                        ),
                      ),
                    ],
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

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgBorder,
              boxShadow: AppShadows.glow,
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.2),
            ),
            child: TasklySurface(
              gradient: AppColors.heroGradient,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THIS WEEK',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          r'$1,180',
                          style: context.type.displayMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Premium dashboard for real earning visibility.',
                          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(painter: _EarningsPainter()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Jobs', 
                  value: '14', 
                  icon: Icons.work_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Avg / job',
                  value: r'$84',
                  icon: Icons.insights_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Conversion',
                  value: '92%',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Repeat',
                  value: '41%',
                  icon: Icons.repeat_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Withdrawal history', action: 'Manage'),
          const SizedBox(height: AppSpacing.md),
          const _HistoryTile(
            label: 'M-Pesa withdrawal', 
            value: r'$420', 
            date: 'Jun 21',
          ),
          const _HistoryTile(
            label: 'Card transfer', 
            value: r'$360', 
            date: 'Jun 14',
          ),
        ],
      ),
    );
  }
}

class TaskerProfileScreen extends StatelessWidget {
  const TaskerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: AppSpacing.page,
        physics: const BouncingScrollPhysics(),
        children: [
          TasklySurface(
            gradient: AppColors.heroGradient,
            child: Column(
              children: [
                const _CirclePhoto(url: _taskerHero, size: 92),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Maya Johnson', 
                  style: context.type.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Verified cleaning specialist',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _ProfileBadge(
                      label: 'ID verified', 
                      icon: Icons.verified_rounded,
                    ),
                    _ProfileBadge(
                      label: 'Background checked',
                      icon: Icons.security_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Rating',
                  value: '4.98',
                  icon: Icons.star_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Reviews',
                  value: '324',
                  icon: Icons.rate_review_rounded,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'Repeat',
                  value: '41%',
                  icon: Icons.repeat_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Skills', action: 'Edit'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              'Deep cleaning',
              'Laundry',
              'Move-out clean',
              'Organizing',
            ].map((skill) => Chip(label: Text(skill))).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: 'Recent reviews', action: 'All'),
          SizedBox(height: AppSpacing.md),
          TasklySurface(
            child: Text(
              'Excellent work, fast communication, and hotel-level attention to detail.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TasklySurface(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.mdBorder,
                boxShadow: AppShadows.glow,
              ),
              child: Icon(icon, color: Colors.black, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: context.type.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4),
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

class _Fields extends StatelessWidget {
  const _Fields({super.key, required this.labels, required this.icon});
  final List<String> labels;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final label in labels) ...[
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _InputField(label: label)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.imageUrl});
  final IconData icon;
  final String title;
  final String imageUrl;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgBorder,
        child: Stack(
          children: [
            PremiumImage(url: imageUrl, height: 230),
            Container(
              height: 230,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8)
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.mdBorder,
                      boxShadow: AppShadows.glow,
                    ),
                    child: Icon(icon, color: Colors.black, size: 22),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title, 
                    style: context.type.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to upload or take a photo',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5),
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

class _SkillSelector extends StatelessWidget {
  const _SkillSelector({super.key});
  @override
  Widget build(BuildContext context) {
    return TasklySurface(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          'Cleaning',
          'Handyman',
          'Laundry',
          'Organizing',
          'Cooking',
          'Moving',
        ].map((category) {
          final selected =
              ['Cleaning', 'Handyman', 'Laundry'].contains(category);
          return FilterChip(
            selected: selected,
            label: Text(category),
            onSelected: (_) {},
          );
        }).toList(),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({super.key});
  @override
  Widget build(BuildContext context) {
    return TasklySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Working days', 
            style: context.type.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) =>
                    ChoiceChip(label: Text(day), selected: day != 'Thu'))
                .toList(),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Preferred hours',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          RangeSlider(
              values: const RangeValues(8, 18),
              min: 6,
              max: 22,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  _ReviewCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.2),
        boxShadow: AppShadows.glow,
      ),
      child: TasklySurface(
        gradient: AppColors.heroGradient,
        child: Column(
          children: [
            Icon(Icons.fact_check_rounded,
                color: AppColors.primary, size: 62),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Application ready', 
              style: context.type.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'This frontend simulates submission and opens the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.45, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return TasklySurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value, 
            style: context.type.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(
      {required this.label, required this.value, required this.date});
  final String label;
  final String value;
  final String date;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TasklySurface(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(date,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(
              value, 
              style: context.type.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label), 
      avatar: Icon(icon, size: 14),
    );
  }
}

class _CirclePhoto extends StatelessWidget {
  const _CirclePhoto({required this.url, this.size = 52});
  final String url;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: AppShadows.glow,
      ),
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: AppColors.elevated,
            child: const Icon(Icons.person_rounded),
          ),
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.primaryGradient.createShader(Offset.zero & size)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(10, size.height * .76)
      ..quadraticBezierTo(size.width * .26, size.height * .18, size.width * .52,
          size.height * .42)
      ..quadraticBezierTo(size.width * .76, size.height * .68, size.width - 10,
          size.height * .24);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EarningsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.primaryGradient.createShader(Offset.zero & size)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.25)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(12, size.height * .7)
      ..quadraticBezierTo(size.width * .28, size.height * .22, size.width * .52,
          size.height * .52)
      ..quadraticBezierTo(size.width * .72, size.height * .78, size.width - 14,
          size.height * .24);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) {
    return Row(
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
          onPressed: () {}, 
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard(
      {super.key,
      required this.job,
      required this.imageUrl,
      this.onDetails,
      this.showActions = true});
  final AvailableJob job;
  final String imageUrl;
  final VoidCallback? onDetails;
  final bool showActions;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              PremiumImage(url: imageUrl, height: 160),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                  ),
                  child: Text(
                    'MATCH ${job.match}%',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.58),
                  child: const Icon(Icons.favorite_border_rounded, size: 18, color: Colors.white),
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
                        job.title, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      job.budget,
                      style: context.type.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  job.instructions,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(text: job.customer, icon: Icons.person_rounded),
                    _Pill(text: job.distance, icon: Icons.near_me_rounded),
                    _Pill(text: job.duration, icon: Icons.schedule_rounded),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TasklyButton(
                          label: 'Save',
                          icon: Icons.bookmark_add_rounded,
                          secondary: true,
                          compact: true,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TasklyButton(
                          label: 'Details',
                          icon: Icons.chevron_right_rounded,
                          compact: true,
                          onPressed: onDetails ?? () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard(
      {super.key,
      required this.jobTitle,
      required this.category,
      required this.description,
      required this.budget,
      required this.status,
      required this.imageUrl});
  final String jobTitle;
  final String category;
  final String description;
  final String budget;
  final String status;
  final String imageUrl;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
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
                          jobTitle, 
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
                        budget,
                        style: context.type.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Pill(text: category, icon: Icons.home_repair_service_rounded),
                      _Pill(text: status, icon: Icons.timeline_rounded),
                    ],
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

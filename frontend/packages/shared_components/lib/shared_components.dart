import 'package:ai_mock/ai_mock.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_ui/shared_ui.dart';

IconData tasklyIcon(String key) {
  return switch (key) {
    'sparkles' => Icons.cleaning_services_rounded,
    'child_care' => Icons.child_care_rounded,
    'restaurant' => Icons.restaurant_rounded,
    'local_laundry_service' => Icons.local_laundry_service_rounded,
    'handyman' => Icons.handyman_rounded,
    'local_shipping' => Icons.local_shipping_rounded,
    'delivery_dining' => Icons.delivery_dining_rounded,
    _ => Icons.task_alt_rounded,
  };
}


String _getCategoryBackground(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('clean')) return 'public/images/cleaner.jpg';
  if (normalized.contains('baby') || normalized.contains('child')) return 'public/images/babysitter.jpg';
  if (normalized.contains('cook') || normalized.contains('restaurant')) return 'public/images/cook.jpg';
  if (normalized.contains('mov') || normalized.contains('shipping')) return 'public/images/movers.jpg';
  if (normalized.contains('deliver')) return 'public/images/delivery.jpg';
  return 'public/images/people.jpg';
}

class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.index = 0,
  });

  final ServiceCategory category;
  final VoidCallback? onTap;
  final int index;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getCategoryBackground(widget.category.name);
    return Listener(
      onPointerDown: (_) => setState(() => hovered = true),
      onPointerCancel: (_) => setState(() => hovered = false),
      onPointerUp: (_) => setState(() => hovered = false),
      child: AnimatedScale(
        scale: hovered ? 0.96 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.easeOut,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.lgBorder,
          child: Container(
            width: 160,
            decoration: AppCards.surface(
              radius: AppRadius.lg,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lgBorder,
              child: Stack(
                clipBehavior: Clip.antiAlias,
                fit: StackFit.passthrough,
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
                          width: 48,
                          height: 48,
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
                            tasklyIcon(widget.category.icon),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'From ${widget.category.averagePrice}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({super.key, required this.preview});

  final AiTaskPreview preview;

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Task Preview',
                      style: context.type.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Text(
                      'Instantly generated brief',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const AiTypingIndicator(
                backgroundColor: Color(0xFFF8FAFC),
                borderColor: Color(0xFFE2E8F0),
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
            style: const TextStyle(color: Color(0xFF475569), height: 1.5, fontSize: 13.5),
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
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: AppSpacing.sm),
          ...preview.recommendations.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0x1A00F299),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF475569), 
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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

class TaskerCard extends StatelessWidget {
  const TaskerCard({
    super.key,
    required this.tasker,
    this.onTap,
    this.horizontal = false,
  });

  final TaskerProfile tasker;
  final VoidCallback? onTap;
  final bool horizontal;

  static const _taskerImages = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final imageIndex = tasker.name.hashCode.abs() % _taskerImages.length;
    final imageUrl = _taskerImages[imageIndex];

    final cardChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            PremiumImage(
              url: imageUrl, 
              height: horizontal ? 140 : 160,
              radius: AppRadius.lg,
            ),
            if (tasker.verified)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      tasker.rating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: AppShadows.glow,
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
                tasker.name,
                style: context.type.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tasker.skill,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _InfoBadge(text: '${tasker.reviews} jobs'),
                  _InfoBadge(text: tasker.distance),
                  _InfoBadge(text: '${tasker.completionRate}% rate'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r'$42/hr',
                      style: context.type.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
    );

    return SizedBox(
      width: horizontal ? 280 : double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgBorder,
          child: cardChild,
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final TasklyTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImagePlaceholder(
                  icon: tasklyIcon(task.category.toLowerCase()),
                  height: 160,
                  label: task.category,
                ),
                Positioned(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _FavoriteButton(onPressed: () {}),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MetaChip(label: task.budget, icon: Icons.payments_rounded),
                      MetaChip(label: task.date, icon: Icons.schedule_rounded),
                      const MetaChip(label: '1.2 mi', icon: Icons.near_me_rounded),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TasklyButton(
                    label: task.status == 'Scheduled' ? 'View booking' : 'Track task',
                    icon: Icons.arrow_forward_rounded,
                    compact: true,
                    onPressed: onTap ?? () {},
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

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.rating,
    required this.icon,
  });

  final String title;
  final String price;
  final String location;
  final double rating;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImagePlaceholder(icon: icon, height: 132, label: title),
                Positioned(
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  child: _FavoriteButton(onPressed: () {}),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        price,
                        style: context.type.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      RatingStars(rating: rating),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TasklyButton(label: 'Book now', compact: true, onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job});

  final AvailableJob job;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: AppRadius.lgBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title, 
                      style: context.type.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Score(score: job.match),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                job.instructions,
                style: TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 13.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetaChip(label: job.customer, icon: Icons.person_rounded),
                  MetaChip(label: job.distance, icon: Icons.near_me_rounded),
                  MetaChip(label: job.budget, icon: Icons.payments_rounded),
                  MetaChip(label: job.duration, icon: Icons.schedule_rounded),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TasklyButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      secondary: true,
                      compact: true,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TasklyButton(
                      label: 'Accept',
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
    );
  }
}

class MetaChip extends StatelessWidget {
  const MetaChip({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  });

  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: borderColor ?? AppColors.border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool active = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.58),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: () {
          setState(() => active = !active);
          widget.onPressed();
        },
        icon: Icon(
          active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: active ? AppColors.danger : Colors.white,
        ),
        iconSize: 20,
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.mdBorder,
        boxShadow: AppShadows.glow,
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

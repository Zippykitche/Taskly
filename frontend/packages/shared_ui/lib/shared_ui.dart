import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

class AppButtons {
  static const primaryHeight = 56.0;
  static const compactHeight = 44.0;
}

class AppCards {
  static BoxDecoration surface({
    bool elevated = false,
    Gradient? gradient,
    double radius = AppRadius.lg,
  }) {
    return BoxDecoration(
      color: gradient == null
          ? (elevated ? AppColors.elevated : AppColors.card)
          : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border, width: 1.2),
      boxShadow: AppShadows.card,
    );
  }
}

class TasklyLogo extends StatelessWidget {
  const TasklyLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * .36),
        boxShadow: AppShadows.glow,
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.black, size: size * .58),
    );
  }
}

class TasklyButton extends StatefulWidget {
  const TasklyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool compact;

  @override
  State<TasklyButton> createState() => _TasklyButtonState();
}

class _TasklyButtonState extends State<TasklyButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: widget.compact ? 13 : 15,
      letterSpacing: -0.1,
      color: widget.secondary ? AppColors.textPrimary : Colors.black,
    );

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon, 
            size: widget.compact ? 16 : 19, 
            color: widget.secondary ? AppColors.primary : Colors.black,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            widget.label, 
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );

    final height = widget.compact ? AppButtons.compactHeight : AppButtons.primaryHeight;

    return Listener(
      onPointerDown: (_) => setState(() => pressed = true),
      onPointerCancel: (_) => setState(() => pressed = false),
      onPointerUp: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: pressed ? .97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.secondary
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgBorder,
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: FilledButton(
                  onPressed: widget.onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: Size.fromHeight(height),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
                  ),
                  child: child,
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: widget.onPressed == null ? null : AppColors.primaryGradient,
                  color: widget.onPressed == null ? AppColors.elevated : null,
                  borderRadius: AppRadius.lgBorder,
                  boxShadow: widget.onPressed == null ? null : AppShadows.glow,
                ),
                child: FilledButton(
                  onPressed: widget.onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: Size.fromHeight(height),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
                  ),
                  child: child,
                ),
              ),
      ),
    );
  }
}

class TasklySurface extends StatelessWidget {
  const TasklySurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardLarge,
    this.elevated = false,
    this.gradient,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool elevated;
  final Gradient? gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: AppCards.surface(
        elevated: elevated,
        gradient: gradient,
        radius: radius,
      ),
      child: child,
    );
  }
}

class TasklySearchBar extends StatefulWidget {
  const TasklySearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.onSubmitted,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;

  @override
  State<TasklySearchBar> createState() => _TasklySearchBarState();
}

class _TasklySearchBarState extends State<TasklySearchBar> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pillBorder,
        boxShadow: focused ? AppShadows.glow : AppShadows.card,
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 1.5 : 1.2,
        ),
      ),
      child: TextField(
        focusNode: focusNode,
        controller: widget.controller,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.mic_none_rounded, color: AppColors.textSecondary, size: 22),
              ),
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 14),
            ],
          ),
          hintText: widget.hint,
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: AppRadius.pillBorder,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.pillBorder,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.pillBorder,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class TasklyAvatar extends StatelessWidget {
  const TasklyAvatar({
    super.key,
    required this.initials,
    this.size = 56,
    this.verified = false,
  });

  final String initials;
  final double size;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF00F299)], // Holographic vibe
            ),
            boxShadow: AppShadows.glow,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * .32,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        if (verified)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
      ],
    );
  }
}

class PremiumImage extends StatelessWidget {
  const PremiumImage({
    super.key,
    required this.url,
    required this.height,
    this.fit = BoxFit.cover,
    this.radius = AppRadius.lg,
    this.overlay,
  });

  final String url;
  final double height;
  final BoxFit fit;
  final double radius;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: fit,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SkeletonBox(height: double.infinity);
              },
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(gradient: AppColors.cardGradient),
                child: Center(
                  child: Icon(Icons.image_rounded, color: AppColors.textMuted, size: 42),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.icon,
    this.height = 150,
    this.label,
    this.gradient,
  });

  final IconData icon;
  final double height;
  final String? label;
  final Gradient? gradient;

  static const _categoryImages = {
    'cleaning': 'public/images/cleaner.jpg',
    'cooking': 'public/images/cook.jpg',
    'moving': 'public/images/movers.jpg',
    'handyman': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80',
    'babysitting': 'public/images/babysitter.jpg',
    'delivery': 'public/images/delivery.jpg',
    'deliveries': 'public/images/delivery.jpg',
    'laundry': 'https://images.unsplash.com/photo-1545173168-9f1947e8015e?auto=format&fit=crop&w=800&q=80',
    'home repair': 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecc?auto=format&fit=crop&w=800&q=80',
    'errands': 'public/images/people.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final normalized = (label ?? '').toLowerCase();
    String? imageUrl;
    
    for (final entry in _categoryImages.entries) {
      if (normalized.contains(entry.key)) {
        imageUrl = entry.value;
        break;
      }
    }

    if (imageUrl != null) {
      return PremiumImage(url: imageUrl, height: height);
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.heroGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -22,
            child: Icon(
              icon,
              size: height * .9,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Center(
            child: Icon(icon, size: 42, color: AppColors.primary),
          ),
          if (label != null)
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Text(
                label!,
                style: context.type.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 15});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.warning, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(2),
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: size - 1,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class AiChatBubble extends StatelessWidget {
  const AiChatBubble({super.key, required this.text, this.fromAi = true});

  final String text;
  final bool fromAi;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: fromAi ? AppColors.cardGradient : AppColors.primaryGradient,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(fromAi ? 6 : AppRadius.lg),
            bottomRight: Radius.circular(fromAi ? AppRadius.lg : 6),
          ),
          border: fromAi ? Border.all(color: AppColors.border, width: 1.2) : null,
          boxShadow: fromAi ? AppShadows.card : AppShadows.glow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fromAi) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'TASKLY AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6366F1),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: fromAi ? AppColors.textPrimary : Colors.black,
                height: 1.5,
                fontSize: 14,
                fontWeight: fromAi ? FontWeight.w600 : FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({
    super.key,
    this.backgroundColor,
    this.borderColor,
  });

  final Color? backgroundColor;
  final Color? borderColor;

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.card,
            borderRadius: AppRadius.pillBorder,
            border: Border.all(color: widget.borderColor ?? AppColors.border, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 14),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final value = math.sin((_controller.value * math.pi * 2) + (index * 1.5));
                  return Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.symmetric(horizontal: 2.5),
                    transform: Matrix4.translationValues(0, value * 3, 0),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.height = 18, this.width});

  final double height;
  final double? width;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgBorder,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + _controller.value * 3, 0),
              end: Alignment(1.5 + _controller.value * 3, 0),
              colors: [
                AppColors.card,
                AppColors.elevated,
                AppColors.card,
              ],
            ),
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TasklyLogo(size: 58),
            const SizedBox(height: AppSpacing.lg),
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: context.type.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class TasklyBottomNav extends StatelessWidget {
  const TasklyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: AppRadius.xlBorder,
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: AppShadows.nav,
        ),
        child: Row(
          children: [
            for (final (index, item) in items.indexed)
              Expanded(
                child: _NavItem(
                  item: item,
                  selected: index == currentIndex,
                  onTap: () => onTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomNavigationBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgBorder,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 56,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: AppRadius.lgBorder,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
                child: item.icon,
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

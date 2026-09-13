import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Micro-interaction button for saving / liking places with a tactile Polaroid click
/// feel, bouncy spring animation, and haptic feedback.
class BouncingHeartButton extends StatefulWidget {
  final bool isSaved;
  final VoidCallback onTap;
  final double size;
  final Color activeColor;
  final bool useHeartIcon;

  const BouncingHeartButton({
    super.key,
    required this.isSaved,
    required this.onTap,
    this.size = 34,
    this.activeColor = const Color(0xFFE11D48), // Rose red for heart / save
    this.useHeartIcon = true,
  });

  @override
  State<BouncingHeartButton> createState() => _BouncingHeartButtonState();
}

class _BouncingHeartButtonState extends State<BouncingHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.38,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.38,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 1. Polaroid shutter tactile click sound
    SystemSound.play(SystemSoundType.click);

    // 2. Crisp medium impact haptic
    HapticFeedback.mediumImpact();

    // 3. Elastic spring bounce
    _controller.forward(from: 0.0);

    // 4. Trigger toggle callback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isSaved;

    return Semantics(
      button: true,
      label: active ? 'Bỏ lưu địa điểm' : 'Thả tim lưu địa điểm',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.size),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: active
                          ? widget.activeColor.withValues(alpha: 0.28)
                          : const Color(0xFF2B1F17).withValues(alpha: 0.12),
                      blurRadius: active ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      widget.useHeartIcon
                          ? (active
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded)
                          : (active
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded),
                      key: ValueKey<bool>(active),
                      size: widget.size * 0.54,
                      color: active ? widget.activeColor : AppColors.neutral700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PrimaryActionButton extends StatefulWidget {
  final bool hasActiveSpot;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryActionButton({
    super.key,
    required this.hasActiveSpot,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<PrimaryActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Only pulse when no active spot (encouraging user to save)
    if (!widget.hasActiveSpot) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PrimaryActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.hasActiveSpot != oldWidget.hasActiveSpot) {
      if (widget.hasActiveSpot) {
        _pulseController.stop();
        _pulseController.reset();
      } else {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.hasActiveSpot ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.hasActiveSpot
                    ? [colorScheme.secondary, colorScheme.secondary.withValues(alpha: 0.8)]
                    : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.hasActiveSpot ? colorScheme.secondary : colorScheme.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: widget.hasActiveSpot 
                                ? colorScheme.onSecondary 
                                : colorScheme.onPrimary,
                            strokeWidth: 3,
                          ),
                        )
                      else
                        Icon(
                          widget.hasActiveSpot ? Icons.navigation : Icons.my_location,
                          size: 40,
                          color: widget.hasActiveSpot 
                              ? colorScheme.onSecondary 
                              : colorScheme.onPrimary,
                        ),
                      
                      const SizedBox(height: 12),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.hasActiveSpot ? 'Navigate to\nmy spot' : 'Save my\nparking',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: widget.hasActiveSpot 
                                ? colorScheme.onSecondary 
                                : colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
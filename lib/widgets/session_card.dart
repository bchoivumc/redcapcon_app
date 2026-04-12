import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/schedule_service.dart';

class SessionCard extends StatefulWidget {
  final Session session;
  final VoidCallback? onTap;
  final bool showBookmark;
  final bool isDeleting;
  final bool canRestore;
  final Future<void> Function()? onDelete;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.showBookmark = true,
    this.isDeleting = false,
    this.canRestore = false,
    this.onDelete,
  });

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> with SingleTickerProviderStateMixin {
  final ScheduleService _scheduleService = ScheduleService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getTypeColor(BuildContext context, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type.toLowerCase()) {
      case 'keynote':
      case 'plenary':
        return colorScheme.secondary;
      case 'workshop':
      case 'deep dive':
        return colorScheme.tertiary;
      case 'breakout':
      case 'talk':
        return colorScheme.primaryContainer;
      case 'break':
      case 'activity (misc)':
        return colorScheme.primaryContainer;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If currently removing, keep showing the animation
    if (_isRemoving) {
      return SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: InkWell(
              onTap: null, // Disable tap during animation
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: 0.5,
                child: AbsorbPointer(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      widget.session.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: widget.isDeleting ? 0.5 : 1.0,
      child: ColorFiltered(
        colorFilter: widget.isDeleting
            ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
              padding: const EdgeInsets.all(12),
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
                              widget.session.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: widget.isDeleting ? TextDecoration.lineThrough : null,
                                    decorationColor: Colors.red,
                                    decorationThickness: 2.0,
                                  ),
                            ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.session.timeRange,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.session.location,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.showBookmark)
                    FutureBuilder<bool>(
                      future: _scheduleService.isSessionSaved(widget.session.id),
                      builder: (context, snapshot) {
                        final isSaved = snapshot.data ?? false;
                        final showAsRestoreable = widget.canRestore;

                        return IconButton(
                          icon: Icon(
                            (isSaved || showAsRestoreable) ? Icons.bookmark : Icons.bookmark_border,
                            color: (isSaved || showAsRestoreable) ? Theme.of(context).colorScheme.primary : null,
                          ),
                          onPressed: () async {
                            // If in My Schedule with onDelete handler
                            if (widget.onDelete != null) {
                              await widget.onDelete!();
                              setState(() {}); // Refresh to show updated state
                            } else if (isSaved) {
                              // Default behavior - with animation (other screens)
                              setState(() => _isRemoving = true);
                              _animationController.forward();
                              await Future.delayed(const Duration(milliseconds: 1200));
                              if (mounted) {
                                await _scheduleService.toggleSession(widget.session.id, session: widget.session);
                              }
                              _animationController.reset();
                              if (mounted) {
                                setState(() => _isRemoving = false);
                              }
                            } else {
                              // Adding - no animation
                              await _scheduleService.toggleSession(widget.session.id, session: widget.session);
                              setState(() {});
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(context, widget.session.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.session.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTypeColor(context, widget.session.type),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.session.audience,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  if (widget.session.speaker.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.session.speaker,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
    );
  }
}

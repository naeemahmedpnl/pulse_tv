import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';
import 'focus_card.dart';

class NavItem {
  final IconData icon;
  final String label;
  final String badge;
  const NavItem(this.icon, this.label, {this.badge = ''});
}

const navItems = [
  NavItem(Icons.auto_awesome_mosaic_rounded, 'Home'),
  NavItem(Icons.live_tv_rounded, 'Live TV', badge: 'LIVE'),
  NavItem(Icons.favorite_rounded, 'Favorites'),
  NavItem(Icons.search_rounded, 'Search'),
  NavItem(Icons.tune_rounded, 'Settings'),
];

/// Apple-TV-meets-Agentic rail: collapsed to icons, expands with labels and telemetry.
class SideNav extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const SideNav({super.key, required this.selected, required this.onSelect});

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> {
  bool _focused = false;
  bool _hovered = false;

  bool get _expanded => _focused || _hovered;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: FocusTraversalGroup(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: _expanded ? 248 : 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surface.withOpacity(_expanded ? 0.98 : 0.85),
                  AppColors.bg.withOpacity(_expanded ? 0.96 : 0.70),
                ],
              ),
              border: const Border(right: BorderSide(color: AppColors.stroke)),
              boxShadow: _expanded
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 36,
                        offset: const Offset(12, 0),
                      ),
                    ]
                  : null,
            ),
            child: ClipRect(
              child: SafeArea(
                right: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Brand(expanded: _expanded),
                                const SizedBox(height: 24),
                                const Spacer(),
                                for (var i = 0; i < navItems.length; i++) ...[
                                  _NavButton(
                                    item: navItems[i],
                                    selected: widget.selected == i,
                                    expanded: _expanded,
                                    onTap: () => widget.onSelect(i),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                const Spacer(),
                                const SizedBox(height: 12),
                                _StatusFooter(expanded: _expanded),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool expanded;
  const _Brand({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OverflowBox(
        minWidth: 0,
        maxWidth: 240,
        alignment: Alignment.centerLeft,
        child: PulseTvBrandLogo(size: 44, withText: expanded),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      onSelect: onTap,
      focusScale: 1.02,
      glow: false,
      radius: BorderRadius.circular(16),
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.35),
                      AppColors.cyan.withOpacity(0.15),
                    ],
                  )
                : focused
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.04),
                        ],
                      )
                    : null,
            border: Border.all(
              color: focused
                  ? AppColors.cyan
                  : selected
                      ? AppColors.accent.withOpacity(0.5)
                      : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: SizedBox(
            height: 50,
            child: OverflowBox(
              minWidth: 0,
              maxWidth: 210,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active indicator bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    height: selected ? 22 : 0,
                    decoration: BoxDecoration(
                      gradient: selected ? cyberGradient : null,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.cyan.withOpacity(0.8),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  SizedBox(width: selected ? 8 : 4),
                  Icon(
                    item.icon,
                    size: 24,
                    color: focused
                        ? Colors.white
                        : selected
                            ? AppColors.cyan
                            : AppColors.textDim,
                  ),
                  const SizedBox(width: 14),
                  AnimatedOpacity(
                    opacity: expanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.label,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: focused || selected ? Colors.white : AppColors.textDim,
                          ),
                        ),
                        if (item.badge.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.live.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.live.withOpacity(0.5)),
                            ),
                            child: Text(
                              item.badge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.live,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusFooter extends StatelessWidget {
  final bool expanded;
  const _StatusFooter({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OverflowBox(
        minWidth: 0,
        maxWidth: 220,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.stroke),
              ),
              child: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.cyan),
            ),
            const SizedBox(width: 12),
            AnimatedOpacity(
              opacity: expanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ULTRA LOW LATENCY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textDim,
                    ),
                  ),
                  Text(
                    'Zero-Jitter Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyan,
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

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../domain/models/user_role.dart';
import 'ar_viewer/ar_house_screen.dart';
import 'constructor/constructor_dashboard_screen.dart';
import 'customization/customize_house_screen.dart';
import 'floorplan/floorplan_2d_to_3d_screen.dart';
import 'homeowner/homeowner_dashboard_screen.dart';
import 'verification/reality_verification_screen.dart';

/// Main Architectural Shell with persistent bottom navigation dock.
/// Hosts Dashboard, 2D→3D Builder, 3D BIM Studio, AI Vision Lab, and AR Projector.
class MainNavigationShell extends StatefulWidget {
  final UserRole role;
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    required this.role,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.role == UserRole.homeowner
        ? const HomeownerDashboardScreen()
        : const ConstructorDashboardScreen();

    final screens = <Widget>[
      dashboard,
      const Floorplan2DTo3DScreen(),
      const CustomizeHouseScreen(),
      const RealityVerificationScreen(),
      const ARHouseScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.architecture_outlined, Icons.architecture_rounded, '2D→3D'),
                _buildNavItem(2, Icons.view_in_ar_outlined, Icons.view_in_ar_rounded, '3D Studio'),
                _buildNavItem(3, Icons.document_scanner_outlined, Icons.document_scanner_rounded, 'AI Vision'),
                _buildNavItem(4, Icons.layers_outlined, Icons.layers_rounded, 'AR Projector'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

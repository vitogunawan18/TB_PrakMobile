import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
import '../theme/app_theme.dart';
import '../routes.dart';
import 'event_list_page.dart';
import 'orders_page.dart';
import 'tickets_page.dart';
import 'profile_page.dart';

class MainNav extends StatefulWidget {
  final ApiService apiService;
  final AuthManager? authManager;
  final int initialIndex;

  const MainNav({
    super.key,
    required this.apiService,
    this.authManager,
    this.initialIndex = 0,
  });

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  late int _index;
  late final List<Widget> _pages;

  final GlobalKey<OrdersPageState> _ordersKey = GlobalKey<OrdersPageState>();
  final GlobalKey<TicketsPageState> _ticketsKey = GlobalKey<TicketsPageState>();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pages = [
      EventListPage(apiService: widget.apiService, authManager: widget.authManager),
      OrdersPage(key: _ordersKey, apiService: widget.apiService),
      TicketsPage(key: _ticketsKey, apiService: widget.apiService),
      ProfilePage(apiService: widget.apiService, authManager: widget.authManager),
    ];
  }

  Widget _buildNavIcon(IconData activeIcon, IconData inactiveIcon, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary.withOpacity(0.6),
          size: 22,
        ),
        if (isSelected) ...[
          const SizedBox(height: 3),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.accentPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ] else ...[
          const SizedBox(height: 7), // Maintain same height to avoid layout shift
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardSurface.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: AppTheme.accentSecondary.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.accentPrimary,
              unselectedItemColor: AppTheme.textSecondary.withOpacity(0.6),
              showSelectedLabels: false, // Hidden because of custom dot indicator
              showUnselectedLabels: false,
              currentIndex: _index,
              onTap: (i) {
                if (i == _index) return;
                switch (i) {
                  case 0:
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                    break;
                  case 1:
                    Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
                    break;
                  case 2:
                    Navigator.of(context).pushReplacementNamed(AppRoutes.tickets);
                    break;
                  case 3:
                    Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
                    break;
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home, Icons.home_outlined, _index == 0),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.list_alt, Icons.list_alt_outlined, _index == 1),
                  label: 'Orders',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.confirmation_num, Icons.confirmation_num_outlined, _index == 2),
                  label: 'Tickets',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person, Icons.person_outline, _index == 3),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

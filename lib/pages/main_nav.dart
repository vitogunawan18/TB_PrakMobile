import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        showUnselectedLabels: true,
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 1) {
            _ordersKey.currentState?.refresh();
          } else if (i == 2) {
            _ticketsKey.currentState?.refresh();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

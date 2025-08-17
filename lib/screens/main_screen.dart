import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce/screens/home_screen.dart';
import 'package:ecommerce/screens/categories_screen.dart';
import 'package:ecommerce/screens/cart_screen.dart';
import 'package:ecommerce/screens/profile_screen.dart';
import 'package:ecommerce/screens/chat_list_screen.dart';
import 'package:ecommerce/screens/driver_main_screen.dart';
import 'package:ecommerce/services/data_service.dart';
import 'package:ecommerce/services/auth_service.dart';
import 'package:ecommerce/models/user_role.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _loadUserData();
  }

  void _initializePages() {
    _pages = [
      const HomeScreen(),
      const CategoriesScreen(),
      const ChatListScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _loadUserData() async {
    final dataService = context.read<DataService>();
    final authService = context.read<AuthService>();
    
    if (authService.isAuthenticated) {
      // Charger les données utilisateur
      await dataService.loadCartItems();
      await dataService.loadWishlist();
      await dataService.loadOrders();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataService = context.watch<DataService>();
    final authService = context.watch<AuthService>();
    
    // Vérifier le rôle de l'utilisateur
    if (UserRoleManager.isDriver) {
      // Rediriger vers l'interface livreur
      return const DriverMainScreen();
    }
    
    // Interface client normale
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: theme.colorScheme.primaryContainer,
          surfaceTintColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              selectedIcon: Icon(
                Icons.home,
                color: theme.colorScheme.primary,
              ),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              selectedIcon: Icon(
                Icons.grid_view,
                color: theme.colorScheme.primary,
              ),
              label: 'Catégories',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              selectedIcon: Icon(
                Icons.chat_bubble,
                color: theme.colorScheme.primary,
              ),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Stack(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  if (dataService.cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${dataService.cartItemCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: Stack(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: theme.colorScheme.primary,
                  ),
                  if (dataService.cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${dataService.cartItemCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Panier',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              selectedIcon: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
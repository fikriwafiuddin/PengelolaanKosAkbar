import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'billing/invoices_screen.dart';
import 'chat/chat_rooms_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

/// Kerangka utama dengan bottom navigation sesuai desain:
/// Beranda, Tagihan, Chat, Profil (seluruh sprint 1-3 aktif).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const InvoicesScreen(),
      const ChatRoomsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.terracotta),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.terracotta),
            label: 'Tagihan',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat_rounded, color: AppColors.terracotta),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.terracotta),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'coming_soon_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';

/// Kerangka utama dengan bottom navigation sesuai desain:
/// Beranda, Tagihan (Sprint 2), Chat (Sprint 3), Profil.
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
      const ComingSoonScreen(
        title: 'Tagihan',
        description: 'Rincian tagihan, pembayaran sewa, dan kuitansi akan tersedia pada Sprint 2.',
        icon: Icons.receipt_long_outlined,
      ),
      const ComingSoonScreen(
        title: 'Chat',
        description: 'Pesan grup dan pengumuman resmi akan tersedia pada Sprint 3.',
        icon: Icons.chat_outlined,
      ),
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

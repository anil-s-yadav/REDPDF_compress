import 'dart:io';
import 'dart:developer';

import 'package:compress_pdf_redpdf/screens/allfiles_screen.dart';
import 'package:compress_pdf_redpdf/screens/homescreen.dart';
import 'package:compress_pdf_redpdf/screens/profilescreen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      log('InAppUpdate error: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const FilesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appColors = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;

    return Scaffold(
      backgroundColor: appColors.bg,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? appColors.card : appColors.bg,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(12),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: isDark ? appColors.card : appColors.bg,
          elevation: 0,
          selectedItemColor: appColors.primary,
          unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_rounded),
              label: 'Files',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

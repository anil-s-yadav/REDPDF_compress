import 'package:compress_pdf_redpdf/screens/allfiles_screen.dart';
import 'package:compress_pdf_redpdf/screens/homescreen.dart';
import 'package:compress_pdf_redpdf/screens/profilescreen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  // bool _isCheckingPermission = false;

  // @override
  // void initState() {
  //   super.initState();
  //   WidgetsBinding.instance.addObserver(this);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _checkPermissions();
  //   });
  // }

  // @override
  // void dispose() {
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     _checkPermissions();
  //   }
  // }

  // Future<void> _checkPermissions() async {
  //   if (_isCheckingPermission) return;
  //   _isCheckingPermission = true;

  //   try {
  //     if (Platform.isAndroid) {
  //       bool manageGranted = await Permission.manageExternalStorage.isGranted;
  //       bool storageGranted = await Permission.storage.isGranted;

  //       if (!manageGranted && !storageGranted) {
  //         // This shows an in-app popup on Android 10 and below
  //         await Permission.storage.request();

  //         // This explicitly redirects to the 'All files access' page on Android 11+
  //         await Permission.manageExternalStorage.request();
  //       }

  //       if (await Permission.manageExternalStorage.isGranted ||
  //           await Permission.storage.isGranted) {
  //         if (mounted) {
  //           context.read<PdfProvider>().scanAllPdfs();
  //         }
  //       }
  //     }
  //   } finally {
  //     Future.delayed(const Duration(seconds: 1), () {
  //       if (mounted) {
  //         _isCheckingPermission = false;
  //       }
  //     });
  //   }
  // }

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
    final theme = Theme.of(context).colorScheme;
    final appColors = AppThemeColors.pdfLight;

    return Scaffold(
      backgroundColor: appColors.primary,
      body: _pages[_selectedIndex],
      // floatingActionButton: _selectedIndex == 0
      //     ? FloatingActionButton.extended(
      //         onPressed: () => Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (_) => const ImageToPdfScreen()),
      //         ),
      //         backgroundColor: appColors.primary,
      //         elevation: 4,
      //         // shape: const CircleBorder(),
      //         isExtended: true,
      //         label: Row(
      //           children: [
      //             const Icon(Icons.add, color: Colors.white, size: 32),
      //             Text("IMG to Pdf", style: TextStyle(color: Colors.white)),
      //           ],
      //         ),
      //       )
      //     : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.surface,
        elevation: 10,
        selectedItemColor: appColors.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "PROFILE"),
        ],
      ),
    );
  }
}

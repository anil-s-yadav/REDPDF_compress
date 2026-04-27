import 'package:compress_pdf_redpdf/providers/pdf_provider.dart';
import 'package:compress_pdf_redpdf/screens/allfiles_screen.dart';
import 'package:compress_pdf_redpdf/screens/homescreen.dart';
import 'package:compress_pdf_redpdf/screens/image_com_screen.dart';
import 'package:compress_pdf_redpdf/screens/navigation.dart';
import 'package:compress_pdf_redpdf/screens/pdf_com_screen.dart';
import 'package:compress_pdf_redpdf/screens/profilescreen.dart';
import 'package:compress_pdf_redpdf/screens/success_screen.dart';
import 'package:compress_pdf_redpdf/theme/app_theme.dart';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/history_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaStore.ensureInitialized();
  MediaStore.appFolder = "RedPDF";

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        // ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        // ChangeNotifierProvider(create: (_) => PermissionProvider()),
        // if (!kIsWeb)
        //   ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PDF Master',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const NavigationPage(),
            '/home': (context) => const HomeScreen(),
            '/allfiles': (context) => const FilesScreen(),
            // '/select-pdf': (context) => const SelectPdfScreen(),
            // '/success': (context) => const SuccessScreen(),
            '/compressimage': (context) => const CompressImageScreen(),
            '/compresspdf': (context) => const CompressPdfScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/success': (context) => const SuccessScreen(),
            // '/upgrade': (context) => const UpgradeScreen(),
            // '/split-pdf': (context) => const SplitPdfScreen(),
            // '/viewer': (context) =>
            //     const PdfViewerScreen(path: 'sample.pdf', title: 'PDF Viewer'),
          },
        );
      },
    );
  }
}

import 'package:compress_pdf_redpdf/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:sign_pdf_redpdf/theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppThemeColors.pdfDark : AppThemeColors.pdfLight;

    return Scaffold(
      backgroundColor: color.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "A product by: ",
              style: TextStyle(
                color: Colors.grey,
                // fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Icon(Icons.picture_as_pdf, color: color.primary),
            const SizedBox(width: 8),
            Text(
              "RedPDF",
              style: TextStyle(
                color: color.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _launchUrl(
                "https://play.google.com/store/apps/details?id=com.legendarysoftware.compress_pdf_redpdf",
              ),
              icon: Icon(Icons.star_border, color: Colors.orange),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER
            /*   const SizedBox(height: 10),
        /// PROFILE
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person, size: 40),
        ),
      
        const SizedBox(height: 12),
      
        Text(
          "Alex Sterling",
          style: TextStyle(
            color: color.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      
        const SizedBox(height: 4),
      
        Text(
          "alex.sterling@redpdf.pro",
          style: TextStyle(color: color.text),
        ),
      
        const SizedBox(height: 20),
      
        /// UPGRADE BUTTON
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Colors.deepOrange, Colors.orange, Colors.amber],
            ),
          ),
          child: const Center(
            child: Text(
              "🚀 Upgrade to Premium",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        */
            _sectionTitle("SETTINGS"),

            _card(
              color.card,
              child: Column(
                children: [
                  SwitchListTile(
                    // thumbColor: WidgetStatePropertyAll(color.primary),
                    activeThumbColor: color.primary,

                    // trackOutlineColor: WidgetStatePropertyAll(color.primary),
                    value: context.watch<ThemeProvider>().isDarkMode,
                    onChanged: (val) =>
                        context.read<ThemeProvider>().toggleDarkMode(val),
                    title: const Text("Dark Mode"),
                    secondary: Container(
                      height: 50,
                      width: 50,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.purple.withAlpha(30),
                      ),
                      child: const Icon(Icons.dark_mode, color: Colors.purple),
                    ),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          leading: Container(
                            height: 50,
                            width: 50,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.blue.withAlpha(30),
                            ),
                            child: const Icon(Icons.deblur, color: Colors.blue),
                          ),
                          title: const Text("Default Compression"),
                          trailing: DropdownButton<CompressionLevel>(
                            value: settings.defaultCompression,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: color.primary,
                            ),
                            style: TextStyle(
                              color: color.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                settings.setDefaultCompression(val);
                              }
                            },
                            items: CompressionLevel.values.map((v) {
                              return DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v.name.substring(0, 1).toUpperCase() +
                                      v.name.substring(1),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          onTap: () => _pickStoragePath(context, settings),
                          leading: Container(
                            height: 50,
                            width: 50,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.green.withAlpha(30),
                            ),
                            child: const Icon(
                              Icons.storage,
                              color: Colors.green,
                            ),
                          ),
                          title: const Text("Storage Location"),
                          subtitle: Text(
                            settings.storageLocation,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                  ),
                  // SwitchListTile(
                  //   value: true,
                  //   onChanged: (v) {},
                  //   title: const Text("Notifications"),
                  //   secondary: const Icon(Icons.notifications),
                  // ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 📄 LEGAL
            _sectionTitle("LEGAL"),

            _card(
              color.card,
              child: GestureDetector(
                onTap: () => _launchUrl(
                  "https://anil-s-yadav.github.io/REDPDF_compress_privacy_policy/",
                ),
                child: _tile(
                  "Privacy Policy",
                  null,
                  color,
                  Icons.privacy_tip_outlined,
                  Icons.arrow_forward_ios,
                  Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 15),

            /// 📄 SUPPORT
            _sectionTitle("SUPPORT US"),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "Rate Us",
                      subtitle: "Love the app?",
                      icon: Icons.star_rounded,
                      colors: [
                        Colors.amber.shade400,
                        Colors.deepOrange.shade400,
                      ],
                      onTap: () => _launchUrl(
                        "https://play.google.com/store/apps/details?id=com.legendarysoftware.compress_pdf_redpdf",
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      title: "More Apps",
                      subtitle: "Try our tools",
                      icon: Icons.dashboard_rounded,
                      colors: [
                        Colors.lightBlue.shade400,
                        Colors.indigo.shade500,
                      ],
                      onTap: () => _launchUrl(
                        "https://play.google.com/store/search?q=pub%3ALegendary%20Software%20Solutions&c=apps",
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ///  SIGN OUT
            // Text(
            //   "Sign Out",
            //   style: TextStyle(
            //     color: color.primary,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            const SizedBox(height: 10),

            Text(
              "VERSION 1.1.11 (11) • A Product by - REDPDF",
              style: TextStyle(fontSize: 12, color: color.text),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Card Wrapper
  Widget _card(Color color, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _tile(
    String title,
    String? trailingText,
    AppColors color,
    IconData? icon1,
    IconData? icon2,
    Color iconColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Container(
          height: 50,
          width: 50,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: iconColor.withAlpha(30),
          ),
          child: Icon(icon1, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: trailingText != null
            ? Text(trailingText, style: TextStyle(color: color.primary))
            : Icon(icon2, size: 16),
      ),
    );
  }

  /// 🔹 Section Title
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 1,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _pickStoragePath(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      settings.setStorageLocation(path);
    }
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(60),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

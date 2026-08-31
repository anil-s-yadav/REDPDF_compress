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
        title: GestureDetector(
          onTap: () => _launchUrl(
            "https://play.google.com/store/apps/details?id=com.legendarysoftware.compress_pdf_redpdf",
          ),
          child: Row(
            children: [
              Text(
                "A product by:  ",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Image.asset(
                'lib/assets/google-play-store-icon.png',
                height: 20,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shop, size: 20, color: Colors.grey),
              ),
              // const SizedBox(width: 8),
              Text(
                " RedPDF",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
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
              child: Column(
                children: [
                  _buildActionTile(
                    title: "Rate Us",
                    subtitle: "Love the app? Leave a review!",
                    icon: Icons.star_rounded,
                    colors: [Colors.amber.shade400, Colors.deepOrange.shade400],
                    onTap: () => _launchUrl(
                      "https://play.google.com/store/apps/details?id=com.legendarysoftware.compress_pdf_redpdf",
                    ),
                  ),
                  _otherAppsTile(color),
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
              "VERSION 1.1.0 (13) • A Product by - REDPDF",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Card Wrapper
  Widget _card(Color color, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
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

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withAlpha(60),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(60),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otherAppsTile(AppColors color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: color.primary.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _launchUrl(
            'https://play.google.com/store/apps/dev?id=8832237281097064209',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    'lib/assets/google-play-store-icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "More Apps",
                              style: TextStyle(
                                color: color.text,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "RedPDF",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Google Play Store • More Tools",
                        style: TextStyle(
                          color: color.text.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: color.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/theme_provider.dart';

// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
//     final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
//     final text = isDark ? Colors.white : const Color(0xFF1E1E1E);
//     final subText = isDark ? Colors.white70 : Colors.black54;
//     final primary = const Color(0xFFE53935);

//     return Scaffold(
//       backgroundColor: bg,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               /// 🔴 HEADER
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 10,
//                 ),
//                 child: Row(
//                   children: [
//                     Text(
//                       "A product by: ",
//                       style: TextStyle(
//                         color: Colors.grey,
//                         // fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                     Icon(Icons.picture_as_pdf, color: primary),
//                     const SizedBox(width: 8),
//                     Text(
//                       "RedPDF",
//                       style: TextStyle(
//                         color: primary,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                     const Spacer(),
//                     Icon(Icons.star_border, color: Colors.orange),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 10),

//               /// 👤 PROFILE
//               CircleAvatar(
//                 radius: 45,
//                 backgroundColor: Colors.grey.shade300,
//                 child: const Icon(Icons.person, size: 40),
//               ),

//               const SizedBox(height: 12),

//               Text(
//                 "Alex Sterling",
//                 style: TextStyle(
//                   color: text,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 4),

//               Text(
//                 "alex.sterling@redpdf.pro",
//                 style: TextStyle(color: subText),
//               ),

//               const SizedBox(height: 20),

//               /// 🔴 UPGRADE BUTTON
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 20),
//                 height: 50,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(30),
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFFF4E50), Color(0xFFE53935)],
//                   ),
//                 ),
//                 child: const Center(
//                   child: Text(
//                     "🚀 Upgrade to Premium",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 25),

//               /// 🟡 STORAGE CARD
//               _card(
//                 card,
//                 child: ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.amber.shade200,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(Icons.workspace_premium),
//                   ),
//                   title: const Text("Pro Storage"),
//                   subtitle: const Text("25.4 GB of 100 GB used"),
//                   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               /// ⚙️ SETTINGS
//               _sectionTitle("SETTINGS"),

//               _card(
//                 card,
//                 child: Column(
//                   children: [
//                     SwitchListTile(
//                       value: context.watch<ThemeProvider>().isDarkMode,
//                       onChanged: (val) =>
//                           context.read<ThemeProvider>().toggleDarkMode(val),
//                       title: const Text("Dark Mode"),
//                       secondary: const Icon(Icons.dark_mode),
//                     ),
//                     _tile("Default Compression", "Balanced"),
//                     _tile("Storage Location", null),
//                     SwitchListTile(
//                       value: true,
//                       onChanged: (v) {},
//                       title: const Text("Notifications"),
//                       secondary: const Icon(Icons.notifications),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               /// 📄 SUPPORT
//               _sectionTitle("SUPPORT & LEGAL"),

//               _card(
//                 card,
//                 child: Column(
//                   children: [
//                     _tile("Rate Us", null),
//                     _tile("Our Other Apps", null),
//                     _tile("Privacy Policy", null),
//                     _tile("Terms & Conditions", null),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               /// 🚪 SIGN OUT
//               Text(
//                 "Sign Out",
//                 style: TextStyle(color: primary, fontWeight: FontWeight.bold),
//               ),

//               const SizedBox(height: 10),

//               Text(
//                 "VERSION 4.2.0 (882) • REDPDF PREMIUM",
//                 style: TextStyle(fontSize: 12, color: subText),
//               ),

//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// 🔹 Card Wrapper
//   Widget _card(Color color, {required Widget child}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: child,
//     );
//   }

//   /// 🔹 Section Title
//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 12,
//             letterSpacing: 1,
//             color: Colors.grey,
//           ),
//         ),
//       ),
//     );
//   }

//   /// 🔹 List Tile
//   Widget _tile(String title, String? trailingText) {
//     return ListTile(
//       title: Text(title),
//       trailing: trailingText != null
//           ? Text(trailingText, style: const TextStyle(color: Colors.red))
//           : const Icon(Icons.arrow_forward_ios, size: 16),
//     );
//   }
// }

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
                        color: color.primary.withAlpha(30),
                      ),
                      child: Icon(Icons.dark_mode, color: color.primary),
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
                              color: color.primary.withAlpha(30),
                            ),
                            child: Icon(Icons.deblur, color: color.primary),
                          ),
                          title: const Text("Default Pdf Compression"),
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
                              color: color.primary.withAlpha(30),
                            ),
                            child: Icon(Icons.storage, color: color.primary),
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

            /// 📄 SUPPORT
            _sectionTitle("SUPPORT & LEGAL"),

            _card(
              color.card,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _launchUrl(
                      "https://play.google.com/store/apps/details?id=com.legendarysoftware.compress_pdf_redpdf",
                    ),
                    child: _tile(
                      "Rate Us",
                      null,
                      color,
                      Icons.star,
                      Icons.open_in_new,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _launchUrl(
                      "https://play.google.com/store/apps/details?id=com.legendarysoftware.compress_pdf_redpdf",
                    ),
                    child: _tile(
                      "Our Other Apps",
                      null,
                      color,
                      Icons.apps,
                      Icons.open_in_new,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _launchUrl(
                      "https://anil-s-yadav.github.io/REDPDF-PrivacyPolicy/",
                    ),
                    child: _tile(
                      "Privacy Policy",
                      null,
                      color,
                      Icons.privacy_tip_outlined,
                      Icons.arrow_forward_ios,
                    ),
                  ),
                  //   _tile(
                  //     "Terms & Conditions",
                  //     null,
                  //     color,
                  //     Icons.gavel_outlined,
                  //     Icons.arrow_forward_ios,
                  //   ),
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
              "VERSION 2.0.0 (2) • A Product by - REDPDF",
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Container(
          height: 50,
          width: 50,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.primary.withAlpha(30),
          ),
          child: Icon(icon1, color: color.primary),
        ),
        title: Text(title),
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
}

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SLF4J
-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }

# Media Store Plus
-keep class com.snnafi.media_store_plus.** { *; }

# Play Core rules
-dontwarn com.google.android.play.core.**

# iText
-keep class com.itextpdf.** { *; }
-keep class org.bouncycastle.** { *; }

# Apache Xerces (required by iText7 for XML parsing)
-keep class org.apache.** { *; }
-dontwarn org.apache.**

# iText7 additional dependencies
-keep class javax.xml.** { *; }
-dontwarn javax.xml.**
-keep class org.w3c.** { *; }
-dontwarn org.w3c.**
-keep class org.xml.** { *; }
-dontwarn org.xml.**

# Jackson JSON (optional dependency for iText7)
-dontwarn com.fasterxml.jackson.**

# BouncyCastle LDAP/JNDI dependencies
-dontwarn javax.naming.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

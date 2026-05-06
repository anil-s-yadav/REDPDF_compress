import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() async {
  // create a PDF
  final PdfDocument document = PdfDocument();
  document.pages.add();
  
  // set password
  final PdfSecurity security = document.security;
  security.userPassword = 'password123';
  security.ownerPassword = 'password123';
  security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
  
  File('test_enc.pdf').writeAsBytesSync(await document.save());
  document.dispose();
  
  // now try to open
  try {
    final doc2 = PdfDocument(inputBytes: File('test_enc.pdf').readAsBytesSync());
    print('Opened without password!');
  } catch (e) {
    print('Error opening without password: ${e.runtimeType} $e');
  }

  // now open with password and save again to see if encryption is removed
  final doc3 = PdfDocument(inputBytes: File('test_enc.pdf').readAsBytesSync(), password: 'password123');
  File('test_unenc.pdf').writeAsBytesSync(await doc3.save());
  doc3.dispose();

  // Try opening the re-saved file
  try {
    final doc4 = PdfDocument(inputBytes: File('test_unenc.pdf').readAsBytesSync());
    print('Successfully opened re-saved file without password! Encryption was removed by default.');
  } catch (e) {
    print('Re-saved file still requires password.');
  }
}

// import 'dart:io';
// import 'package:syncfusion_flutter_pdf/pdf.dart';

// void main() async {
//   // Try clearing security directly?
//   // Let's create an encrypted PDF first
//   final PdfDocument document = PdfDocument();
//   document.pages.add();
//   document.security.userPassword = '123';
//   document.security.ownerPassword = '123';
//   File('test_enc.pdf').writeAsBytesSync(await document.save());
//   document.dispose();
  
//   // Read it back
//   final doc2 = PdfDocument(inputBytes: File('test_enc.pdf').readAsBytesSync(), password: '123');
//   // How to remove encryption?
//   // In C#, it's document.Security.Remove(); but in Dart?
//   // Let's check available methods on security
//   // doc2.security.userPassword = ''; // ?
//   // Let's try drawing template
  
//   final unencryptedDoc = PdfDocument();
//   for(int i = 0; i < doc2.pages.count; i++) {
//     final page = doc2.pages[i];
//     final newPage = unencryptedDoc.pages.add();
//     newPage.graphics.drawPdfTemplate(page.createTemplate(), const Offset(0, 0));
//   }
  
//   File('test_unenc.pdf').writeAsBytesSync(await unencryptedDoc.save());
//   unencryptedDoc.dispose();
//   doc2.dispose();
  
//   // Verify
//   try {
//     final doc3 = PdfDocument(inputBytes: File('test_unenc.pdf').readAsBytesSync());
//     print('SUCCESS! Unencrypted via template.');
//     doc3.dispose();
//   } catch(e) {
//     print('FAILED! $e');
//   }
// }

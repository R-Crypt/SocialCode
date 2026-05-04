import 'dart:html' as html;
import 'dart:convert';

void downloadCsv(String filename, String csvText) {
  // Convert CSV text to bytes and create a Blob
  final bytes = utf8.encode(csvText);
  final blob = html.Blob([bytes], 'text/csv');
  
  // Create an object URL from the Blob
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create an anchor element, trigger download, and cleanup
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}

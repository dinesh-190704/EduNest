import 'dart:html' as html;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

dynamic createFile(String path) => throw UnsupportedError('File operations not supported on web');
dynamic createDirectory(String path) => throw UnsupportedError('Directory operations not supported on web');

Future<String> uploadFileToStorage(Reference ref, dynamic file) async {
  if (file is List<int>) {
    await ref.putData(Uint8List.fromList(file));
  } else {
    await ref.putBlob(file);
  }
  return ref.getDownloadURL();
}

Future<void> downloadFileFromUrl(String url, String fileName) async {
  final anchorElement = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchorElement);
  anchorElement.click();
  html.document.body?.children.remove(anchorElement);
}

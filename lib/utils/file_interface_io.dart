import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

File createFile(String path) => File(path);
Directory createDirectory(String path) => Directory(path);

Future<String> uploadFileToStorage(Reference ref, dynamic file) async {
  await ref.putFile(file as File);
  return ref.getDownloadURL();
}

Future<void> downloadFileFromUrl(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  final bytes = response.bodyBytes;
  final downloadDir = createDirectory('/storage/emulated/0/Download');
  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }
  final file = createFile('${downloadDir.path}/$fileName');
  await file.writeAsBytes(bytes);
}

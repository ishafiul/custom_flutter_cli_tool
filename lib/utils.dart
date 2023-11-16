import 'dart:io';

import 'package:yaml/yaml.dart';

Future<String> getPubspecContents() async {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    throw StateError('pubspec.yaml does not exist');
  }
  return file.readAsString();
}

Future<String> getAppName() async {
  final pubspecContents = await getPubspecContents();
  final yaml = loadYaml(pubspecContents) as Map;
  final name = yaml['name'];
  if (name is! String) {
    throw StateError('Invalid name property in pubspec.yaml');
  }
  return name;
}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}


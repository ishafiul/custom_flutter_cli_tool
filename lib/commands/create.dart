import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ishaf_cli/utils.dart';

class CreateCommand extends Command {
  static const _gitUrl = 'git-url';
  static const _nameTemplate = 'starter_kit_flutter';

  CreateCommand() {
    const starterGitUrl =
        'https://github.com/ishafiul/starter_kit_flutter.git';
    argParser.addOption(
      _gitUrl,
      abbr: 'g',
      help: 'Git URL to clone from',
      defaultsTo: starterGitUrl,
    );
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new project';

  @override
  FutureOr? run() {
    if (argResults!.rest.isEmpty) {
      print('Please specify a project name');
      return null;
    }

    final name = argResults!.rest.first;
    final gitUrl = argResults![_gitUrl] as String;
    _validateUrl(gitUrl);

    final dir = Directory(name);
    if (dir.existsSync()) {
      print('Directory $name already exists');
      exit(1);
    }

    print('Creating $name from $gitUrl');
    _cloneAndSetup(gitUrl, name);
  }

  void _cloneAndSetup(String gitUrl, String name) {
    final result = Process.runSync(
      'git',
      ['clone', gitUrl, name],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      print(result.stderr);
      return;
    }

    _setup(name);

    print('Running pub get...');
    Process.runSync(
      'dart',
      ['pub', 'get'],
      workingDirectory: name,
    );

    print('All done!');
    print('Running pub get...');
  }

  void _setup(String name) {
    /// pubspec
    final pubspec = File('$name/pubspec.yaml');
    final linesYaml = pubspec.readAsLinesSync();
    final newLinesYaml = <String>[];
    for (final line in linesYaml) {
      if (line.contains('name:')) {
        newLinesYaml.add(line.replaceFirst(_nameTemplate, name));
        newLinesYaml.add(
          line.replaceFirst(
            _nameTemplate,
            name
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) => word.capitalize())
                .join(' '),
          ),
        );
      } else {
        newLinesYaml.add(line);
      }
    }
    pubspec.writeAsStringSync(newLinesYaml.join('\n'));

    /// readme
    final readme = File('$name/README.md');
    final readmeLines = readme.readAsLinesSync();
    final newLinesReadme = <String>[];
    for (final line in readmeLines) {
      if (line.contains('# $_nameTemplate')) {
        newLinesReadme.add(line.replaceFirst(_nameTemplate, name));
      } else {
        newLinesReadme.add(line);
      }
    }
    readme.writeAsStringSync(newLinesReadme.join('\n'));

    /// app/gradle
    final gradle = File('$name/android/app/build.gradle');
    final gradleLines = gradle.readAsLinesSync();
    final newLinesGradle = <String>[];
    for (final line in gradleLines) {
      if (line.contains('appName:')) {
        newLinesGradle.add(
          line.replaceFirst(
            _nameTemplate,
            name
                .replaceAll('_', ' ')
                .split(' ')
                .map((word) => word.capitalize())
                .join(' '),
          ),
        );
      } else {
        newLinesGradle.add(line);
      }
    }
    gradle.writeAsStringSync(newLinesGradle.join('\n'));

    ///git
    final gitDir = Directory('$name/.git');
    gitDir.deleteSync(recursive: true);


    ///
    final libDir = Directory('$name/lib');
    final dartFiles =
        findFilesInDir(libDir).where((f) => f.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      final newLines = <String>[];
      for (final line in lines) {
        if (line.startsWith('import') && line.contains(_nameTemplate)) {
          newLines.add(line.replaceFirst(_nameTemplate, name));
        } else {
          newLines.add(line);
        }
      }
      file.writeAsStringSync(newLines.join('\n'));
    }


    ///
    final test = Directory('$name/test');
    final testDirDartFiles =
    findFilesInDir(test).where((f) => f.path.endsWith('.dart'));
    for (final file in testDirDartFiles) {
      final lines = file.readAsLinesSync();
      final newLines = <String>[];
      for (final line in lines) {
        if (line.startsWith('import') && line.contains(_nameTemplate)) {
          newLines.add(line.replaceFirst(_nameTemplate, name));
        } else {
          newLines.add(line);
        }
      }
      file.writeAsStringSync(newLines.join('\n'));
    }

    Process.runSync('dart', ['fix', '--apply'], workingDirectory: name);
    Process.runSync('dart', ['format', 'bin'], workingDirectory: name);
    Process.runSync('dart', ['format', 'lib'], workingDirectory: name);
  }

  List<File> findFilesInDir(Directory dir) {
    final files = <File>[];
    for (final entity in dir.listSync()) {
      if (entity is File) {
        files.add(entity);
      } else if (entity is Directory) {
        files.addAll(findFilesInDir(entity));
      }
    }
    return files;
  }

  void _validateUrl(String url) {
    if (!url.startsWith('https://')) {
      throw UsageException(
        'Git URL must start with https://',
        _gitUrl,
      );
    }
  }
}

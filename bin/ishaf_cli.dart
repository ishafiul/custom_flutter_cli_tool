import 'package:args/command_runner.dart';
import 'package:ishaf_cli/commands/create.dart';

Future<void> main(List<String> args) async {
  final runner = CommandRunner('ishaf', 'Official ishaf CLI xD')
    ..addCommand(CreateCommand());

  await runner.run(args);
}

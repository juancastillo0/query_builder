import 'dart:async';
import 'package:glob/glob.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:query_builder/database/models/parsers/create_table_parser.dart';
import 'package:query_builder/database/models/parsers/table_models.dart';

class TablesGenerator implements Builder {
  final BuilderOptions options;

  TablesGenerator(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'lib/$lib$': ['lib/all_tables.sql.dart']
    };
  }

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'all_tables.sql.dart'),
    );
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final allFiles = <AssetId, List<SqlTable>>{};

    await for (final input in buildStep.findAssets(Glob('lib/**.sql'))) {
      final text = await buildStep.readAsString(input);
      final parseResult = createTableListParser.parse(text);

      if (parseResult.isFailure) {
        print(parseResult);
        continue;
      }
      allFiles[input] = parseResult.value;
    }

    final allTables = allFiles.values.expand((e) => e).toList();
    // for (final entry in allFiles.entries) {
    try {
      String out = '''
import 'package:query_builder/query_builder.dart';

${allTables.first.templates.dartClass(allTables)}
''';
      try {
        out = DartFormatter().format(out);
      } catch (_) {}
      await buildStep.writeAsString(_allFileOutput(buildStep), out);
    } catch (e, s) {
      print('$e $s');
    }
    // }
  }
}

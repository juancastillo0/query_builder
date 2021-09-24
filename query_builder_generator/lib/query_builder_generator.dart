/// Support for doing something awesome.
///
/// More dartdocs go here.
library query_builder_generator;

import 'package:build/build.dart';

import 'src/tables_generator.dart';

export 'src/query_builder_generator_base.dart';

Builder tablesGenerator(BuilderOptions options) => TablesGenerator(options);


import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'fy_generator.dart';

Builder testBuilder(BuilderOptions options) =>
    LibraryBuilder(TestGenerator());


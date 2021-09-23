import 'package:petitparser/petitparser.dart';

Parser<T> enumParser<T>(List<T> enumValues, {String? optionalPrefix}) {
  return enumValues.fold<Parser<T>?>(null, (Parser<T>? value, T element) {
    Parser<T> curr =
        string(element.toString().split('.')[1]).map((value) => element);
    if (optionalPrefix != null) {
      curr = (string('$optionalPrefix.').optional() & curr).pick(1).cast();
    }
    if (value == null) {
      value = curr;
    } else {
      value = value.or(curr).cast();
    }
    return value;
  })!;
}

Parser<String> stringsParser(Iterable<String> enumValues) {
  return enumValues.fold<Parser<String>?>(null, (value, element) {
    final curr = string(element);
    if (value == null) {
      value = curr;
    } else {
      value = value.or(curr).cast<String>();
    }
    return value;
  })!;
}

Parser<List<T>> separatedParser<T>(
  Parser<T> parser, {
  Parser? left,
  Parser? right,
  Parser? separator,
}) {
  return ((left ?? char('[')).trim() &
          parser
              .separatedBy<T>(
                (separator ?? char(',')).trim(),
                includeSeparators: false,
                optionalSeparatorAtEnd: true,
              )
              .optional() &
          (right ?? char(']')).trim())
      .pick(1)
      .map((Object? value) => List.castFrom<Object?, T>(value as List? ?? []));
}

Parser<MapEntry<String, T>> structParamsParser<T>(
    Map<String, Parser<T>> params) {
  final parser = params.entries.fold<Parser<MapEntry<String, T>>?>(null,
      (previousValue, element) {
    final curr =
        (string(element.key).trim() & char(':').trim() & element.value.trim())
            .map((value) => MapEntry(value[0] as String, value[2] as T));
    if (previousValue == null) {
      previousValue = curr;
    } else {
      previousValue = previousValue.or(curr).cast<MapEntry<String, T>>();
    }
    return previousValue;
  })!;
  return parser;
}

Parser<String> orManyString(Iterable<String> params) {
  return orMany<String, String>(params, (s) => string(s));
}

Parser<T> orMany<T, V>(Iterable<V> params, Parser<T> Function(V) parserFn) {
  final parser = params.fold<Parser<T>?>(null, (previousValue, element) {
    final curr = parserFn(element);
    if (previousValue == null) {
      previousValue = curr;
    } else {
      previousValue = previousValue.or(curr).cast<T>();
    }
    return previousValue;
  })!;
  return parser;
}

final boolParser =
    (string('true') | string('false')).map((Object? value) => value == 'true');

final _num = char('0').or(pattern('1-9') & digit().star());
final unsignedIntParser = _num.flatten().map((value) => int.parse(value));
final intParser =
    (char('-').optional() & _num).flatten().map((value) => int.parse(value));
final unsignedDoubleParser = (_num & char('.').seq(_num).optional())
    .flatten()
    .map((value) => double.parse(value));
final doubleParser =
    (char('-').optional() & _num & char('.').seq(_num).optional())
        .flatten()
        .map((value) => double.parse(value));

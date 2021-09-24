import 'sql_values.dart';

class SqlSelect {
  final String tableName;
  List<String>? _selects;
  SqlValue<SqlBoolValue>? _where;
  List<SqlOrderItem>? _orderBy;
  SqlLimit? _limit;
  List<String>? _groupBy;
  List<SqlJoin>? _join;

  SqlSelect(
    this.tableName, {
    List<String>? selects,
    SqlValue<SqlBoolValue>? where,
    List<SqlOrderItem>? orderBy,
    SqlLimit? limit,
    List<String>? groupBy,
    List<SqlJoin>? join,
  })  : _selects = selects,
        _where = where,
        _orderBy = orderBy,
        _limit = limit,
        _groupBy = groupBy,
        _join = join;

  SqlSelect selects(List<String> selects) {
    _selects = selects;
    return this;
  }

  SqlSelect join(SqlJoin join) {
    _join ??= [];
    _join!.add(join);
    return this;
  }

  SqlSelect where(SqlValue<SqlBoolValue> where) {
    _where = where;
    return this;
  }

  SqlSelect limit(int rowCount, {int? offset}) {
    _limit = SqlLimit(rowCount, offset: offset);
    return this;
  }

  SqlSelect groupBy(List<String> groupBy) {
    _groupBy = groupBy;
    return this;
  }

  SqlSelect orderBy(List<SqlOrderItem> orderBy) {
    _orderBy = orderBy;
    return this;
  }

  SqlQuery build(SqlDatabase database) {
    final ctx = SqlContext(database: database, unsafe: false);
    final query = """
SELECT ${_selects?.join(',') ?? '*'}
FROM $tableName
${_join == null ? '' : _join!.map((e) => e.toSql(ctx)).join('\n')}
${_where == null ? '' : 'WHERE ${_where!.toSql(ctx)}'}
${_groupBy == null ? '' : 'GROUP BY ${_groupBy!.join(',')}'}
${_orderBy == null ? '' : 'ORDER BY ${_orderBy!.map((item) => item.toSql(ctx)).join(",")}'}
${_limit == null ? '' : 'LIMIT ${_limit!.rowCount} ${_limit!.offset == null ? "" : "OFFSET ${_limit!.offset}"}'}
;""";
    return SqlQuery(query, ctx.variables);
  }
}

class SqlInsert {
  final String tableName;

  List<Map<String, SqlValue>>? _values;
  SqlSelect? _select;

  SqlInsert(this.tableName);

  SqlInsert values(List<Map<String, SqlValue>> values) {
    _values = values;
    return this;
  }

  SqlInsert select(SqlSelect select) {
    _select = select;
    return this;
  }

  // TODO:
  // ABORT
  // FAIL
  // IGNORE
  // REPLACE
  // ROLLBACK

  SqlQuery build(SqlDatabase database) {
    final _values = this._values;
    if (_values != null) {
      final ctx = SqlContext(database: database, unsafe: false);
      final allNames = _values.fold<Iterable<String>>(
        <String>[],
        (previousValue, element) => previousValue.followedBy(element.keys),
      ).toSet();

      String _mapValue(Map<String, SqlValue> e) {
        return allNames
            .map(
              (n) => e.containsKey(n)
                  ? e[n]!.toSql(ctx)
                  : const SqlValue<SqlStringValue>.raw('DEFAULT'),
            )
            .join(',');
      }

      final query = """
INSERT INTO $tableName (${allNames.join(',')})
VALUES 
${_values.map(_mapValue).join(',\n')}
;""";
      return SqlQuery(query, ctx.variables);
    }

    final _select = this._select!.build(database);
    // TODO: column names
    final query = '''
INSERT INTO $tableName
${_select.query} 
;''';
    return SqlQuery(query, _select.params);
  }
}

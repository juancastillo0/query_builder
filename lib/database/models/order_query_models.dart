import 'package:query_builder/database/models/sql_values.dart';

class SqlOrderItem<V extends SqlValue<dynamic>> implements SqlGenerator {
  final V value;
  final bool desc;
  final bool nullsFirst;

  const SqlOrderItem(this.value, {this.desc = false, this.nullsFirst = false});

  @override
  String toSql(SqlContext ctx) {
    return '${nullsFirst && !desc ? "${value.toSql(ctx)} IS NOT NULL," : ""}${value.toSql(ctx)} ${desc ? "DESC" : "ASC"}';
  }
}

class SqlJoin implements SqlGenerator {
  final String table;
  final String? alias;
  final SqlValue<SqlBoolValue>? condition;
  final bool isInner;

  const SqlJoin(this.table,
      {this.condition, this.alias, required this.isInner});
  const SqlJoin.inner(this.table, {this.condition, this.alias})
      : this.isInner = true;
  const SqlJoin.left(this.table, {this.condition, this.alias})
      : this.isInner = false;

  @override
  String toSql(SqlContext ctx) {
    return ' ${isInner ? "INNER" : "LEFT"} JOIN'
        ' $table ${alias ?? ''}${condition == null ? '' : ' ON ${condition!.toSql(ctx)}'}';
  }
}

class SqlLimit {
  final int? offset;
  final int rowCount;

  const SqlLimit(this.rowCount, {this.offset});
}

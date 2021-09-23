import 'sql_values.dart';

enum SqlDatabase {
  mysql,
  postgres,
  sqlite,
}

abstract class TransactionContext extends TableConnection {
  const TransactionContext();
  Never rollback();

  factory TransactionContext.fromConnection(
    TableConnection conn, {
    required Never Function() rollback,
  }) = TransactionContextValue;
}

class TransactionContextValue extends TransactionContext {
  final TableConnection conn;
  final Never Function() _rollback;

  TransactionContextValue(
    this.conn, {
    required Never Function() rollback,
  }) : _rollback = rollback;

  @override
  SqlDatabase get database => conn.database;

  @override
  Future<SqlQueryResult> query(String sqlQuery, [List<Object?>? values]) {
    return conn.query(sqlQuery, values);
  }

  @override
  Never rollback() => _rollback();

  @override
  Future<T> transaction<T>(
    Future<T> Function(TransactionContext) transactionFn,
  ) {
    return conn.transaction(transactionFn);
  }
}

class SqlQuery {
  final String query;
  final List<String> params;

  const SqlQuery(this.query, this.params);
}

abstract class TableConnection {
  const TableConnection();
  SqlDatabase get database;

  Future<SqlQueryResult> query(
    String sqlQuery, [
    List<Object?>? values,
  ]);

  Future<T> transaction<T>(
    Future<T> Function(TransactionContext context) transactionFn,
  );

  Future<SqlQueryResult> select(
    String tableName,
    List<String> selects, {
    SqlValue<SqlBoolValue>? where,
    List<SqlOrderItem>? orderBy,
    SqlLimit? limit,
    List<String>? groupBy,
    List<SqlJoin>? join,
    bool unsafe = false,
  }) async {
    final sqlQuery = selectSql(
      tableName,
      selects,
      where: where,
      limit: limit,
      orderBy: orderBy,
    );

    return query(sqlQuery.query, sqlQuery.params);
    // int _refIndex = 3;

    // return result.map((r) {
    //   return Room(
    //     codeRoom: r[0] as String,
    //     section: r[1] as int,
    //     createdAt: r[2] as DateTime,
    //   );
    // }).toList();
  }

  SqlQuery selectSql(
    String tableName,
    List<String> selects, {
    SqlValue<SqlBoolValue>? where,
    List<SqlOrderItem>? orderBy,
    SqlLimit? limit,
    List<String>? groupBy,
    List<SqlJoin>? join,
    bool unsafe = false,
  }) {
// ${withRoom ? ",JSON_ARRAYAGG(JSON_OBJECT('codeRoom',room.code_room,'section',room.section,'createdAt',room.created_at)) refRoom" : ""}
// ${withUser ? ",JSON_ARRAYAGG(JSON_OBJECT('codeUser',user.code_user,'createdAt',user.created_at)) refUser" : ""}
// ${withTypeMessage ? ",JSON_ARRAYAGG(JSON_OBJECT('codeType',type_message.code_type,'createdAt',type_message.created_at)) refTypeMessage" : ""}

// ${withRoom ? "JOIN room ON message.room_code=room.code_room AND message.room_code_section=room.section" : ""}
// ${withUser ? "JOIN user ON message.user_code=user.code_user" : ""}
// ${withTypeMessage ? "JOIN type_message ON message.type_message_code=type_message.code_type" : ""}

    final ctx = SqlContext(database: database, unsafe: unsafe);
    final query = """
SELECT ${selects.join(',')}
FROM $tableName
${join == null ? '' : join.map((e) => e.toSql(ctx)).join('\n')}
${where == null ? '' : 'WHERE ${where.toSql(ctx)}'}
${groupBy == null ? '' : 'GROUP BY ${groupBy.join(',')}'}
${orderBy == null ? '' : 'ORDER BY ${orderBy.map((item) => item.toSql(ctx)).join(",")}'}
${limit == null ? '' : 'LIMIT ${limit.rowCount} ${limit.offset == null ? "" : "OFFSET ${limit.offset}"}'}
;""";
    return SqlQuery(query, ctx.variables);
  }
}

abstract class SqlQueryResult implements Iterable<SqlRow> {
  int? get affectedRows;
}

abstract class SqlRow implements Map<String, dynamic> {
  Object? columnAt(int index);
}

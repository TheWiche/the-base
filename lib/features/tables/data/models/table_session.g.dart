// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'table_session.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTableSessionCollection on Isar {
  IsarCollection<TableSession> get tableSessions => this.collection();
}

const TableSessionSchema = CollectionSchema(
  name: r'TableSession',
  id: -2278078652889476667,
  properties: {
    r'apodo': PropertySchema(
      id: 0,
      name: r'apodo',
      type: IsarType.string,
    ),
    r'closedAt': PropertySchema(
      id: 1,
      name: r'closedAt',
      type: IsarType.dateTime,
    ),
    r'openedAt': PropertySchema(
      id: 2,
      name: r'openedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 3,
      name: r'status',
      type: IsarType.byte,
      enumMap: _TableSessionstatusEnumValueMap,
    ),
    r'tableNumber': PropertySchema(
      id: 4,
      name: r'tableNumber',
      type: IsarType.long,
    ),
    r'verificationCode': PropertySchema(
      id: 5,
      name: r'verificationCode',
      type: IsarType.string,
    )
  },
  estimateSize: _tableSessionEstimateSize,
  serialize: _tableSessionSerialize,
  deserialize: _tableSessionDeserialize,
  deserializeProp: _tableSessionDeserializeProp,
  idName: r'id',
  indexes: {
    r'tableNumber': IndexSchema(
      id: -3323858932237924188,
      name: r'tableNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tableNumber',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'openedAt': IndexSchema(
      id: -5170574981129517220,
      name: r'openedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'openedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'orderItems': LinkSchema(
      id: 3740031000218941287,
      name: r'orderItems',
      target: r'OrderItem',
      single: false,
    ),
    r'payments': LinkSchema(
      id: -3797472867465413569,
      name: r'payments',
      target: r'PaymentReceipt',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _tableSessionGetId,
  getLinks: _tableSessionGetLinks,
  attach: _tableSessionAttach,
  version: '3.1.0+1',
);

int _tableSessionEstimateSize(
  TableSession object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.apodo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.verificationCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _tableSessionSerialize(
  TableSession object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.apodo);
  writer.writeDateTime(offsets[1], object.closedAt);
  writer.writeDateTime(offsets[2], object.openedAt);
  writer.writeByte(offsets[3], object.status.index);
  writer.writeLong(offsets[4], object.tableNumber);
  writer.writeString(offsets[5], object.verificationCode);
}

TableSession _tableSessionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TableSession();
  object.apodo = reader.readStringOrNull(offsets[0]);
  object.closedAt = reader.readDateTimeOrNull(offsets[1]);
  object.id = id;
  object.openedAt = reader.readDateTime(offsets[2]);
  object.status =
      _TableSessionstatusValueEnumMap[reader.readByteOrNull(offsets[3])] ??
          TableStatus.open;
  object.tableNumber = reader.readLong(offsets[4]);
  object.verificationCode = reader.readStringOrNull(offsets[5]);
  return object;
}

P _tableSessionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (_TableSessionstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          TableStatus.open) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TableSessionstatusEnumValueMap = {
  'open': 0,
  'partiallyPaid': 1,
  'closed': 2,
};
const _TableSessionstatusValueEnumMap = {
  0: TableStatus.open,
  1: TableStatus.partiallyPaid,
  2: TableStatus.closed,
};

Id _tableSessionGetId(TableSession object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _tableSessionGetLinks(TableSession object) {
  return [object.orderItems, object.payments];
}

void _tableSessionAttach(
    IsarCollection<dynamic> col, Id id, TableSession object) {
  object.id = id;
  object.orderItems
      .attach(col, col.isar.collection<OrderItem>(), r'orderItems', id);
  object.payments
      .attach(col, col.isar.collection<PaymentReceipt>(), r'payments', id);
}

extension TableSessionQueryWhereSort
    on QueryBuilder<TableSession, TableSession, QWhere> {
  QueryBuilder<TableSession, TableSession, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhere> anyTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'tableNumber'),
      );
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhere> anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhere> anyOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'openedAt'),
      );
    });
  }
}

extension TableSessionQueryWhere
    on QueryBuilder<TableSession, TableSession, QWhereClause> {
  QueryBuilder<TableSession, TableSession, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      tableNumberEqualTo(int tableNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tableNumber',
        value: [tableNumber],
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      tableNumberNotEqualTo(int tableNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableNumber',
              lower: [],
              upper: [tableNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableNumber',
              lower: [tableNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableNumber',
              lower: [tableNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableNumber',
              lower: [],
              upper: [tableNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      tableNumberGreaterThan(
    int tableNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tableNumber',
        lower: [tableNumber],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      tableNumberLessThan(
    int tableNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tableNumber',
        lower: [],
        upper: [tableNumber],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      tableNumberBetween(
    int lowerTableNumber,
    int upperTableNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tableNumber',
        lower: [lowerTableNumber],
        includeLower: includeLower,
        upper: [upperTableNumber],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> statusEqualTo(
      TableStatus status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> statusNotEqualTo(
      TableStatus status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> statusGreaterThan(
    TableStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [status],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> statusLessThan(
    TableStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [],
        upper: [status],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> statusBetween(
    TableStatus lowerStatus,
    TableStatus upperStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'status',
        lower: [lowerStatus],
        includeLower: includeLower,
        upper: [upperStatus],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> openedAtEqualTo(
      DateTime openedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'openedAt',
        value: [openedAt],
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      openedAtNotEqualTo(DateTime openedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'openedAt',
              lower: [],
              upper: [openedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'openedAt',
              lower: [openedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'openedAt',
              lower: [openedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'openedAt',
              lower: [],
              upper: [openedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause>
      openedAtGreaterThan(
    DateTime openedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'openedAt',
        lower: [openedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> openedAtLessThan(
    DateTime openedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'openedAt',
        lower: [],
        upper: [openedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterWhereClause> openedAtBetween(
    DateTime lowerOpenedAt,
    DateTime upperOpenedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'openedAt',
        lower: [lowerOpenedAt],
        includeLower: includeLower,
        upper: [upperOpenedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TableSessionQueryFilter
    on QueryBuilder<TableSession, TableSession, QFilterCondition> {
  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      apodoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'apodo',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      apodoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'apodo',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> apodoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apodo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      apodoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'apodo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> apodoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'apodo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> apodoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'apodo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      apodoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'apodo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> apodoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'apodo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> apodoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'apodo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> apodoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'apodo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      apodoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'apodo',
        value: '',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      apodoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'apodo',
        value: '',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      closedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closedAt',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      closedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closedAt',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      closedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      closedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      closedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      closedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      openedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      openedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      openedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      openedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> statusEqualTo(
      TableStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      statusGreaterThan(
    TableStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      statusLessThan(
    TableStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> statusBetween(
    TableStatus lower,
    TableStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      tableNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      tableNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tableNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      tableNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tableNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      tableNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tableNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'verificationCode',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'verificationCode',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verificationCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verificationCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verificationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      verificationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verificationCode',
        value: '',
      ));
    });
  }
}

extension TableSessionQueryObject
    on QueryBuilder<TableSession, TableSession, QFilterCondition> {}

extension TableSessionQueryLinks
    on QueryBuilder<TableSession, TableSession, QFilterCondition> {
  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> orderItems(
      FilterQuery<OrderItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'orderItems');
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      orderItemsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', length, true, length, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      orderItemsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', 0, true, 0, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      orderItemsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', 0, false, 999999, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      orderItemsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', 0, true, length, include);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      orderItemsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'orderItems', length, include, 999999, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      orderItemsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'orderItems', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition> payments(
      FilterQuery<PaymentReceipt> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'payments');
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      paymentsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'payments', length, true, length, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      paymentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'payments', 0, true, 0, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      paymentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'payments', 0, false, 999999, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      paymentsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'payments', 0, true, length, include);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      paymentsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'payments', length, include, 999999, true);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterFilterCondition>
      paymentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'payments', lower, includeLower, upper, includeUpper);
    });
  }
}

extension TableSessionQuerySortBy
    on QueryBuilder<TableSession, TableSession, QSortBy> {
  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByApodo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apodo', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByApodoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apodo', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByClosedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> sortByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy>
      sortByTableNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy>
      sortByVerificationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy>
      sortByVerificationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.desc);
    });
  }
}

extension TableSessionQuerySortThenBy
    on QueryBuilder<TableSession, TableSession, QSortThenBy> {
  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByApodo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apodo', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByApodoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apodo', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByClosedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy> thenByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy>
      thenByTableNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.desc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy>
      thenByVerificationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.asc);
    });
  }

  QueryBuilder<TableSession, TableSession, QAfterSortBy>
      thenByVerificationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.desc);
    });
  }
}

extension TableSessionQueryWhereDistinct
    on QueryBuilder<TableSession, TableSession, QDistinct> {
  QueryBuilder<TableSession, TableSession, QDistinct> distinctByApodo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apodo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TableSession, TableSession, QDistinct> distinctByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closedAt');
    });
  }

  QueryBuilder<TableSession, TableSession, QDistinct> distinctByOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openedAt');
    });
  }

  QueryBuilder<TableSession, TableSession, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<TableSession, TableSession, QDistinct> distinctByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tableNumber');
    });
  }

  QueryBuilder<TableSession, TableSession, QDistinct>
      distinctByVerificationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verificationCode',
          caseSensitive: caseSensitive);
    });
  }
}

extension TableSessionQueryProperty
    on QueryBuilder<TableSession, TableSession, QQueryProperty> {
  QueryBuilder<TableSession, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TableSession, String?, QQueryOperations> apodoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apodo');
    });
  }

  QueryBuilder<TableSession, DateTime?, QQueryOperations> closedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closedAt');
    });
  }

  QueryBuilder<TableSession, DateTime, QQueryOperations> openedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openedAt');
    });
  }

  QueryBuilder<TableSession, TableStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<TableSession, int, QQueryOperations> tableNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tableNumber');
    });
  }

  QueryBuilder<TableSession, String?, QQueryOperations>
      verificationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verificationCode');
    });
  }
}

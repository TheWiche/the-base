// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_snapshot.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetShiftSnapshotCollection on Isar {
  IsarCollection<ShiftSnapshot> get shiftSnapshots => this.collection();
}

const ShiftSnapshotSchema = CollectionSchema(
  name: r'ShiftSnapshot',
  id: 497135310374613032,
  properties: {
    r'availableBalance': PropertySchema(
      id: 0,
      name: r'availableBalance',
      type: IsarType.long,
    ),
    r'cashInHand': PropertySchema(
      id: 1,
      name: r'cashInHand',
      type: IsarType.long,
    ),
    r'cashPaymentsTotal': PropertySchema(
      id: 2,
      name: r'cashPaymentsTotal',
      type: IsarType.long,
    ),
    r'initialBase': PropertySchema(
      id: 3,
      name: r'initialBase',
      type: IsarType.long,
    ),
    r'netProfit': PropertySchema(
      id: 4,
      name: r'netProfit',
      type: IsarType.long,
    ),
    r'servedStandardItemsTotal': PropertySchema(
      id: 5,
      name: r'servedStandardItemsTotal',
      type: IsarType.long,
    ),
    r'snapshotAt': PropertySchema(
      id: 6,
      name: r'snapshotAt',
      type: IsarType.dateTime,
    ),
    r'totalDebt': PropertySchema(
      id: 7,
      name: r'totalDebt',
      type: IsarType.long,
    ),
    r'totalDecreases': PropertySchema(
      id: 8,
      name: r'totalDecreases',
      type: IsarType.long,
    ),
    r'totalIncreases': PropertySchema(
      id: 9,
      name: r'totalIncreases',
      type: IsarType.long,
    ),
    r'totalLiquorDebt': PropertySchema(
      id: 10,
      name: r'totalLiquorDebt',
      type: IsarType.long,
    ),
    r'transferTipsTotal': PropertySchema(
      id: 11,
      name: r'transferTipsTotal',
      type: IsarType.long,
    ),
    r'verifiedTransfersTotal': PropertySchema(
      id: 12,
      name: r'verifiedTransfersTotal',
      type: IsarType.long,
    )
  },
  estimateSize: _shiftSnapshotEstimateSize,
  serialize: _shiftSnapshotSerialize,
  deserialize: _shiftSnapshotDeserialize,
  deserializeProp: _shiftSnapshotDeserializeProp,
  idName: r'id',
  indexes: {
    r'snapshotAt': IndexSchema(
      id: 6285255341184370317,
      name: r'snapshotAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'snapshotAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _shiftSnapshotGetId,
  getLinks: _shiftSnapshotGetLinks,
  attach: _shiftSnapshotAttach,
  version: '3.1.0+1',
);

int _shiftSnapshotEstimateSize(
  ShiftSnapshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _shiftSnapshotSerialize(
  ShiftSnapshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.availableBalance);
  writer.writeLong(offsets[1], object.cashInHand);
  writer.writeLong(offsets[2], object.cashPaymentsTotal);
  writer.writeLong(offsets[3], object.initialBase);
  writer.writeLong(offsets[4], object.netProfit);
  writer.writeLong(offsets[5], object.servedStandardItemsTotal);
  writer.writeDateTime(offsets[6], object.snapshotAt);
  writer.writeLong(offsets[7], object.totalDebt);
  writer.writeLong(offsets[8], object.totalDecreases);
  writer.writeLong(offsets[9], object.totalIncreases);
  writer.writeLong(offsets[10], object.totalLiquorDebt);
  writer.writeLong(offsets[11], object.transferTipsTotal);
  writer.writeLong(offsets[12], object.verifiedTransfersTotal);
}

ShiftSnapshot _shiftSnapshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ShiftSnapshot();
  object.availableBalance = reader.readLong(offsets[0]);
  object.cashInHand = reader.readLong(offsets[1]);
  object.cashPaymentsTotal = reader.readLong(offsets[2]);
  object.id = id;
  object.initialBase = reader.readLong(offsets[3]);
  object.netProfit = reader.readLong(offsets[4]);
  object.servedStandardItemsTotal = reader.readLong(offsets[5]);
  object.snapshotAt = reader.readDateTime(offsets[6]);
  object.totalDebt = reader.readLong(offsets[7]);
  object.totalDecreases = reader.readLong(offsets[8]);
  object.totalIncreases = reader.readLong(offsets[9]);
  object.totalLiquorDebt = reader.readLong(offsets[10]);
  object.transferTipsTotal = reader.readLong(offsets[11]);
  object.verifiedTransfersTotal = reader.readLong(offsets[12]);
  return object;
}

P _shiftSnapshotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _shiftSnapshotGetId(ShiftSnapshot object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _shiftSnapshotGetLinks(ShiftSnapshot object) {
  return [];
}

void _shiftSnapshotAttach(
    IsarCollection<dynamic> col, Id id, ShiftSnapshot object) {
  object.id = id;
}

extension ShiftSnapshotQueryWhereSort
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QWhere> {
  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhere> anySnapshotAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'snapshotAt'),
      );
    });
  }
}

extension ShiftSnapshotQueryWhere
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QWhereClause> {
  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause> idBetween(
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

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause>
      snapshotAtEqualTo(DateTime snapshotAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'snapshotAt',
        value: [snapshotAt],
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause>
      snapshotAtNotEqualTo(DateTime snapshotAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotAt',
              lower: [],
              upper: [snapshotAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotAt',
              lower: [snapshotAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotAt',
              lower: [snapshotAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'snapshotAt',
              lower: [],
              upper: [snapshotAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause>
      snapshotAtGreaterThan(
    DateTime snapshotAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'snapshotAt',
        lower: [snapshotAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause>
      snapshotAtLessThan(
    DateTime snapshotAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'snapshotAt',
        lower: [],
        upper: [snapshotAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterWhereClause>
      snapshotAtBetween(
    DateTime lowerSnapshotAt,
    DateTime upperSnapshotAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'snapshotAt',
        lower: [lowerSnapshotAt],
        includeLower: includeLower,
        upper: [upperSnapshotAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ShiftSnapshotQueryFilter
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QFilterCondition> {
  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      availableBalanceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'availableBalance',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      availableBalanceGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'availableBalance',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      availableBalanceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'availableBalance',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      availableBalanceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'availableBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashInHandEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cashInHand',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashInHandGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cashInHand',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashInHandLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cashInHand',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashInHandBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cashInHand',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashPaymentsTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cashPaymentsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashPaymentsTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cashPaymentsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashPaymentsTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cashPaymentsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      cashPaymentsTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cashPaymentsTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      initialBaseEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'initialBase',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      initialBaseGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'initialBase',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      initialBaseLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'initialBase',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      initialBaseBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'initialBase',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      netProfitEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'netProfit',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      netProfitGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'netProfit',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      netProfitLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'netProfit',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      netProfitBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'netProfit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      servedStandardItemsTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servedStandardItemsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      servedStandardItemsTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'servedStandardItemsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      servedStandardItemsTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'servedStandardItemsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      servedStandardItemsTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'servedStandardItemsTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      snapshotAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'snapshotAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      snapshotAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'snapshotAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      snapshotAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'snapshotAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      snapshotAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'snapshotAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDebtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDebt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDebtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDebt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDebtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDebt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDebtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDebt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDecreasesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDecreases',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDecreasesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDecreases',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDecreasesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDecreases',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalDecreasesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDecreases',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalIncreasesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalIncreases',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalIncreasesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalIncreases',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalIncreasesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalIncreases',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalIncreasesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalIncreases',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalLiquorDebtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalLiquorDebt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalLiquorDebtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalLiquorDebt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalLiquorDebtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalLiquorDebt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      totalLiquorDebtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalLiquorDebt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      transferTipsTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transferTipsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      transferTipsTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transferTipsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      transferTipsTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transferTipsTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      transferTipsTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transferTipsTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      verifiedTransfersTotalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verifiedTransfersTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      verifiedTransfersTotalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verifiedTransfersTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      verifiedTransfersTotalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verifiedTransfersTotal',
        value: value,
      ));
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterFilterCondition>
      verifiedTransfersTotalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verifiedTransfersTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ShiftSnapshotQueryObject
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QFilterCondition> {}

extension ShiftSnapshotQueryLinks
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QFilterCondition> {}

extension ShiftSnapshotQuerySortBy
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QSortBy> {
  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByAvailableBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableBalance', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByAvailableBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableBalance', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> sortByCashInHand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashInHand', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByCashInHandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashInHand', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByCashPaymentsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashPaymentsTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByCashPaymentsTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashPaymentsTotal', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> sortByInitialBase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBase', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByInitialBaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBase', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> sortByNetProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netProfit', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByNetProfitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netProfit', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByServedStandardItemsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedStandardItemsTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByServedStandardItemsTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedStandardItemsTotal', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> sortBySnapshotAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotAt', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortBySnapshotAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotAt', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> sortByTotalDebt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDebt', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalDebtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDebt', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalDecreases() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDecreases', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalDecreasesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDecreases', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalIncreases() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncreases', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalIncreasesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncreases', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalLiquorDebt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLiquorDebt', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTotalLiquorDebtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLiquorDebt', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTransferTipsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferTipsTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByTransferTipsTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferTipsTotal', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByVerifiedTransfersTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedTransfersTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      sortByVerifiedTransfersTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedTransfersTotal', Sort.desc);
    });
  }
}

extension ShiftSnapshotQuerySortThenBy
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QSortThenBy> {
  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByAvailableBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableBalance', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByAvailableBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'availableBalance', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenByCashInHand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashInHand', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByCashInHandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashInHand', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByCashPaymentsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashPaymentsTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByCashPaymentsTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cashPaymentsTotal', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenByInitialBase() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBase', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByInitialBaseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'initialBase', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenByNetProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netProfit', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByNetProfitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netProfit', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByServedStandardItemsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedStandardItemsTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByServedStandardItemsTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servedStandardItemsTotal', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenBySnapshotAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotAt', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenBySnapshotAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'snapshotAt', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy> thenByTotalDebt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDebt', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalDebtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDebt', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalDecreases() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDecreases', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalDecreasesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDecreases', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalIncreases() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncreases', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalIncreasesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalIncreases', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalLiquorDebt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLiquorDebt', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTotalLiquorDebtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalLiquorDebt', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTransferTipsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferTipsTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByTransferTipsTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferTipsTotal', Sort.desc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByVerifiedTransfersTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedTransfersTotal', Sort.asc);
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QAfterSortBy>
      thenByVerifiedTransfersTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verifiedTransfersTotal', Sort.desc);
    });
  }
}

extension ShiftSnapshotQueryWhereDistinct
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct> {
  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByAvailableBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'availableBalance');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct> distinctByCashInHand() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cashInHand');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByCashPaymentsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cashPaymentsTotal');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByInitialBase() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'initialBase');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct> distinctByNetProfit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netProfit');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByServedStandardItemsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servedStandardItemsTotal');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct> distinctBySnapshotAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'snapshotAt');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct> distinctByTotalDebt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDebt');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByTotalDecreases() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDecreases');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByTotalIncreases() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalIncreases');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByTotalLiquorDebt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalLiquorDebt');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByTransferTipsTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transferTipsTotal');
    });
  }

  QueryBuilder<ShiftSnapshot, ShiftSnapshot, QDistinct>
      distinctByVerifiedTransfersTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verifiedTransfersTotal');
    });
  }
}

extension ShiftSnapshotQueryProperty
    on QueryBuilder<ShiftSnapshot, ShiftSnapshot, QQueryProperty> {
  QueryBuilder<ShiftSnapshot, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations>
      availableBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'availableBalance');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> cashInHandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cashInHand');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations>
      cashPaymentsTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cashPaymentsTotal');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> initialBaseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'initialBase');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> netProfitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netProfit');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations>
      servedStandardItemsTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servedStandardItemsTotal');
    });
  }

  QueryBuilder<ShiftSnapshot, DateTime, QQueryOperations> snapshotAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'snapshotAt');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> totalDebtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDebt');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> totalDecreasesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDecreases');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> totalIncreasesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalIncreases');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations> totalLiquorDebtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalLiquorDebt');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations>
      transferTipsTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transferTipsTotal');
    });
  }

  QueryBuilder<ShiftSnapshot, int, QQueryOperations>
      verifiedTransfersTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verifiedTransfersTotal');
    });
  }
}

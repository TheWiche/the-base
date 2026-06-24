// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_receipt.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPaymentReceiptCollection on Isar {
  IsarCollection<PaymentReceipt> get paymentReceipts => this.collection();
}

const PaymentReceiptSchema = CollectionSchema(
  name: r'PaymentReceipt',
  id: -8242016932844722686,
  properties: {
    r'amountPaid': PropertySchema(
      id: 0,
      name: r'amountPaid',
      type: IsarType.long,
    ),
    r'changeGiven': PropertySchema(
      id: 1,
      name: r'changeGiven',
      type: IsarType.long,
    ),
    r'isLegalizedInCaja': PropertySchema(
      id: 2,
      name: r'isLegalizedInCaja',
      type: IsarType.bool,
    ),
    r'paidAt': PropertySchema(
      id: 3,
      name: r'paidAt',
      type: IsarType.dateTime,
    ),
    r'paymentMethod': PropertySchema(
      id: 4,
      name: r'paymentMethod',
      type: IsarType.byte,
      enumMap: _PaymentReceiptpaymentMethodEnumValueMap,
    ),
    r'photoPath': PropertySchema(
      id: 5,
      name: r'photoPath',
      type: IsarType.string,
    ),
    r'supabasePhotoUrl': PropertySchema(
      id: 6,
      name: r'supabasePhotoUrl',
      type: IsarType.string,
    ),
    r'tableSessionId': PropertySchema(
      id: 7,
      name: r'tableSessionId',
      type: IsarType.long,
    ),
    r'tipAmount': PropertySchema(
      id: 8,
      name: r'tipAmount',
      type: IsarType.long,
    ),
    r'transferMethodIndex': PropertySchema(
      id: 9,
      name: r'transferMethodIndex',
      type: IsarType.long,
    ),
    r'verificationCode': PropertySchema(
      id: 10,
      name: r'verificationCode',
      type: IsarType.string,
    )
  },
  estimateSize: _paymentReceiptEstimateSize,
  serialize: _paymentReceiptSerialize,
  deserialize: _paymentReceiptDeserialize,
  deserializeProp: _paymentReceiptDeserializeProp,
  idName: r'id',
  indexes: {
    r'tableSessionId': IndexSchema(
      id: -4296580020788134000,
      name: r'tableSessionId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'tableSessionId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isLegalizedInCaja': IndexSchema(
      id: 7746600605492365367,
      name: r'isLegalizedInCaja',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isLegalizedInCaja',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'paidAt': IndexSchema(
      id: -701685063105958775,
      name: r'paidAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'paidAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'tableSession': LinkSchema(
      id: -573299664468034064,
      name: r'tableSession',
      target: r'TableSession',
      single: true,
      linkName: r'payments',
    )
  },
  embeddedSchemas: {},
  getId: _paymentReceiptGetId,
  getLinks: _paymentReceiptGetLinks,
  attach: _paymentReceiptAttach,
  version: '3.1.0+1',
);

int _paymentReceiptEstimateSize(
  PaymentReceipt object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.photoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.supabasePhotoUrl;
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

void _paymentReceiptSerialize(
  PaymentReceipt object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.amountPaid);
  writer.writeLong(offsets[1], object.changeGiven);
  writer.writeBool(offsets[2], object.isLegalizedInCaja);
  writer.writeDateTime(offsets[3], object.paidAt);
  writer.writeByte(offsets[4], object.paymentMethod.index);
  writer.writeString(offsets[5], object.photoPath);
  writer.writeString(offsets[6], object.supabasePhotoUrl);
  writer.writeLong(offsets[7], object.tableSessionId);
  writer.writeLong(offsets[8], object.tipAmount);
  writer.writeLong(offsets[9], object.transferMethodIndex);
  writer.writeString(offsets[10], object.verificationCode);
}

PaymentReceipt _paymentReceiptDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PaymentReceipt();
  object.amountPaid = reader.readLong(offsets[0]);
  object.changeGiven = reader.readLong(offsets[1]);
  object.id = id;
  object.isLegalizedInCaja = reader.readBool(offsets[2]);
  object.paidAt = reader.readDateTime(offsets[3]);
  object.paymentMethod = _PaymentReceiptpaymentMethodValueEnumMap[
          reader.readByteOrNull(offsets[4])] ??
      PaymentMethod.cash;
  object.photoPath = reader.readStringOrNull(offsets[5]);
  object.supabasePhotoUrl = reader.readStringOrNull(offsets[6]);
  object.tableSessionId = reader.readLong(offsets[7]);
  object.tipAmount = reader.readLong(offsets[8]);
  object.transferMethodIndex = reader.readLongOrNull(offsets[9]);
  object.verificationCode = reader.readStringOrNull(offsets[10]);
  return object;
}

P _paymentReceiptDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (_PaymentReceiptpaymentMethodValueEnumMap[
              reader.readByteOrNull(offset)] ??
          PaymentMethod.cash) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PaymentReceiptpaymentMethodEnumValueMap = {
  'cash': 0,
  'transfer': 1,
};
const _PaymentReceiptpaymentMethodValueEnumMap = {
  0: PaymentMethod.cash,
  1: PaymentMethod.transfer,
};

Id _paymentReceiptGetId(PaymentReceipt object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _paymentReceiptGetLinks(PaymentReceipt object) {
  return [object.tableSession];
}

void _paymentReceiptAttach(
    IsarCollection<dynamic> col, Id id, PaymentReceipt object) {
  object.id = id;
  object.tableSession
      .attach(col, col.isar.collection<TableSession>(), r'tableSession', id);
}

extension PaymentReceiptQueryWhereSort
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QWhere> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhere>
      anyTableSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'tableSessionId'),
      );
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhere>
      anyIsLegalizedInCaja() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isLegalizedInCaja'),
      );
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhere> anyPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'paidAt'),
      );
    });
  }
}

extension PaymentReceiptQueryWhere
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QWhereClause> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> idBetween(
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      tableSessionIdEqualTo(int tableSessionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'tableSessionId',
        value: [tableSessionId],
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      tableSessionIdNotEqualTo(int tableSessionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableSessionId',
              lower: [],
              upper: [tableSessionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableSessionId',
              lower: [tableSessionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableSessionId',
              lower: [tableSessionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'tableSessionId',
              lower: [],
              upper: [tableSessionId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      tableSessionIdGreaterThan(
    int tableSessionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tableSessionId',
        lower: [tableSessionId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      tableSessionIdLessThan(
    int tableSessionId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tableSessionId',
        lower: [],
        upper: [tableSessionId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      tableSessionIdBetween(
    int lowerTableSessionId,
    int upperTableSessionId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'tableSessionId',
        lower: [lowerTableSessionId],
        includeLower: includeLower,
        upper: [upperTableSessionId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      isLegalizedInCajaEqualTo(bool isLegalizedInCaja) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isLegalizedInCaja',
        value: [isLegalizedInCaja],
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      isLegalizedInCajaNotEqualTo(bool isLegalizedInCaja) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isLegalizedInCaja',
              lower: [],
              upper: [isLegalizedInCaja],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isLegalizedInCaja',
              lower: [isLegalizedInCaja],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isLegalizedInCaja',
              lower: [isLegalizedInCaja],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isLegalizedInCaja',
              lower: [],
              upper: [isLegalizedInCaja],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> paidAtEqualTo(
      DateTime paidAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'paidAt',
        value: [paidAt],
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      paidAtNotEqualTo(DateTime paidAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paidAt',
              lower: [],
              upper: [paidAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paidAt',
              lower: [paidAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paidAt',
              lower: [paidAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paidAt',
              lower: [],
              upper: [paidAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      paidAtGreaterThan(
    DateTime paidAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paidAt',
        lower: [paidAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause>
      paidAtLessThan(
    DateTime paidAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paidAt',
        lower: [],
        upper: [paidAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterWhereClause> paidAtBetween(
    DateTime lowerPaidAt,
    DateTime upperPaidAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'paidAt',
        lower: [lowerPaidAt],
        includeLower: includeLower,
        upper: [upperPaidAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PaymentReceiptQueryFilter
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QFilterCondition> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      amountPaidEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amountPaid',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      amountPaidGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amountPaid',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      amountPaidLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amountPaid',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      amountPaidBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amountPaid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      changeGivenEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'changeGiven',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      changeGivenGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'changeGiven',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      changeGivenLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'changeGiven',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      changeGivenBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'changeGiven',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      isLegalizedInCajaEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLegalizedInCaja',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paidAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paidAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paidAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paidAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paidAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paidAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paymentMethodEqualTo(PaymentMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paymentMethodGreaterThan(
    PaymentMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paymentMethodLessThan(
    PaymentMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      paymentMethodBetween(
    PaymentMethod lower,
    PaymentMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'photoPath',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      photoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'supabasePhotoUrl',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'supabasePhotoUrl',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supabasePhotoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supabasePhotoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supabasePhotoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supabasePhotoUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'supabasePhotoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'supabasePhotoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'supabasePhotoUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'supabasePhotoUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supabasePhotoUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      supabasePhotoUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'supabasePhotoUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tableSessionIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableSessionId',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tableSessionIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tableSessionId',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tableSessionIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tableSessionId',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tableSessionIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tableSessionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tipAmountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tipAmountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tipAmountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipAmount',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tipAmountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      transferMethodIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transferMethodIndex',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      transferMethodIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transferMethodIndex',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      transferMethodIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transferMethodIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      transferMethodIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transferMethodIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      transferMethodIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transferMethodIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      transferMethodIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transferMethodIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      verificationCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'verificationCode',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      verificationCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'verificationCode',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
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

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      verificationCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verificationCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      verificationCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verificationCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      verificationCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verificationCode',
        value: '',
      ));
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      verificationCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verificationCode',
        value: '',
      ));
    });
  }
}

extension PaymentReceiptQueryObject
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QFilterCondition> {}

extension PaymentReceiptQueryLinks
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QFilterCondition> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tableSession(FilterQuery<TableSession> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'tableSession');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterFilterCondition>
      tableSessionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'tableSession', 0, true, 0, true);
    });
  }
}

extension PaymentReceiptQuerySortBy
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QSortBy> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByAmountPaidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByChangeGiven() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeGiven', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByChangeGivenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeGiven', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByIsLegalizedInCaja() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLegalizedInCaja', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByIsLegalizedInCajaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLegalizedInCaja', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> sortByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByPaidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> sortByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortBySupabasePhotoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabasePhotoUrl', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortBySupabasePhotoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabasePhotoUrl', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByTableSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableSessionId', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByTableSessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableSessionId', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> sortByTipAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipAmount', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByTipAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipAmount', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByTransferMethodIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferMethodIndex', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByTransferMethodIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferMethodIndex', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByVerificationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      sortByVerificationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.desc);
    });
  }
}

extension PaymentReceiptQuerySortThenBy
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QSortThenBy> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByAmountPaidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amountPaid', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByChangeGiven() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeGiven', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByChangeGivenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeGiven', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByIsLegalizedInCaja() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLegalizedInCaja', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByIsLegalizedInCajaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLegalizedInCaja', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> thenByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByPaidAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAt', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> thenByPhotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByPhotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'photoPath', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenBySupabasePhotoUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabasePhotoUrl', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenBySupabasePhotoUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supabasePhotoUrl', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByTableSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableSessionId', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByTableSessionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableSessionId', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy> thenByTipAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipAmount', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByTipAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipAmount', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByTransferMethodIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferMethodIndex', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByTransferMethodIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transferMethodIndex', Sort.desc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByVerificationCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.asc);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QAfterSortBy>
      thenByVerificationCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verificationCode', Sort.desc);
    });
  }
}

extension PaymentReceiptQueryWhereDistinct
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct> {
  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByAmountPaid() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amountPaid');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByChangeGiven() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'changeGiven');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByIsLegalizedInCaja() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLegalizedInCaja');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct> distinctByPaidAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAt');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMethod');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct> distinctByPhotoPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctBySupabasePhotoUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supabasePhotoUrl',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByTableSessionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tableSessionId');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByTipAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipAmount');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByTransferMethodIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transferMethodIndex');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentReceipt, QDistinct>
      distinctByVerificationCode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verificationCode',
          caseSensitive: caseSensitive);
    });
  }
}

extension PaymentReceiptQueryProperty
    on QueryBuilder<PaymentReceipt, PaymentReceipt, QQueryProperty> {
  QueryBuilder<PaymentReceipt, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PaymentReceipt, int, QQueryOperations> amountPaidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amountPaid');
    });
  }

  QueryBuilder<PaymentReceipt, int, QQueryOperations> changeGivenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'changeGiven');
    });
  }

  QueryBuilder<PaymentReceipt, bool, QQueryOperations>
      isLegalizedInCajaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLegalizedInCaja');
    });
  }

  QueryBuilder<PaymentReceipt, DateTime, QQueryOperations> paidAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAt');
    });
  }

  QueryBuilder<PaymentReceipt, PaymentMethod, QQueryOperations>
      paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<PaymentReceipt, String?, QQueryOperations> photoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoPath');
    });
  }

  QueryBuilder<PaymentReceipt, String?, QQueryOperations>
      supabasePhotoUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supabasePhotoUrl');
    });
  }

  QueryBuilder<PaymentReceipt, int, QQueryOperations> tableSessionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tableSessionId');
    });
  }

  QueryBuilder<PaymentReceipt, int, QQueryOperations> tipAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipAmount');
    });
  }

  QueryBuilder<PaymentReceipt, int?, QQueryOperations>
      transferMethodIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transferMethodIndex');
    });
  }

  QueryBuilder<PaymentReceipt, String?, QQueryOperations>
      verificationCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verificationCode');
    });
  }
}

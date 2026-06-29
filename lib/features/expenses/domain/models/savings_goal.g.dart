// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_goal.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSavingsGoalCollection on Isar {
  IsarCollection<SavingsGoal> get savingsGoals => this.collection();
}

const SavingsGoalSchema = CollectionSchema(
  name: r'SavingsGoal',
  id: 2336982407974704875,
  properties: {
    r'savedAmount': PropertySchema(
      id: 0,
      name: r'savedAmount',
      type: IsarType.double,
    ),
    r'targetAmount': PropertySchema(
      id: 1,
      name: r'targetAmount',
      type: IsarType.double,
    ),
    r'title': PropertySchema(
      id: 2,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _savingsGoalEstimateSize,
  serialize: _savingsGoalSerialize,
  deserialize: _savingsGoalDeserialize,
  deserializeProp: _savingsGoalDeserializeProp,
  idName: r'id',
  indexes: {
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _savingsGoalGetId,
  getLinks: _savingsGoalGetLinks,
  attach: _savingsGoalAttach,
  version: '3.1.0+1',
);

int _savingsGoalEstimateSize(
  SavingsGoal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _savingsGoalSerialize(
  SavingsGoal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.savedAmount);
  writer.writeDouble(offsets[1], object.targetAmount);
  writer.writeString(offsets[2], object.title);
}

SavingsGoal _savingsGoalDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SavingsGoal();
  object.id = id;
  object.savedAmount = reader.readDouble(offsets[0]);
  object.targetAmount = reader.readDouble(offsets[1]);
  object.title = reader.readString(offsets[2]);
  return object;
}

P _savingsGoalDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _savingsGoalGetId(SavingsGoal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _savingsGoalGetLinks(SavingsGoal object) {
  return [];
}

void _savingsGoalAttach(
    IsarCollection<dynamic> col, Id id, SavingsGoal object) {
  object.id = id;
}

extension SavingsGoalByIndex on IsarCollection<SavingsGoal> {
  Future<SavingsGoal?> getByTitle(String title) {
    return getByIndex(r'title', [title]);
  }

  SavingsGoal? getByTitleSync(String title) {
    return getByIndexSync(r'title', [title]);
  }

  Future<bool> deleteByTitle(String title) {
    return deleteByIndex(r'title', [title]);
  }

  bool deleteByTitleSync(String title) {
    return deleteByIndexSync(r'title', [title]);
  }

  Future<List<SavingsGoal?>> getAllByTitle(List<String> titleValues) {
    final values = titleValues.map((e) => [e]).toList();
    return getAllByIndex(r'title', values);
  }

  List<SavingsGoal?> getAllByTitleSync(List<String> titleValues) {
    final values = titleValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'title', values);
  }

  Future<int> deleteAllByTitle(List<String> titleValues) {
    final values = titleValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'title', values);
  }

  int deleteAllByTitleSync(List<String> titleValues) {
    final values = titleValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'title', values);
  }

  Future<Id> putByTitle(SavingsGoal object) {
    return putByIndex(r'title', object);
  }

  Id putByTitleSync(SavingsGoal object, {bool saveLinks = true}) {
    return putByIndexSync(r'title', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTitle(List<SavingsGoal> objects) {
    return putAllByIndex(r'title', objects);
  }

  List<Id> putAllByTitleSync(List<SavingsGoal> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'title', objects, saveLinks: saveLinks);
  }
}

extension SavingsGoalQueryWhereSort
    on QueryBuilder<SavingsGoal, SavingsGoal, QWhere> {
  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SavingsGoalQueryWhere
    on QueryBuilder<SavingsGoal, SavingsGoal, QWhereClause> {
  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> idBetween(
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

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> titleEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterWhereClause> titleNotEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }
}

extension SavingsGoalQueryFilter
    on QueryBuilder<SavingsGoal, SavingsGoal, QFilterCondition> {
  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      savedAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      savedAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      savedAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savedAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      savedAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savedAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      targetAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'targetAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      targetAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'targetAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      targetAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'targetAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      targetAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'targetAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension SavingsGoalQueryObject
    on QueryBuilder<SavingsGoal, SavingsGoal, QFilterCondition> {}

extension SavingsGoalQueryLinks
    on QueryBuilder<SavingsGoal, SavingsGoal, QFilterCondition> {}

extension SavingsGoalQuerySortBy
    on QueryBuilder<SavingsGoal, SavingsGoal, QSortBy> {
  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> sortBySavedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAmount', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> sortBySavedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAmount', Sort.desc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> sortByTargetAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy>
      sortByTargetAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.desc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension SavingsGoalQuerySortThenBy
    on QueryBuilder<SavingsGoal, SavingsGoal, QSortThenBy> {
  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenBySavedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAmount', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenBySavedAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedAmount', Sort.desc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenByTargetAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy>
      thenByTargetAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'targetAmount', Sort.desc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension SavingsGoalQueryWhereDistinct
    on QueryBuilder<SavingsGoal, SavingsGoal, QDistinct> {
  QueryBuilder<SavingsGoal, SavingsGoal, QDistinct> distinctBySavedAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedAmount');
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QDistinct> distinctByTargetAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'targetAmount');
    });
  }

  QueryBuilder<SavingsGoal, SavingsGoal, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension SavingsGoalQueryProperty
    on QueryBuilder<SavingsGoal, SavingsGoal, QQueryProperty> {
  QueryBuilder<SavingsGoal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SavingsGoal, double, QQueryOperations> savedAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedAmount');
    });
  }

  QueryBuilder<SavingsGoal, double, QQueryOperations> targetAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'targetAmount');
    });
  }

  QueryBuilder<SavingsGoal, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}

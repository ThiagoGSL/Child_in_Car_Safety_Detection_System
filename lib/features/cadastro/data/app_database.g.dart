// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserDatasTable extends UserDatas
    with TableInfo<$UserDatasTable, UserData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDatasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userNameMeta = const VerificationMeta(
    'userName',
  );
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
    'user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _childNameMeta = const VerificationMeta(
    'childName',
  );
  @override
  late final GeneratedColumn<String> childName = GeneratedColumn<String>(
    'child_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emergencyNameMeta = const VerificationMeta(
    'emergencyName',
  );
  @override
  late final GeneratedColumn<String> emergencyName = GeneratedColumn<String>(
    'emergency_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emergencyPhoneMeta = const VerificationMeta(
    'emergencyPhone',
  );
  @override
  late final GeneratedColumn<String> emergencyPhone = GeneratedColumn<String>(
    'emergency_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userName,
    childName,
    email,
    phone,
    emergencyName,
    emergencyPhone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_datas';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_name')) {
      context.handle(
        _userNameMeta,
        userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta),
      );
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('child_name')) {
      context.handle(
        _childNameMeta,
        childName.isAcceptableOrUnknown(data['child_name']!, _childNameMeta),
      );
    } else if (isInserting) {
      context.missing(_childNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('emergency_name')) {
      context.handle(
        _emergencyNameMeta,
        emergencyName.isAcceptableOrUnknown(
          data['emergency_name']!,
          _emergencyNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_emergencyNameMeta);
    }
    if (data.containsKey('emergency_phone')) {
      context.handle(
        _emergencyPhoneMeta,
        emergencyPhone.isAcceptableOrUnknown(
          data['emergency_phone']!,
          _emergencyPhoneMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_emergencyPhoneMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      userName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}user_name'],
          )!,
      childName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}child_name'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      phone:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}phone'],
          )!,
      emergencyName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}emergency_name'],
          )!,
      emergencyPhone:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}emergency_phone'],
          )!,
    );
  }

  @override
  $UserDatasTable createAlias(String alias) {
    return $UserDatasTable(attachedDatabase, alias);
  }
}

class UserData extends DataClass implements Insertable<UserData> {
  final int id;
  final String userName;
  final String childName;
  final String email;
  final String phone;
  final String emergencyName;
  final String emergencyPhone;
  const UserData({
    required this.id,
    required this.userName,
    required this.childName,
    required this.email,
    required this.phone,
    required this.emergencyName,
    required this.emergencyPhone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_name'] = Variable<String>(userName);
    map['child_name'] = Variable<String>(childName);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['emergency_name'] = Variable<String>(emergencyName);
    map['emergency_phone'] = Variable<String>(emergencyPhone);
    return map;
  }

  UserDatasCompanion toCompanion(bool nullToAbsent) {
    return UserDatasCompanion(
      id: Value(id),
      userName: Value(userName),
      childName: Value(childName),
      email: Value(email),
      phone: Value(phone),
      emergencyName: Value(emergencyName),
      emergencyPhone: Value(emergencyPhone),
    );
  }

  factory UserData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserData(
      id: serializer.fromJson<int>(json['id']),
      userName: serializer.fromJson<String>(json['userName']),
      childName: serializer.fromJson<String>(json['childName']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      emergencyName: serializer.fromJson<String>(json['emergencyName']),
      emergencyPhone: serializer.fromJson<String>(json['emergencyPhone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userName': serializer.toJson<String>(userName),
      'childName': serializer.toJson<String>(childName),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'emergencyName': serializer.toJson<String>(emergencyName),
      'emergencyPhone': serializer.toJson<String>(emergencyPhone),
    };
  }

  UserData copyWith({
    int? id,
    String? userName,
    String? childName,
    String? email,
    String? phone,
    String? emergencyName,
    String? emergencyPhone,
  }) => UserData(
    id: id ?? this.id,
    userName: userName ?? this.userName,
    childName: childName ?? this.childName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    emergencyName: emergencyName ?? this.emergencyName,
    emergencyPhone: emergencyPhone ?? this.emergencyPhone,
  );
  UserData copyWithCompanion(UserDatasCompanion data) {
    return UserData(
      id: data.id.present ? data.id.value : this.id,
      userName: data.userName.present ? data.userName.value : this.userName,
      childName: data.childName.present ? data.childName.value : this.childName,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      emergencyName:
          data.emergencyName.present
              ? data.emergencyName.value
              : this.emergencyName,
      emergencyPhone:
          data.emergencyPhone.present
              ? data.emergencyPhone.value
              : this.emergencyPhone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserData(')
          ..write('id: $id, ')
          ..write('userName: $userName, ')
          ..write('childName: $childName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('emergencyName: $emergencyName, ')
          ..write('emergencyPhone: $emergencyPhone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userName,
    childName,
    email,
    phone,
    emergencyName,
    emergencyPhone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserData &&
          other.id == this.id &&
          other.userName == this.userName &&
          other.childName == this.childName &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.emergencyName == this.emergencyName &&
          other.emergencyPhone == this.emergencyPhone);
}

class UserDatasCompanion extends UpdateCompanion<UserData> {
  final Value<int> id;
  final Value<String> userName;
  final Value<String> childName;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> emergencyName;
  final Value<String> emergencyPhone;
  const UserDatasCompanion({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.childName = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.emergencyName = const Value.absent(),
    this.emergencyPhone = const Value.absent(),
  });
  UserDatasCompanion.insert({
    this.id = const Value.absent(),
    required String userName,
    required String childName,
    required String email,
    required String phone,
    required String emergencyName,
    required String emergencyPhone,
  }) : userName = Value(userName),
       childName = Value(childName),
       email = Value(email),
       phone = Value(phone),
       emergencyName = Value(emergencyName),
       emergencyPhone = Value(emergencyPhone);
  static Insertable<UserData> custom({
    Expression<int>? id,
    Expression<String>? userName,
    Expression<String>? childName,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? emergencyName,
    Expression<String>? emergencyPhone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userName != null) 'user_name': userName,
      if (childName != null) 'child_name': childName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (emergencyName != null) 'emergency_name': emergencyName,
      if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
    });
  }

  UserDatasCompanion copyWith({
    Value<int>? id,
    Value<String>? userName,
    Value<String>? childName,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? emergencyName,
    Value<String>? emergencyPhone,
  }) {
    return UserDatasCompanion(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      childName: childName ?? this.childName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (childName.present) {
      map['child_name'] = Variable<String>(childName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (emergencyName.present) {
      map['emergency_name'] = Variable<String>(emergencyName.value);
    }
    if (emergencyPhone.present) {
      map['emergency_phone'] = Variable<String>(emergencyPhone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDatasCompanion(')
          ..write('id: $id, ')
          ..write('userName: $userName, ')
          ..write('childName: $childName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('emergencyName: $emergencyName, ')
          ..write('emergencyPhone: $emergencyPhone')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserDatasTable userDatas = $UserDatasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [userDatas];
}

typedef $$UserDatasTableCreateCompanionBuilder =
    UserDatasCompanion Function({
      Value<int> id,
      required String userName,
      required String childName,
      required String email,
      required String phone,
      required String emergencyName,
      required String emergencyPhone,
    });
typedef $$UserDatasTableUpdateCompanionBuilder =
    UserDatasCompanion Function({
      Value<int> id,
      Value<String> userName,
      Value<String> childName,
      Value<String> email,
      Value<String> phone,
      Value<String> emergencyName,
      Value<String> emergencyPhone,
    });

class $$UserDatasTableFilterComposer
    extends Composer<_$AppDatabase, $UserDatasTable> {
  $$UserDatasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childName => $composableBuilder(
    column: $table.childName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyName => $composableBuilder(
    column: $table.emergencyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyPhone => $composableBuilder(
    column: $table.emergencyPhone,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserDatasTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDatasTable> {
  $$UserDatasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userName => $composableBuilder(
    column: $table.userName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childName => $composableBuilder(
    column: $table.childName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyName => $composableBuilder(
    column: $table.emergencyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyPhone => $composableBuilder(
    column: $table.emergencyPhone,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserDatasTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDatasTable> {
  $$UserDatasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get childName =>
      $composableBuilder(column: $table.childName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get emergencyName => $composableBuilder(
    column: $table.emergencyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emergencyPhone => $composableBuilder(
    column: $table.emergencyPhone,
    builder: (column) => column,
  );
}

class $$UserDatasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserDatasTable,
          UserData,
          $$UserDatasTableFilterComposer,
          $$UserDatasTableOrderingComposer,
          $$UserDatasTableAnnotationComposer,
          $$UserDatasTableCreateCompanionBuilder,
          $$UserDatasTableUpdateCompanionBuilder,
          (UserData, BaseReferences<_$AppDatabase, $UserDatasTable, UserData>),
          UserData,
          PrefetchHooks Function()
        > {
  $$UserDatasTableTableManager(_$AppDatabase db, $UserDatasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UserDatasTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UserDatasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UserDatasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userName = const Value.absent(),
                Value<String> childName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> emergencyName = const Value.absent(),
                Value<String> emergencyPhone = const Value.absent(),
              }) => UserDatasCompanion(
                id: id,
                userName: userName,
                childName: childName,
                email: email,
                phone: phone,
                emergencyName: emergencyName,
                emergencyPhone: emergencyPhone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userName,
                required String childName,
                required String email,
                required String phone,
                required String emergencyName,
                required String emergencyPhone,
              }) => UserDatasCompanion.insert(
                id: id,
                userName: userName,
                childName: childName,
                email: email,
                phone: phone,
                emergencyName: emergencyName,
                emergencyPhone: emergencyPhone,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserDatasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserDatasTable,
      UserData,
      $$UserDatasTableFilterComposer,
      $$UserDatasTableOrderingComposer,
      $$UserDatasTableAnnotationComposer,
      $$UserDatasTableCreateCompanionBuilder,
      $$UserDatasTableUpdateCompanionBuilder,
      (UserData, BaseReferences<_$AppDatabase, $UserDatasTable, UserData>),
      UserData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserDatasTableTableManager get userDatas =>
      $$UserDatasTableTableManager(_db, _db.userDatas);
}

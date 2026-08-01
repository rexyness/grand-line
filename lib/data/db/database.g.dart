// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ArcsTable extends Arcs with TableInfo<$ArcsTable, Arc> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArcsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _partMeta = const VerificationMeta('part');
  @override
  late final GeneratedColumn<int> part = GeneratedColumn<int>(
    'part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sagaMeta = const VerificationMeta('saga');
  @override
  late final GeneratedColumn<String> saga = GeneratedColumn<String>(
    'saga',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortcodeMeta = const VerificationMeta(
    'shortcode',
  );
  @override
  late final GeneratedColumn<String> shortcode = GeneratedColumn<String>(
    'shortcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _mkvcodeMeta = const VerificationMeta(
    'mkvcode',
  );
  @override
  late final GeneratedColumn<String> mkvcode = GeneratedColumn<String>(
    'mkvcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta(
    'backdropUrl',
  );
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    part,
    saga,
    title,
    shortcode,
    description,
    mkvcode,
    backdropUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arcs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Arc> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('part')) {
      context.handle(
        _partMeta,
        part.isAcceptableOrUnknown(data['part']!, _partMeta),
      );
    }
    if (data.containsKey('saga')) {
      context.handle(
        _sagaMeta,
        saga.isAcceptableOrUnknown(data['saga']!, _sagaMeta),
      );
    } else if (isInserting) {
      context.missing(_sagaMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('shortcode')) {
      context.handle(
        _shortcodeMeta,
        shortcode.isAcceptableOrUnknown(data['shortcode']!, _shortcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_shortcodeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('mkvcode')) {
      context.handle(
        _mkvcodeMeta,
        mkvcode.isAcceptableOrUnknown(data['mkvcode']!, _mkvcodeMeta),
      );
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
        _backdropUrlMeta,
        backdropUrl.isAcceptableOrUnknown(
          data['backdrop_url']!,
          _backdropUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {part};
  @override
  Arc map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Arc(
      part: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}part'],
      )!,
      saga: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saga'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      shortcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shortcode'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      mkvcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mkvcode'],
      )!,
      backdropUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_url'],
      ),
    );
  }

  @override
  $ArcsTable createAlias(String alias) {
    return $ArcsTable(attachedDatabase, alias);
  }
}

class Arc extends DataClass implements Insertable<Arc> {
  final int part;
  final String saga;
  final String title;
  final String shortcode;
  final String description;
  final String mkvcode;

  /// Filled by catalog sync (spec §10.5); never vendored.
  final String? backdropUrl;
  const Arc({
    required this.part,
    required this.saga,
    required this.title,
    required this.shortcode,
    required this.description,
    required this.mkvcode,
    this.backdropUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['part'] = Variable<int>(part);
    map['saga'] = Variable<String>(saga);
    map['title'] = Variable<String>(title);
    map['shortcode'] = Variable<String>(shortcode);
    map['description'] = Variable<String>(description);
    map['mkvcode'] = Variable<String>(mkvcode);
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    return map;
  }

  ArcsCompanion toCompanion(bool nullToAbsent) {
    return ArcsCompanion(
      part: Value(part),
      saga: Value(saga),
      title: Value(title),
      shortcode: Value(shortcode),
      description: Value(description),
      mkvcode: Value(mkvcode),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
    );
  }

  factory Arc.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Arc(
      part: serializer.fromJson<int>(json['part']),
      saga: serializer.fromJson<String>(json['saga']),
      title: serializer.fromJson<String>(json['title']),
      shortcode: serializer.fromJson<String>(json['shortcode']),
      description: serializer.fromJson<String>(json['description']),
      mkvcode: serializer.fromJson<String>(json['mkvcode']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'part': serializer.toJson<int>(part),
      'saga': serializer.toJson<String>(saga),
      'title': serializer.toJson<String>(title),
      'shortcode': serializer.toJson<String>(shortcode),
      'description': serializer.toJson<String>(description),
      'mkvcode': serializer.toJson<String>(mkvcode),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
    };
  }

  Arc copyWith({
    int? part,
    String? saga,
    String? title,
    String? shortcode,
    String? description,
    String? mkvcode,
    Value<String?> backdropUrl = const Value.absent(),
  }) => Arc(
    part: part ?? this.part,
    saga: saga ?? this.saga,
    title: title ?? this.title,
    shortcode: shortcode ?? this.shortcode,
    description: description ?? this.description,
    mkvcode: mkvcode ?? this.mkvcode,
    backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
  );
  Arc copyWithCompanion(ArcsCompanion data) {
    return Arc(
      part: data.part.present ? data.part.value : this.part,
      saga: data.saga.present ? data.saga.value : this.saga,
      title: data.title.present ? data.title.value : this.title,
      shortcode: data.shortcode.present ? data.shortcode.value : this.shortcode,
      description: data.description.present
          ? data.description.value
          : this.description,
      mkvcode: data.mkvcode.present ? data.mkvcode.value : this.mkvcode,
      backdropUrl: data.backdropUrl.present
          ? data.backdropUrl.value
          : this.backdropUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Arc(')
          ..write('part: $part, ')
          ..write('saga: $saga, ')
          ..write('title: $title, ')
          ..write('shortcode: $shortcode, ')
          ..write('description: $description, ')
          ..write('mkvcode: $mkvcode, ')
          ..write('backdropUrl: $backdropUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    part,
    saga,
    title,
    shortcode,
    description,
    mkvcode,
    backdropUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Arc &&
          other.part == this.part &&
          other.saga == this.saga &&
          other.title == this.title &&
          other.shortcode == this.shortcode &&
          other.description == this.description &&
          other.mkvcode == this.mkvcode &&
          other.backdropUrl == this.backdropUrl);
}

class ArcsCompanion extends UpdateCompanion<Arc> {
  final Value<int> part;
  final Value<String> saga;
  final Value<String> title;
  final Value<String> shortcode;
  final Value<String> description;
  final Value<String> mkvcode;
  final Value<String?> backdropUrl;
  const ArcsCompanion({
    this.part = const Value.absent(),
    this.saga = const Value.absent(),
    this.title = const Value.absent(),
    this.shortcode = const Value.absent(),
    this.description = const Value.absent(),
    this.mkvcode = const Value.absent(),
    this.backdropUrl = const Value.absent(),
  });
  ArcsCompanion.insert({
    this.part = const Value.absent(),
    required String saga,
    required String title,
    required String shortcode,
    this.description = const Value.absent(),
    this.mkvcode = const Value.absent(),
    this.backdropUrl = const Value.absent(),
  }) : saga = Value(saga),
       title = Value(title),
       shortcode = Value(shortcode);
  static Insertable<Arc> custom({
    Expression<int>? part,
    Expression<String>? saga,
    Expression<String>? title,
    Expression<String>? shortcode,
    Expression<String>? description,
    Expression<String>? mkvcode,
    Expression<String>? backdropUrl,
  }) {
    return RawValuesInsertable({
      if (part != null) 'part': part,
      if (saga != null) 'saga': saga,
      if (title != null) 'title': title,
      if (shortcode != null) 'shortcode': shortcode,
      if (description != null) 'description': description,
      if (mkvcode != null) 'mkvcode': mkvcode,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
    });
  }

  ArcsCompanion copyWith({
    Value<int>? part,
    Value<String>? saga,
    Value<String>? title,
    Value<String>? shortcode,
    Value<String>? description,
    Value<String>? mkvcode,
    Value<String?>? backdropUrl,
  }) {
    return ArcsCompanion(
      part: part ?? this.part,
      saga: saga ?? this.saga,
      title: title ?? this.title,
      shortcode: shortcode ?? this.shortcode,
      description: description ?? this.description,
      mkvcode: mkvcode ?? this.mkvcode,
      backdropUrl: backdropUrl ?? this.backdropUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (part.present) {
      map['part'] = Variable<int>(part.value);
    }
    if (saga.present) {
      map['saga'] = Variable<String>(saga.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (shortcode.present) {
      map['shortcode'] = Variable<String>(shortcode.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (mkvcode.present) {
      map['mkvcode'] = Variable<String>(mkvcode.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArcsCompanion(')
          ..write('part: $part, ')
          ..write('saga: $saga, ')
          ..write('title: $title, ')
          ..write('shortcode: $shortcode, ')
          ..write('description: $description, ')
          ..write('mkvcode: $mkvcode, ')
          ..write('backdropUrl: $backdropUrl')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _arcPartMeta = const VerificationMeta(
    'arcPart',
  );
  @override
  late final GeneratedColumn<int> arcPart = GeneratedColumn<int>(
    'arc_part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES arcs (part)',
    ),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mangaChaptersMeta = const VerificationMeta(
    'mangaChapters',
  );
  @override
  late final GeneratedColumn<String> mangaChapters = GeneratedColumn<String>(
    'manga_chapters',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _animeEpisodesMeta = const VerificationMeta(
    'animeEpisodes',
  );
  @override
  late final GeneratedColumn<String> animeEpisodes = GeneratedColumn<String>(
    'anime_episodes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releasedMeta = const VerificationMeta(
    'released',
  );
  @override
  late final GeneratedColumn<DateTime> released = GeneratedColumn<DateTime>(
    'released',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    arcPart,
    number,
    title,
    mangaChapters,
    animeEpisodes,
    released,
    durationSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('arc_part')) {
      context.handle(
        _arcPartMeta,
        arcPart.isAcceptableOrUnknown(data['arc_part']!, _arcPartMeta),
      );
    } else if (isInserting) {
      context.missing(_arcPartMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('manga_chapters')) {
      context.handle(
        _mangaChaptersMeta,
        mangaChapters.isAcceptableOrUnknown(
          data['manga_chapters']!,
          _mangaChaptersMeta,
        ),
      );
    }
    if (data.containsKey('anime_episodes')) {
      context.handle(
        _animeEpisodesMeta,
        animeEpisodes.isAcceptableOrUnknown(
          data['anime_episodes']!,
          _animeEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('released')) {
      context.handle(
        _releasedMeta,
        released.isAcceptableOrUnknown(data['released']!, _releasedMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {arcPart, number};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      arcPart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arc_part'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      mangaChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manga_chapters'],
      ),
      animeEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_episodes'],
      ),
      released: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}released'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int arcPart;
  final int number;
  final String? title;
  final String? mangaChapters;
  final String? animeEpisodes;
  final DateTime? released;
  final int? durationSeconds;
  const Episode({
    required this.arcPart,
    required this.number,
    this.title,
    this.mangaChapters,
    this.animeEpisodes,
    this.released,
    this.durationSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['arc_part'] = Variable<int>(arcPart);
    map['number'] = Variable<int>(number);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || mangaChapters != null) {
      map['manga_chapters'] = Variable<String>(mangaChapters);
    }
    if (!nullToAbsent || animeEpisodes != null) {
      map['anime_episodes'] = Variable<String>(animeEpisodes);
    }
    if (!nullToAbsent || released != null) {
      map['released'] = Variable<DateTime>(released);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      arcPart: Value(arcPart),
      number: Value(number),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      mangaChapters: mangaChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(mangaChapters),
      animeEpisodes: animeEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(animeEpisodes),
      released: released == null && nullToAbsent
          ? const Value.absent()
          : Value(released),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
    );
  }

  factory Episode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      arcPart: serializer.fromJson<int>(json['arcPart']),
      number: serializer.fromJson<int>(json['number']),
      title: serializer.fromJson<String?>(json['title']),
      mangaChapters: serializer.fromJson<String?>(json['mangaChapters']),
      animeEpisodes: serializer.fromJson<String?>(json['animeEpisodes']),
      released: serializer.fromJson<DateTime?>(json['released']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'arcPart': serializer.toJson<int>(arcPart),
      'number': serializer.toJson<int>(number),
      'title': serializer.toJson<String?>(title),
      'mangaChapters': serializer.toJson<String?>(mangaChapters),
      'animeEpisodes': serializer.toJson<String?>(animeEpisodes),
      'released': serializer.toJson<DateTime?>(released),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
    };
  }

  Episode copyWith({
    int? arcPart,
    int? number,
    Value<String?> title = const Value.absent(),
    Value<String?> mangaChapters = const Value.absent(),
    Value<String?> animeEpisodes = const Value.absent(),
    Value<DateTime?> released = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
  }) => Episode(
    arcPart: arcPart ?? this.arcPart,
    number: number ?? this.number,
    title: title.present ? title.value : this.title,
    mangaChapters: mangaChapters.present
        ? mangaChapters.value
        : this.mangaChapters,
    animeEpisodes: animeEpisodes.present
        ? animeEpisodes.value
        : this.animeEpisodes,
    released: released.present ? released.value : this.released,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
  );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      arcPart: data.arcPart.present ? data.arcPart.value : this.arcPart,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      mangaChapters: data.mangaChapters.present
          ? data.mangaChapters.value
          : this.mangaChapters,
      animeEpisodes: data.animeEpisodes.present
          ? data.animeEpisodes.value
          : this.animeEpisodes,
      released: data.released.present ? data.released.value : this.released,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('mangaChapters: $mangaChapters, ')
          ..write('animeEpisodes: $animeEpisodes, ')
          ..write('released: $released, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    arcPart,
    number,
    title,
    mangaChapters,
    animeEpisodes,
    released,
    durationSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.arcPart == this.arcPart &&
          other.number == this.number &&
          other.title == this.title &&
          other.mangaChapters == this.mangaChapters &&
          other.animeEpisodes == this.animeEpisodes &&
          other.released == this.released &&
          other.durationSeconds == this.durationSeconds);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> arcPart;
  final Value<int> number;
  final Value<String?> title;
  final Value<String?> mangaChapters;
  final Value<String?> animeEpisodes;
  final Value<DateTime?> released;
  final Value<int?> durationSeconds;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.arcPart = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.mangaChapters = const Value.absent(),
    this.animeEpisodes = const Value.absent(),
    this.released = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required int arcPart,
    required int number,
    this.title = const Value.absent(),
    this.mangaChapters = const Value.absent(),
    this.animeEpisodes = const Value.absent(),
    this.released = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : arcPart = Value(arcPart),
       number = Value(number);
  static Insertable<Episode> custom({
    Expression<int>? arcPart,
    Expression<int>? number,
    Expression<String>? title,
    Expression<String>? mangaChapters,
    Expression<String>? animeEpisodes,
    Expression<DateTime>? released,
    Expression<int>? durationSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (arcPart != null) 'arc_part': arcPart,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (mangaChapters != null) 'manga_chapters': mangaChapters,
      if (animeEpisodes != null) 'anime_episodes': animeEpisodes,
      if (released != null) 'released': released,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<int>? arcPart,
    Value<int>? number,
    Value<String?>? title,
    Value<String?>? mangaChapters,
    Value<String?>? animeEpisodes,
    Value<DateTime?>? released,
    Value<int?>? durationSeconds,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      arcPart: arcPart ?? this.arcPart,
      number: number ?? this.number,
      title: title ?? this.title,
      mangaChapters: mangaChapters ?? this.mangaChapters,
      animeEpisodes: animeEpisodes ?? this.animeEpisodes,
      released: released ?? this.released,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (arcPart.present) {
      map['arc_part'] = Variable<int>(arcPart.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mangaChapters.present) {
      map['manga_chapters'] = Variable<String>(mangaChapters.value);
    }
    if (animeEpisodes.present) {
      map['anime_episodes'] = Variable<String>(animeEpisodes.value);
    }
    if (released.present) {
      map['released'] = Variable<DateTime>(released.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('mangaChapters: $mangaChapters, ')
          ..write('animeEpisodes: $animeEpisodes, ')
          ..write('released: $released, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _arcPartMeta = const VerificationMeta(
    'arcPart',
  );
  @override
  late final GeneratedColumn<int> arcPart = GeneratedColumn<int>(
    'arc_part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantMeta = const VerificationMeta(
    'variant',
  );
  @override
  late final GeneratedColumn<String> variant = GeneratedColumn<String>(
    'variant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pixeldrainIdMeta = const VerificationMeta(
    'pixeldrainId',
  );
  @override
  late final GeneratedColumn<String> pixeldrainId = GeneratedColumn<String>(
    'pixeldrain_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crc32Meta = const VerificationMeta('crc32');
  @override
  late final GeneratedColumn<String> crc32 = GeneratedColumn<String>(
    'crc32',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    arcPart,
    number,
    kind,
    variant,
    quality,
    pixeldrainId,
    crc32,
    fileName,
    sizeBytes,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('arc_part')) {
      context.handle(
        _arcPartMeta,
        arcPart.isAcceptableOrUnknown(data['arc_part']!, _arcPartMeta),
      );
    } else if (isInserting) {
      context.missing(_arcPartMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('variant')) {
      context.handle(
        _variantMeta,
        variant.isAcceptableOrUnknown(data['variant']!, _variantMeta),
      );
    } else if (isInserting) {
      context.missing(_variantMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('pixeldrain_id')) {
      context.handle(
        _pixeldrainIdMeta,
        pixeldrainId.isAcceptableOrUnknown(
          data['pixeldrain_id']!,
          _pixeldrainIdMeta,
        ),
      );
    }
    if (data.containsKey('crc32')) {
      context.handle(
        _crc32Meta,
        crc32.isAcceptableOrUnknown(data['crc32']!, _crc32Meta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {arcPart, number, kind, variant, quality},
  ];
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      arcPart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arc_part'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      variant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quality'],
      )!,
      pixeldrainId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pixeldrain_id'],
      ),
      crc32: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crc32'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends DataClass implements Insertable<Source> {
  final int id;
  final int arcPart;
  final int number;
  final String kind;
  final String variant;

  /// 480/720/1080 for streams; 0 (n/a) for downloads. Non-null so the
  /// uniqueness constraint holds (SQLite treats NULLs as distinct).
  final int quality;
  final String? pixeldrainId;
  final String? crc32;
  final String? fileName;
  final int? sizeBytes;
  final int updatedAtMs;
  const Source({
    required this.id,
    required this.arcPart,
    required this.number,
    required this.kind,
    required this.variant,
    required this.quality,
    this.pixeldrainId,
    this.crc32,
    this.fileName,
    this.sizeBytes,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['arc_part'] = Variable<int>(arcPart);
    map['number'] = Variable<int>(number);
    map['kind'] = Variable<String>(kind);
    map['variant'] = Variable<String>(variant);
    map['quality'] = Variable<int>(quality);
    if (!nullToAbsent || pixeldrainId != null) {
      map['pixeldrain_id'] = Variable<String>(pixeldrainId);
    }
    if (!nullToAbsent || crc32 != null) {
      map['crc32'] = Variable<String>(crc32);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      arcPart: Value(arcPart),
      number: Value(number),
      kind: Value(kind),
      variant: Value(variant),
      quality: Value(quality),
      pixeldrainId: pixeldrainId == null && nullToAbsent
          ? const Value.absent()
          : Value(pixeldrainId),
      crc32: crc32 == null && nullToAbsent
          ? const Value.absent()
          : Value(crc32),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<int>(json['id']),
      arcPart: serializer.fromJson<int>(json['arcPart']),
      number: serializer.fromJson<int>(json['number']),
      kind: serializer.fromJson<String>(json['kind']),
      variant: serializer.fromJson<String>(json['variant']),
      quality: serializer.fromJson<int>(json['quality']),
      pixeldrainId: serializer.fromJson<String?>(json['pixeldrainId']),
      crc32: serializer.fromJson<String?>(json['crc32']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'arcPart': serializer.toJson<int>(arcPart),
      'number': serializer.toJson<int>(number),
      'kind': serializer.toJson<String>(kind),
      'variant': serializer.toJson<String>(variant),
      'quality': serializer.toJson<int>(quality),
      'pixeldrainId': serializer.toJson<String?>(pixeldrainId),
      'crc32': serializer.toJson<String?>(crc32),
      'fileName': serializer.toJson<String?>(fileName),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  Source copyWith({
    int? id,
    int? arcPart,
    int? number,
    String? kind,
    String? variant,
    int? quality,
    Value<String?> pixeldrainId = const Value.absent(),
    Value<String?> crc32 = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    int? updatedAtMs,
  }) => Source(
    id: id ?? this.id,
    arcPart: arcPart ?? this.arcPart,
    number: number ?? this.number,
    kind: kind ?? this.kind,
    variant: variant ?? this.variant,
    quality: quality ?? this.quality,
    pixeldrainId: pixeldrainId.present ? pixeldrainId.value : this.pixeldrainId,
    crc32: crc32.present ? crc32.value : this.crc32,
    fileName: fileName.present ? fileName.value : this.fileName,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      arcPart: data.arcPart.present ? data.arcPart.value : this.arcPart,
      number: data.number.present ? data.number.value : this.number,
      kind: data.kind.present ? data.kind.value : this.kind,
      variant: data.variant.present ? data.variant.value : this.variant,
      quality: data.quality.present ? data.quality.value : this.quality,
      pixeldrainId: data.pixeldrainId.present
          ? data.pixeldrainId.value
          : this.pixeldrainId,
      crc32: data.crc32.present ? data.crc32.value : this.crc32,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('kind: $kind, ')
          ..write('variant: $variant, ')
          ..write('quality: $quality, ')
          ..write('pixeldrainId: $pixeldrainId, ')
          ..write('crc32: $crc32, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    arcPart,
    number,
    kind,
    variant,
    quality,
    pixeldrainId,
    crc32,
    fileName,
    sizeBytes,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.arcPart == this.arcPart &&
          other.number == this.number &&
          other.kind == this.kind &&
          other.variant == this.variant &&
          other.quality == this.quality &&
          other.pixeldrainId == this.pixeldrainId &&
          other.crc32 == this.crc32 &&
          other.fileName == this.fileName &&
          other.sizeBytes == this.sizeBytes &&
          other.updatedAtMs == this.updatedAtMs);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<int> id;
  final Value<int> arcPart;
  final Value<int> number;
  final Value<String> kind;
  final Value<String> variant;
  final Value<int> quality;
  final Value<String?> pixeldrainId;
  final Value<String?> crc32;
  final Value<String?> fileName;
  final Value<int?> sizeBytes;
  final Value<int> updatedAtMs;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.arcPart = const Value.absent(),
    this.number = const Value.absent(),
    this.kind = const Value.absent(),
    this.variant = const Value.absent(),
    this.quality = const Value.absent(),
    this.pixeldrainId = const Value.absent(),
    this.crc32 = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    required int arcPart,
    required int number,
    required String kind,
    required String variant,
    this.quality = const Value.absent(),
    this.pixeldrainId = const Value.absent(),
    this.crc32 = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  }) : arcPart = Value(arcPart),
       number = Value(number),
       kind = Value(kind),
       variant = Value(variant);
  static Insertable<Source> custom({
    Expression<int>? id,
    Expression<int>? arcPart,
    Expression<int>? number,
    Expression<String>? kind,
    Expression<String>? variant,
    Expression<int>? quality,
    Expression<String>? pixeldrainId,
    Expression<String>? crc32,
    Expression<String>? fileName,
    Expression<int>? sizeBytes,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (arcPart != null) 'arc_part': arcPart,
      if (number != null) 'number': number,
      if (kind != null) 'kind': kind,
      if (variant != null) 'variant': variant,
      if (quality != null) 'quality': quality,
      if (pixeldrainId != null) 'pixeldrain_id': pixeldrainId,
      if (crc32 != null) 'crc32': crc32,
      if (fileName != null) 'file_name': fileName,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<int>? arcPart,
    Value<int>? number,
    Value<String>? kind,
    Value<String>? variant,
    Value<int>? quality,
    Value<String?>? pixeldrainId,
    Value<String?>? crc32,
    Value<String?>? fileName,
    Value<int?>? sizeBytes,
    Value<int>? updatedAtMs,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      arcPart: arcPart ?? this.arcPart,
      number: number ?? this.number,
      kind: kind ?? this.kind,
      variant: variant ?? this.variant,
      quality: quality ?? this.quality,
      pixeldrainId: pixeldrainId ?? this.pixeldrainId,
      crc32: crc32 ?? this.crc32,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (arcPart.present) {
      map['arc_part'] = Variable<int>(arcPart.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (variant.present) {
      map['variant'] = Variable<String>(variant.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (pixeldrainId.present) {
      map['pixeldrain_id'] = Variable<String>(pixeldrainId.value);
    }
    if (crc32.present) {
      map['crc32'] = Variable<String>(crc32.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('kind: $kind, ')
          ..write('variant: $variant, ')
          ..write('quality: $quality, ')
          ..write('pixeldrainId: $pixeldrainId, ')
          ..write('crc32: $crc32, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

class $ProgressEntriesTable extends ProgressEntries
    with TableInfo<$ProgressEntriesTable, ProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _arcPartMeta = const VerificationMeta(
    'arcPart',
  );
  @override
  late final GeneratedColumn<int> arcPart = GeneratedColumn<int>(
    'arc_part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _watchedMeta = const VerificationMeta(
    'watched',
  );
  @override
  late final GeneratedColumn<bool> watched = GeneratedColumn<bool>(
    'watched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("watched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    arcPart,
    number,
    positionMs,
    watched,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('arc_part')) {
      context.handle(
        _arcPartMeta,
        arcPart.isAcceptableOrUnknown(data['arc_part']!, _arcPartMeta),
      );
    } else if (isInserting) {
      context.missing(_arcPartMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('watched')) {
      context.handle(
        _watchedMeta,
        watched.isAcceptableOrUnknown(data['watched']!, _watchedMeta),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {arcPart, number};
  @override
  ProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressEntry(
      arcPart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arc_part'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      watched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}watched'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $ProgressEntriesTable createAlias(String alias) {
    return $ProgressEntriesTable(attachedDatabase, alias);
  }
}

class ProgressEntry extends DataClass implements Insertable<ProgressEntry> {
  final int arcPart;
  final int number;
  final int positionMs;
  final bool watched;
  final int updatedAtMs;
  const ProgressEntry({
    required this.arcPart,
    required this.number,
    required this.positionMs,
    required this.watched,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['arc_part'] = Variable<int>(arcPart);
    map['number'] = Variable<int>(number);
    map['position_ms'] = Variable<int>(positionMs);
    map['watched'] = Variable<bool>(watched);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  ProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProgressEntriesCompanion(
      arcPart: Value(arcPart),
      number: Value(number),
      positionMs: Value(positionMs),
      watched: Value(watched),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory ProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressEntry(
      arcPart: serializer.fromJson<int>(json['arcPart']),
      number: serializer.fromJson<int>(json['number']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      watched: serializer.fromJson<bool>(json['watched']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'arcPart': serializer.toJson<int>(arcPart),
      'number': serializer.toJson<int>(number),
      'positionMs': serializer.toJson<int>(positionMs),
      'watched': serializer.toJson<bool>(watched),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  ProgressEntry copyWith({
    int? arcPart,
    int? number,
    int? positionMs,
    bool? watched,
    int? updatedAtMs,
  }) => ProgressEntry(
    arcPart: arcPart ?? this.arcPart,
    number: number ?? this.number,
    positionMs: positionMs ?? this.positionMs,
    watched: watched ?? this.watched,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  ProgressEntry copyWithCompanion(ProgressEntriesCompanion data) {
    return ProgressEntry(
      arcPart: data.arcPart.present ? data.arcPart.value : this.arcPart,
      number: data.number.present ? data.number.value : this.number,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      watched: data.watched.present ? data.watched.value : this.watched,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntry(')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('positionMs: $positionMs, ')
          ..write('watched: $watched, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(arcPart, number, positionMs, watched, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressEntry &&
          other.arcPart == this.arcPart &&
          other.number == this.number &&
          other.positionMs == this.positionMs &&
          other.watched == this.watched &&
          other.updatedAtMs == this.updatedAtMs);
}

class ProgressEntriesCompanion extends UpdateCompanion<ProgressEntry> {
  final Value<int> arcPart;
  final Value<int> number;
  final Value<int> positionMs;
  final Value<bool> watched;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const ProgressEntriesCompanion({
    this.arcPart = const Value.absent(),
    this.number = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.watched = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressEntriesCompanion.insert({
    required int arcPart,
    required int number,
    this.positionMs = const Value.absent(),
    this.watched = const Value.absent(),
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : arcPart = Value(arcPart),
       number = Value(number),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<ProgressEntry> custom({
    Expression<int>? arcPart,
    Expression<int>? number,
    Expression<int>? positionMs,
    Expression<bool>? watched,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (arcPart != null) 'arc_part': arcPart,
      if (number != null) 'number': number,
      if (positionMs != null) 'position_ms': positionMs,
      if (watched != null) 'watched': watched,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressEntriesCompanion copyWith({
    Value<int>? arcPart,
    Value<int>? number,
    Value<int>? positionMs,
    Value<bool>? watched,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return ProgressEntriesCompanion(
      arcPart: arcPart ?? this.arcPart,
      number: number ?? this.number,
      positionMs: positionMs ?? this.positionMs,
      watched: watched ?? this.watched,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (arcPart.present) {
      map['arc_part'] = Variable<int>(arcPart.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (watched.present) {
      map['watched'] = Variable<bool>(watched.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntriesCompanion(')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('positionMs: $positionMs, ')
          ..write('watched: $watched, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadEntriesTable extends DownloadEntries
    with TableInfo<$DownloadEntriesTable, DownloadEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _arcPartMeta = const VerificationMeta(
    'arcPart',
  );
  @override
  late final GeneratedColumn<int> arcPart = GeneratedColumn<int>(
    'arc_part',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    arcPart,
    number,
    sourceId,
    taskId,
    status,
    filePath,
    sizeBytes,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('arc_part')) {
      context.handle(
        _arcPartMeta,
        arcPart.isAcceptableOrUnknown(data['arc_part']!, _arcPartMeta),
      );
    } else if (isInserting) {
      context.missing(_arcPartMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {arcPart, number};
  @override
  DownloadEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadEntry(
      arcPart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}arc_part'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  $DownloadEntriesTable createAlias(String alias) {
    return $DownloadEntriesTable(attachedDatabase, alias);
  }
}

class DownloadEntry extends DataClass implements Insertable<DownloadEntry> {
  final int arcPart;
  final int number;
  final int? sourceId;
  final String? taskId;

  /// queued | running | paused | complete | failed
  final String status;
  final String? filePath;
  final int? sizeBytes;
  final int updatedAtMs;
  const DownloadEntry({
    required this.arcPart,
    required this.number,
    this.sourceId,
    this.taskId,
    required this.status,
    this.filePath,
    this.sizeBytes,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['arc_part'] = Variable<int>(arcPart);
    map['number'] = Variable<int>(number);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<int>(sourceId);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  DownloadEntriesCompanion toCompanion(bool nullToAbsent) {
    return DownloadEntriesCompanion(
      arcPart: Value(arcPart),
      number: Value(number),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      status: Value(status),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory DownloadEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadEntry(
      arcPart: serializer.fromJson<int>(json['arcPart']),
      number: serializer.fromJson<int>(json['number']),
      sourceId: serializer.fromJson<int?>(json['sourceId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      status: serializer.fromJson<String>(json['status']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'arcPart': serializer.toJson<int>(arcPart),
      'number': serializer.toJson<int>(number),
      'sourceId': serializer.toJson<int?>(sourceId),
      'taskId': serializer.toJson<String?>(taskId),
      'status': serializer.toJson<String>(status),
      'filePath': serializer.toJson<String?>(filePath),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  DownloadEntry copyWith({
    int? arcPart,
    int? number,
    Value<int?> sourceId = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    String? status,
    Value<String?> filePath = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    int? updatedAtMs,
  }) => DownloadEntry(
    arcPart: arcPart ?? this.arcPart,
    number: number ?? this.number,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    taskId: taskId.present ? taskId.value : this.taskId,
    status: status ?? this.status,
    filePath: filePath.present ? filePath.value : this.filePath,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  DownloadEntry copyWithCompanion(DownloadEntriesCompanion data) {
    return DownloadEntry(
      arcPart: data.arcPart.present ? data.arcPart.value : this.arcPart,
      number: data.number.present ? data.number.value : this.number,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      status: data.status.present ? data.status.value : this.status,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadEntry(')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('sourceId: $sourceId, ')
          ..write('taskId: $taskId, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    arcPart,
    number,
    sourceId,
    taskId,
    status,
    filePath,
    sizeBytes,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadEntry &&
          other.arcPart == this.arcPart &&
          other.number == this.number &&
          other.sourceId == this.sourceId &&
          other.taskId == this.taskId &&
          other.status == this.status &&
          other.filePath == this.filePath &&
          other.sizeBytes == this.sizeBytes &&
          other.updatedAtMs == this.updatedAtMs);
}

class DownloadEntriesCompanion extends UpdateCompanion<DownloadEntry> {
  final Value<int> arcPart;
  final Value<int> number;
  final Value<int?> sourceId;
  final Value<String?> taskId;
  final Value<String> status;
  final Value<String?> filePath;
  final Value<int?> sizeBytes;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const DownloadEntriesCompanion({
    this.arcPart = const Value.absent(),
    this.number = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadEntriesCompanion.insert({
    required int arcPart,
    required int number,
    this.sourceId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : arcPart = Value(arcPart),
       number = Value(number),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<DownloadEntry> custom({
    Expression<int>? arcPart,
    Expression<int>? number,
    Expression<int>? sourceId,
    Expression<String>? taskId,
    Expression<String>? status,
    Expression<String>? filePath,
    Expression<int>? sizeBytes,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (arcPart != null) 'arc_part': arcPart,
      if (number != null) 'number': number,
      if (sourceId != null) 'source_id': sourceId,
      if (taskId != null) 'task_id': taskId,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadEntriesCompanion copyWith({
    Value<int>? arcPart,
    Value<int>? number,
    Value<int?>? sourceId,
    Value<String?>? taskId,
    Value<String>? status,
    Value<String?>? filePath,
    Value<int?>? sizeBytes,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return DownloadEntriesCompanion(
      arcPart: arcPart ?? this.arcPart,
      number: number ?? this.number,
      sourceId: sourceId ?? this.sourceId,
      taskId: taskId ?? this.taskId,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (arcPart.present) {
      map['arc_part'] = Variable<int>(arcPart.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadEntriesCompanion(')
          ..write('arcPart: $arcPart, ')
          ..write('number: $number, ')
          ..write('sourceId: $sourceId, ')
          ..write('taskId: $taskId, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArcsTable arcs = $ArcsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $ProgressEntriesTable progressEntries = $ProgressEntriesTable(
    this,
  );
  late final $DownloadEntriesTable downloadEntries = $DownloadEntriesTable(
    this,
  );
  late final CatalogDao catalogDao = CatalogDao(this as AppDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  late final DownloadsDao downloadsDao = DownloadsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    arcs,
    episodes,
    sources,
    progressEntries,
    downloadEntries,
  ];
}

typedef $$ArcsTableCreateCompanionBuilder =
    ArcsCompanion Function({
      Value<int> part,
      required String saga,
      required String title,
      required String shortcode,
      Value<String> description,
      Value<String> mkvcode,
      Value<String?> backdropUrl,
    });
typedef $$ArcsTableUpdateCompanionBuilder =
    ArcsCompanion Function({
      Value<int> part,
      Value<String> saga,
      Value<String> title,
      Value<String> shortcode,
      Value<String> description,
      Value<String> mkvcode,
      Value<String?> backdropUrl,
    });

final class $$ArcsTableReferences
    extends BaseReferences<_$AppDatabase, $ArcsTable, Arc> {
  $$ArcsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(db.arcs.part, db.episodes.arcPart),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.arcPart.part.sqlEquals($_itemColumn<int>('part')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ArcsTableFilterComposer extends Composer<_$AppDatabase, $ArcsTable> {
  $$ArcsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saga => $composableBuilder(
    column: $table.saga,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortcode => $composableBuilder(
    column: $table.shortcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mkvcode => $composableBuilder(
    column: $table.mkvcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.part,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.arcPart,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArcsTableOrderingComposer extends Composer<_$AppDatabase, $ArcsTable> {
  $$ArcsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get part => $composableBuilder(
    column: $table.part,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saga => $composableBuilder(
    column: $table.saga,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortcode => $composableBuilder(
    column: $table.shortcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mkvcode => $composableBuilder(
    column: $table.mkvcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArcsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArcsTable> {
  $$ArcsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get part =>
      $composableBuilder(column: $table.part, builder: (column) => column);

  GeneratedColumn<String> get saga =>
      $composableBuilder(column: $table.saga, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get shortcode =>
      $composableBuilder(column: $table.shortcode, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mkvcode =>
      $composableBuilder(column: $table.mkvcode, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => column,
  );

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.part,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.arcPart,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ArcsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArcsTable,
          Arc,
          $$ArcsTableFilterComposer,
          $$ArcsTableOrderingComposer,
          $$ArcsTableAnnotationComposer,
          $$ArcsTableCreateCompanionBuilder,
          $$ArcsTableUpdateCompanionBuilder,
          (Arc, $$ArcsTableReferences),
          Arc,
          PrefetchHooks Function({bool episodesRefs})
        > {
  $$ArcsTableTableManager(_$AppDatabase db, $ArcsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArcsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArcsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArcsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> part = const Value.absent(),
                Value<String> saga = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> shortcode = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> mkvcode = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
              }) => ArcsCompanion(
                part: part,
                saga: saga,
                title: title,
                shortcode: shortcode,
                description: description,
                mkvcode: mkvcode,
                backdropUrl: backdropUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> part = const Value.absent(),
                required String saga,
                required String title,
                required String shortcode,
                Value<String> description = const Value.absent(),
                Value<String> mkvcode = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
              }) => ArcsCompanion.insert(
                part: part,
                saga: saga,
                title: title,
                shortcode: shortcode,
                description: description,
                mkvcode: mkvcode,
                backdropUrl: backdropUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ArcsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({episodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (episodesRefs) db.episodes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (episodesRefs)
                    await $_getPrefetchedData<Arc, $ArcsTable, Episode>(
                      currentTable: table,
                      referencedTable: $$ArcsTableReferences._episodesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$ArcsTableReferences(db, table, p0).episodesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.arcPart == item.part),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ArcsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArcsTable,
      Arc,
      $$ArcsTableFilterComposer,
      $$ArcsTableOrderingComposer,
      $$ArcsTableAnnotationComposer,
      $$ArcsTableCreateCompanionBuilder,
      $$ArcsTableUpdateCompanionBuilder,
      (Arc, $$ArcsTableReferences),
      Arc,
      PrefetchHooks Function({bool episodesRefs})
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      required int arcPart,
      required int number,
      Value<String?> title,
      Value<String?> mangaChapters,
      Value<String?> animeEpisodes,
      Value<DateTime?> released,
      Value<int?> durationSeconds,
      Value<int> rowid,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> arcPart,
      Value<int> number,
      Value<String?> title,
      Value<String?> mangaChapters,
      Value<String?> animeEpisodes,
      Value<DateTime?> released,
      Value<int?> durationSeconds,
      Value<int> rowid,
    });

final class $$EpisodesTableReferences
    extends BaseReferences<_$AppDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ArcsTable _arcPartTable(_$AppDatabase db) => db.arcs.createAlias(
    $_aliasNameGenerator(db.episodes.arcPart, db.arcs.part),
  );

  $$ArcsTableProcessedTableManager get arcPart {
    final $_column = $_itemColumn<int>('arc_part')!;

    final manager = $$ArcsTableTableManager(
      $_db,
      $_db.arcs,
    ).filter((f) => f.part.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_arcPartTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mangaChapters => $composableBuilder(
    column: $table.mangaChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animeEpisodes => $composableBuilder(
    column: $table.animeEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get released => $composableBuilder(
    column: $table.released,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  $$ArcsTableFilterComposer get arcPart {
    final $$ArcsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arcPart,
      referencedTable: $db.arcs,
      getReferencedColumn: (t) => t.part,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArcsTableFilterComposer(
            $db: $db,
            $table: $db.arcs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mangaChapters => $composableBuilder(
    column: $table.mangaChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animeEpisodes => $composableBuilder(
    column: $table.animeEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get released => $composableBuilder(
    column: $table.released,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  $$ArcsTableOrderingComposer get arcPart {
    final $$ArcsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arcPart,
      referencedTable: $db.arcs,
      getReferencedColumn: (t) => t.part,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArcsTableOrderingComposer(
            $db: $db,
            $table: $db.arcs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get mangaChapters => $composableBuilder(
    column: $table.mangaChapters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get animeEpisodes => $composableBuilder(
    column: $table.animeEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get released =>
      $composableBuilder(column: $table.released, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  $$ArcsTableAnnotationComposer get arcPart {
    final $$ArcsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.arcPart,
      referencedTable: $db.arcs,
      getReferencedColumn: (t) => t.part,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ArcsTableAnnotationComposer(
            $db: $db,
            $table: $db.arcs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, $$EpisodesTableReferences),
          Episode,
          PrefetchHooks Function({bool arcPart})
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> arcPart = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> mangaChapters = const Value.absent(),
                Value<String?> animeEpisodes = const Value.absent(),
                Value<DateTime?> released = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                arcPart: arcPart,
                number: number,
                title: title,
                mangaChapters: mangaChapters,
                animeEpisodes: animeEpisodes,
                released: released,
                durationSeconds: durationSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int arcPart,
                required int number,
                Value<String?> title = const Value.absent(),
                Value<String?> mangaChapters = const Value.absent(),
                Value<String?> animeEpisodes = const Value.absent(),
                Value<DateTime?> released = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                arcPart: arcPart,
                number: number,
                title: title,
                mangaChapters: mangaChapters,
                animeEpisodes: animeEpisodes,
                released: released,
                durationSeconds: durationSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({arcPart = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (arcPart) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.arcPart,
                                referencedTable: $$EpisodesTableReferences
                                    ._arcPartTable(db),
                                referencedColumn: $$EpisodesTableReferences
                                    ._arcPartTable(db)
                                    .part,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, $$EpisodesTableReferences),
      Episode,
      PrefetchHooks Function({bool arcPart})
    >;
typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      required int arcPart,
      required int number,
      required String kind,
      required String variant,
      Value<int> quality,
      Value<String?> pixeldrainId,
      Value<String?> crc32,
      Value<String?> fileName,
      Value<int?> sizeBytes,
      Value<int> updatedAtMs,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      Value<int> arcPart,
      Value<int> number,
      Value<String> kind,
      Value<String> variant,
      Value<int> quality,
      Value<String?> pixeldrainId,
      Value<String?> crc32,
      Value<String?> fileName,
      Value<int?> sizeBytes,
      Value<int> updatedAtMs,
    });

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
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

  ColumnFilters<int> get arcPart => $composableBuilder(
    column: $table.arcPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pixeldrainId => $composableBuilder(
    column: $table.pixeldrainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crc32 => $composableBuilder(
    column: $table.crc32,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
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

  ColumnOrderings<int> get arcPart => $composableBuilder(
    column: $table.arcPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variant => $composableBuilder(
    column: $table.variant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pixeldrainId => $composableBuilder(
    column: $table.pixeldrainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crc32 => $composableBuilder(
    column: $table.crc32,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get arcPart =>
      $composableBuilder(column: $table.arcPart, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get variant =>
      $composableBuilder(column: $table.variant, builder: (column) => column);

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get pixeldrainId => $composableBuilder(
    column: $table.pixeldrainId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get crc32 =>
      $composableBuilder(column: $table.crc32, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, BaseReferences<_$AppDatabase, $SourcesTable, Source>),
          Source,
          PrefetchHooks Function()
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> arcPart = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> variant = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<String?> pixeldrainId = const Value.absent(),
                Value<String?> crc32 = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                arcPart: arcPart,
                number: number,
                kind: kind,
                variant: variant,
                quality: quality,
                pixeldrainId: pixeldrainId,
                crc32: crc32,
                fileName: fileName,
                sizeBytes: sizeBytes,
                updatedAtMs: updatedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int arcPart,
                required int number,
                required String kind,
                required String variant,
                Value<int> quality = const Value.absent(),
                Value<String?> pixeldrainId = const Value.absent(),
                Value<String?> crc32 = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                arcPart: arcPart,
                number: number,
                kind: kind,
                variant: variant,
                quality: quality,
                pixeldrainId: pixeldrainId,
                crc32: crc32,
                fileName: fileName,
                sizeBytes: sizeBytes,
                updatedAtMs: updatedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, BaseReferences<_$AppDatabase, $SourcesTable, Source>),
      Source,
      PrefetchHooks Function()
    >;
typedef $$ProgressEntriesTableCreateCompanionBuilder =
    ProgressEntriesCompanion Function({
      required int arcPart,
      required int number,
      Value<int> positionMs,
      Value<bool> watched,
      required int updatedAtMs,
      Value<int> rowid,
    });
typedef $$ProgressEntriesTableUpdateCompanionBuilder =
    ProgressEntriesCompanion Function({
      Value<int> arcPart,
      Value<int> number,
      Value<int> positionMs,
      Value<bool> watched,
      Value<int> updatedAtMs,
      Value<int> rowid,
    });

class $$ProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressEntriesTable> {
  $$ProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get arcPart => $composableBuilder(
    column: $table.arcPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get watched => $composableBuilder(
    column: $table.watched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressEntriesTable> {
  $$ProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get arcPart => $composableBuilder(
    column: $table.arcPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get watched => $composableBuilder(
    column: $table.watched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressEntriesTable> {
  $$ProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get arcPart =>
      $composableBuilder(column: $table.arcPart, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get watched =>
      $composableBuilder(column: $table.watched, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$ProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressEntriesTable,
          ProgressEntry,
          $$ProgressEntriesTableFilterComposer,
          $$ProgressEntriesTableOrderingComposer,
          $$ProgressEntriesTableAnnotationComposer,
          $$ProgressEntriesTableCreateCompanionBuilder,
          $$ProgressEntriesTableUpdateCompanionBuilder,
          (
            ProgressEntry,
            BaseReferences<_$AppDatabase, $ProgressEntriesTable, ProgressEntry>,
          ),
          ProgressEntry,
          PrefetchHooks Function()
        > {
  $$ProgressEntriesTableTableManager(
    _$AppDatabase db,
    $ProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> arcPart = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<bool> watched = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressEntriesCompanion(
                arcPart: arcPart,
                number: number,
                positionMs: positionMs,
                watched: watched,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int arcPart,
                required int number,
                Value<int> positionMs = const Value.absent(),
                Value<bool> watched = const Value.absent(),
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => ProgressEntriesCompanion.insert(
                arcPart: arcPart,
                number: number,
                positionMs: positionMs,
                watched: watched,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressEntriesTable,
      ProgressEntry,
      $$ProgressEntriesTableFilterComposer,
      $$ProgressEntriesTableOrderingComposer,
      $$ProgressEntriesTableAnnotationComposer,
      $$ProgressEntriesTableCreateCompanionBuilder,
      $$ProgressEntriesTableUpdateCompanionBuilder,
      (
        ProgressEntry,
        BaseReferences<_$AppDatabase, $ProgressEntriesTable, ProgressEntry>,
      ),
      ProgressEntry,
      PrefetchHooks Function()
    >;
typedef $$DownloadEntriesTableCreateCompanionBuilder =
    DownloadEntriesCompanion Function({
      required int arcPart,
      required int number,
      Value<int?> sourceId,
      Value<String?> taskId,
      Value<String> status,
      Value<String?> filePath,
      Value<int?> sizeBytes,
      required int updatedAtMs,
      Value<int> rowid,
    });
typedef $$DownloadEntriesTableUpdateCompanionBuilder =
    DownloadEntriesCompanion Function({
      Value<int> arcPart,
      Value<int> number,
      Value<int?> sourceId,
      Value<String?> taskId,
      Value<String> status,
      Value<String?> filePath,
      Value<int?> sizeBytes,
      Value<int> updatedAtMs,
      Value<int> rowid,
    });

class $$DownloadEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get arcPart => $composableBuilder(
    column: $table.arcPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get arcPart => $composableBuilder(
    column: $table.arcPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadEntriesTable> {
  $$DownloadEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get arcPart =>
      $composableBuilder(column: $table.arcPart, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );
}

class $$DownloadEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadEntriesTable,
          DownloadEntry,
          $$DownloadEntriesTableFilterComposer,
          $$DownloadEntriesTableOrderingComposer,
          $$DownloadEntriesTableAnnotationComposer,
          $$DownloadEntriesTableCreateCompanionBuilder,
          $$DownloadEntriesTableUpdateCompanionBuilder,
          (
            DownloadEntry,
            BaseReferences<_$AppDatabase, $DownloadEntriesTable, DownloadEntry>,
          ),
          DownloadEntry,
          PrefetchHooks Function()
        > {
  $$DownloadEntriesTableTableManager(
    _$AppDatabase db,
    $DownloadEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> arcPart = const Value.absent(),
                Value<int> number = const Value.absent(),
                Value<int?> sourceId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadEntriesCompanion(
                arcPart: arcPart,
                number: number,
                sourceId: sourceId,
                taskId: taskId,
                status: status,
                filePath: filePath,
                sizeBytes: sizeBytes,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int arcPart,
                required int number,
                Value<int?> sourceId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                required int updatedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => DownloadEntriesCompanion.insert(
                arcPart: arcPart,
                number: number,
                sourceId: sourceId,
                taskId: taskId,
                status: status,
                filePath: filePath,
                sizeBytes: sizeBytes,
                updatedAtMs: updatedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadEntriesTable,
      DownloadEntry,
      $$DownloadEntriesTableFilterComposer,
      $$DownloadEntriesTableOrderingComposer,
      $$DownloadEntriesTableAnnotationComposer,
      $$DownloadEntriesTableCreateCompanionBuilder,
      $$DownloadEntriesTableUpdateCompanionBuilder,
      (
        DownloadEntry,
        BaseReferences<_$AppDatabase, $DownloadEntriesTable, DownloadEntry>,
      ),
      DownloadEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArcsTableTableManager get arcs => $$ArcsTableTableManager(_db, _db.arcs);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$ProgressEntriesTableTableManager get progressEntries =>
      $$ProgressEntriesTableTableManager(_db, _db.progressEntries);
  $$DownloadEntriesTableTableManager get downloadEntries =>
      $$DownloadEntriesTableTableManager(_db, _db.downloadEntries);
}

mixin _$CatalogDaoMixin on DatabaseAccessor<AppDatabase> {
  $ArcsTable get arcs => attachedDatabase.arcs;
  $EpisodesTable get episodes => attachedDatabase.episodes;
  $SourcesTable get sources => attachedDatabase.sources;
  CatalogDaoManager get managers => CatalogDaoManager(this);
}

class CatalogDaoManager {
  final _$CatalogDaoMixin _db;
  CatalogDaoManager(this._db);
  $$ArcsTableTableManager get arcs =>
      $$ArcsTableTableManager(_db.attachedDatabase, _db.arcs);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db.attachedDatabase, _db.episodes);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db.attachedDatabase, _db.sources);
}

mixin _$ProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProgressEntriesTable get progressEntries => attachedDatabase.progressEntries;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
  $$ProgressEntriesTableTableManager get progressEntries =>
      $$ProgressEntriesTableTableManager(
        _db.attachedDatabase,
        _db.progressEntries,
      );
}

mixin _$DownloadsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DownloadEntriesTable get downloadEntries => attachedDatabase.downloadEntries;
  DownloadsDaoManager get managers => DownloadsDaoManager(this);
}

class DownloadsDaoManager {
  final _$DownloadsDaoMixin _db;
  DownloadsDaoManager(this._db);
  $$DownloadEntriesTableTableManager get downloadEntries =>
      $$DownloadEntriesTableTableManager(
        _db.attachedDatabase,
        _db.downloadEntries,
      );
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
const appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  const AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'365ef3f215d780c29a21b6328f0b547a8363c6a6';

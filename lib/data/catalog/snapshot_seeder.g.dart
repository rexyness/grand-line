// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_seeder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app database, seeded. UI layers await this instead of [appDatabase].

@ProviderFor(seededDatabase)
const seededDatabaseProvider = SeededDatabaseProvider._();

/// The app database, seeded. UI layers await this instead of [appDatabase].

final class SeededDatabaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppDatabase>,
          AppDatabase,
          FutureOr<AppDatabase>
        >
    with $FutureModifier<AppDatabase>, $FutureProvider<AppDatabase> {
  /// The app database, seeded. UI layers await this instead of [appDatabase].
  const SeededDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seededDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seededDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<AppDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppDatabase> create(Ref ref) {
    return seededDatabase(ref);
  }
}

String _$seededDatabaseHash() => r'f74ee99f45b33d804f3c83394a1eb508413ff7a8';

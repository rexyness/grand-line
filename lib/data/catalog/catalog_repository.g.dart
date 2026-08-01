// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(catalogRepository)
const catalogRepositoryProvider = CatalogRepositoryProvider._();

final class CatalogRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogRepository>,
          CatalogRepository,
          FutureOr<CatalogRepository>
        >
    with
        $FutureModifier<CatalogRepository>,
        $FutureProvider<CatalogRepository> {
  const CatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<CatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogRepository> create(Ref ref) {
    return catalogRepository(ref);
  }
}

String _$catalogRepositoryHash() => r'197e974fcf66ecb1d9c5481ca1d1cb7ea395990a';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_backend.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(catalogBackend)
const catalogBackendProvider = CatalogBackendProvider._();

final class CatalogBackendProvider
    extends
        $FunctionalProvider<CatalogBackend?, CatalogBackend?, CatalogBackend?>
    with $Provider<CatalogBackend?> {
  const CatalogBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogBackendHash();

  @$internal
  @override
  $ProviderElement<CatalogBackend?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CatalogBackend? create(Ref ref) {
    return catalogBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CatalogBackend? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CatalogBackend?>(value),
    );
  }
}

String _$catalogBackendHash() => r'2f4802b2026ef4cd898a1257ae760fc02c29bac6';

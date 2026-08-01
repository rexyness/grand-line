// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backdrop_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backdropCache)
const backdropCacheProvider = BackdropCacheProvider._();

final class BackdropCacheProvider
    extends
        $FunctionalProvider<
          AsyncValue<BackdropCache>,
          BackdropCache,
          FutureOr<BackdropCache>
        >
    with $FutureModifier<BackdropCache>, $FutureProvider<BackdropCache> {
  const BackdropCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backdropCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backdropCacheHash();

  @$internal
  @override
  $FutureProviderElement<BackdropCache> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BackdropCache> create(Ref ref) {
    return backdropCache(ref);
  }
}

String _$backdropCacheHash() => r'0a00dc84bfc497b737be353ac089495e3a891d4d';

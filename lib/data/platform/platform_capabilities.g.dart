// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_capabilities.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(platformCapabilities)
const platformCapabilitiesProvider = PlatformCapabilitiesProvider._();

final class PlatformCapabilitiesProvider
    extends
        $FunctionalProvider<
          PlatformCapabilities,
          PlatformCapabilities,
          PlatformCapabilities
        >
    with $Provider<PlatformCapabilities> {
  const PlatformCapabilitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformCapabilitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformCapabilitiesHash();

  @$internal
  @override
  $ProviderElement<PlatformCapabilities> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlatformCapabilities create(Ref ref) {
    return platformCapabilities(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlatformCapabilities value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlatformCapabilities>(value),
    );
  }
}

String _$platformCapabilitiesHash() =>
    r'cf54ecd2f59281c7d20cec462bb89e294fe63fda';

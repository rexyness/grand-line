import 'package:file_selector/file_selector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin shims over the external-intent packages (spec §6.3: engine packages
/// never leak past data/); features call these, never the packages.

/// Opens [url] in the system browser. Returns false when the OS refuses.
Future<bool> openExternalUrl(String url) async {
  try {
    return await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// System folder picker (desktop download-folder setting, spec §4.5).
/// Null when the user cancels.
Future<String?> pickFolder({String? initialDirectory}) =>
    getDirectoryPath(initialDirectory: initialDirectory);

/// App version as `X.Y.Z+N` from the platform package metadata.
Future<String> appVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.buildNumber.isEmpty
      ? info.version
      : '${info.version}+${info.buildNumber}';
}

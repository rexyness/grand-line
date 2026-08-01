import Flutter
import UIKit
#if canImport(workmanager_apple)
import workmanager_apple
#elseif canImport(workmanager)
import workmanager
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Best-effort BGAppRefresh release check (spec §9.4): iOS decides when
    // sideloaded apps may run it; the identifier must match Info.plist's
    // BGTaskSchedulerPermittedIdentifiers. The Dart-side notify_state file
    // gates whether a fired task actually does anything.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "io.github.rexyness.grandline.releasecheck",
      frequency: NSNumber(value: 6 * 60 * 60))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

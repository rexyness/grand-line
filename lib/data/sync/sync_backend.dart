/// What the sync layer needs from a hosted backend (spec §8): email-OTP
/// auth and push/pull of watch-progress rows. Engine-free so [SyncService]
/// and its tests never touch the Supabase packages (spec §6.3).
library;

/// A watch-progress row as it crosses the wire (spec §8.3): only position +
/// watched sync, keyed by logical episode identity, with the client-stamped
/// timestamp that drives the most-recent-activity-wins merge.
class RemoteProgress {
  const RemoteProgress({
    required this.arcPart,
    required this.number,
    required this.positionMs,
    required this.watched,
    required this.updatedAt,
  });

  final int arcPart;
  final int number;
  final int positionMs;
  final bool watched;
  final DateTime updatedAt;
}

/// Auth failure with a human-readable message, so screens never have to
/// know the backend package's exception types.
class SyncAuthException implements Exception {
  const SyncAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class SyncBackend {
  /// Signed-in email, or null. [userEmailStream] emits the current value on
  /// listen, then every change.
  String? get userEmail;
  Stream<String?> get userEmailStream;

  /// Emails a 6-digit one-time code (spec §8.2: sole sign-in method).
  Future<void> sendOtp(String email);

  Future<void> verifyOtp({required String email, required String code});

  Future<void> signOut();

  /// Applies [rows] server-side under the most-recent-activity-wins rule
  /// (the `apply_progress_batch` RPC, spec §3.3).
  Future<void> pushProgress(List<RemoteProgress> rows);

  /// The signed-in user's complete server-side progress.
  Future<List<RemoteProgress>> pullProgress();
}

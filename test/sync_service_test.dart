import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/data/sync/sync_backend.dart';
import 'package:grand_line/data/sync/sync_service.dart';

class FakeSyncBackend implements SyncBackend {
  String? _email;
  final _emailController = StreamController<String?>.broadcast();
  final pushed = <List<RemoteProgress>>[];
  List<RemoteProgress> remote = [];

  void setEmail(String? email) {
    _email = email;
    _emailController.add(email);
  }

  @override
  String? get userEmail => _email;

  @override
  Stream<String?> get userEmailStream => _emailController.stream;

  @override
  Future<void> sendOtp(String email) async {}

  @override
  Future<void> verifyOtp({required String email, required String code}) async {
    setEmail(email);
  }

  @override
  Future<void> signOut() async => setEmail(null);

  @override
  Future<void> pushProgress(List<RemoteProgress> rows) async {
    if (rows.isNotEmpty) pushed.add(rows);
  }

  @override
  Future<List<RemoteProgress>> pullProgress() async => remote;
}

void main() {
  late AppDatabase db;
  late FakeSyncBackend backend;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    backend = FakeSyncBackend();
  });

  tearDown(() => db.close());

  Future<void> writeLocal(int arcPart, int number,
      {int positionMs = 0, bool watched = false, required int updatedAtMs}) {
    return db.progressDao.applyLww(
      arcPart: arcPart,
      number: number,
      positionMs: positionMs,
      watched: watched,
      updatedAtMs: updatedAtMs,
    );
  }

  group('syncNow', () {
    test('pushes every local row and pulls with client-side LWW', () async {
      backend.setEmail('nami@example.com');
      final service = SyncService(db, backend);

      await writeLocal(1, 1, positionMs: 60000, updatedAtMs: 2000);
      await writeLocal(1, 2, positionMs: 30000, watched: true, updatedAtMs: 5000);
      // Remote: newer row for E1 (must win), older for E2 (must lose).
      backend.remote = [
        RemoteProgress(
          arcPart: 1,
          number: 1,
          positionMs: 90000,
          watched: true,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(9000, isUtc: true),
        ),
        RemoteProgress(
          arcPart: 1,
          number: 2,
          positionMs: 1000,
          watched: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
        ),
      ];

      final when = await service.syncNow();
      expect(when, isNotNull);

      expect(backend.pushed, hasLength(1));
      final rows = backend.pushed.single;
      expect(rows, hasLength(2));
      final e1 = rows.singleWhere((r) => r.number == 1);
      expect(e1.positionMs, 60000);
      expect(e1.updatedAt, DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true));

      final localE1 = await db.progressDao.get(1, 1);
      expect(localE1!.positionMs, 90000, reason: 'newer remote wins');
      expect(localE1.watched, isTrue);
      final localE2 = await db.progressDao.get(1, 2);
      expect(localE2!.positionMs, 30000, reason: 'older remote loses');
      expect(localE2.watched, isTrue);
    });

    test('records the last-sync time', () async {
      backend.setEmail('nami@example.com');
      final service = SyncService(db, backend);
      expect(await service.watchLastSync().first, isNull);

      await service.syncNow();
      final last = await service.watchLastSync().first;
      expect(last, isNotNull);
    });

    test('no-ops when signed out or local-only', () async {
      expect(await SyncService(db, backend).syncNow(), isNull);
      expect(await SyncService(db, null).syncNow(), isNull);
      expect(backend.pushed, isEmpty);
    });
  });

  group('background triggers', () {
    test('sign-in runs the history upload and pull', () async {
      await writeLocal(3, 1, positionMs: 42, updatedAtMs: 7000);
      backend.remote = [
        RemoteProgress(
          arcPart: 3,
          number: 2,
          positionMs: 500,
          watched: false,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(8000, isUtc: true),
        ),
      ];
      final service = SyncService(db, backend)..start();

      backend.setEmail('zoro@example.com');
      await pumpEventQueue();

      expect(backend.pushed, hasLength(1));
      expect(backend.pushed.single.single.positionMs, 42);
      final pulled = await db.progressDao.get(3, 2);
      expect(pulled!.positionMs, 500, reason: 'pull ran after the upload');

      // A token refresh re-emitting the same email must not re-sync.
      backend.setEmail('zoro@example.com');
      await pumpEventQueue();
      expect(backend.pushed, hasLength(1));

      await service.dispose();
    });

    test('local progress changes push after the debounce', () async {
      backend.setEmail('luffy@example.com');
      final service = SyncService(db, backend,
          pushDebounce: const Duration(milliseconds: 20))
        ..start();
      await pumpEventQueue();

      await writeLocal(2, 4, positionMs: 1234, updatedAtMs: 3000);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(backend.pushed, hasLength(1));
      expect(backend.pushed.single.single.positionMs, 1234);

      await service.dispose();
    });

    test('signed-out changes never push', () async {
      final service = SyncService(db, backend,
          pushDebounce: const Duration(milliseconds: 20))
        ..start();
      await pumpEventQueue();

      await writeLocal(2, 4, updatedAtMs: 3000);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(backend.pushed, isEmpty);
      await service.dispose();
    });
  });
}

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grand_line/data/db/database.dart';
import 'package:grand_line/data/sync/sync_backend.dart';
import 'package:grand_line/data/sync/sync_service.dart';
import 'package:grand_line/features/account/account_screen.dart';

class FakeSyncBackend implements SyncBackend {
  String? _email;
  final _controller = StreamController<String?>.broadcast();
  String? sentOtpTo;
  String? verifiedCode;

  @override
  String? get userEmail => _email;

  @override
  Stream<String?> get userEmailStream async* {
    yield _email;
    yield* _controller.stream;
  }

  @override
  Future<void> sendOtp(String email) async => sentOtpTo = email;

  @override
  Future<void> verifyOtp({required String email, required String code}) async {
    verifiedCode = code;
    _email = email;
    _controller.add(email);
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _controller.add(null);
  }

  @override
  Future<void> pushProgress(List<RemoteProgress> rows) async {}

  @override
  Future<List<RemoteProgress>> pullProgress() async => [];
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpAccount(WidgetTester tester, {SyncBackend? backend}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncServiceProvider.overrideWith((ref) {
            final service = SyncService(db, backend);
            ref.onDispose(service.dispose);
            return service;
          }),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> teardownTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('local-only build explains sync is unavailable', (tester) async {
    await pumpAccount(tester, backend: null);
    expect(find.textContaining('no sync backend'), findsOneWidget);
    await teardownTree(tester);
  });

  testWidgets('email → code → signed-in card, then sign out', (tester) async {
    final backend = FakeSyncBackend();
    await pumpAccount(tester, backend: backend);

    expect(find.text('Sign in to sync watch progress'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' robin@example.com ');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(backend.sentOtpTo, 'robin@example.com');

    expect(find.text('6-digit code'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pump();
    await tester.pump();
    expect(backend.verifiedCode, '123456');

    expect(find.text('robin@example.com'), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Not synced yet'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Sign in to sync watch progress'), findsOneWidget);

    await teardownTree(tester);
  });

  testWidgets('rejects a bad email and a short code locally', (tester) async {
    final backend = FakeSyncBackend();
    await pumpAccount(tester, backend: backend);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.textContaining('does not look like'), findsOneWidget);
    expect(backend.sentOtpTo, isNull);

    await tester.enterText(find.byType(TextField), 'usopp@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Verify'));
    await tester.pump();
    expect(find.textContaining('6-digit code from the email'), findsOneWidget);
    expect(backend.verifiedCode, isNull);

    await teardownTree(tester);
  });
}

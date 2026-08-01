import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sync/sync_service.dart';
import 'account_model.dart';

/// Account & sync surface (spec §4.6). Signed out: email → 6-digit OTP →
/// done, one identical flow on all four platforms. Signed in: email,
/// last-sync time, Sync now, Sign out (local data stays). Will live inside
/// Settings once that screen exists (step 12); until then home links here.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(syncServiceProvider);
    final email = ref.watch(signedInEmailProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: !service.available
                ? const Text(
                    'This build has no sync backend configured. '
                    'Watch progress stays on this device.',
                    textAlign: TextAlign.center,
                  )
                : email != null
                    ? _SignedInCard(email: email)
                    : const _SignInFlow(),
          ),
        ),
      ),
    );
  }
}

class _SignedInCard extends ConsumerStatefulWidget {
  const _SignedInCard({required this.email});

  final String email;

  @override
  ConsumerState<_SignedInCard> createState() => _SignedInCardState();
}

class _SignedInCardState extends ConsumerState<_SignedInCard> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(syncServiceProvider).syncNow();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Sync failed — check your connection and try again.'),
      ));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastSync = ref.watch(lastSyncProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.cloud_done_outlined, size: 48),
        const SizedBox(height: 12),
        Text(widget.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          formatLastSync(lastSync, DateTime.now()),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _syncing ? null : _syncNow,
          icon: _syncing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(_syncing ? 'Syncing…' : 'Sync now'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              _syncing ? null : () => ref.read(syncServiceProvider).signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 8),
        Text(
          'Signing out keeps everything on this device.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SignInFlow extends ConsumerStatefulWidget {
  const _SignInFlow();

  @override
  ConsumerState<_SignInFlow> createState() => _SignInFlowState();
}

class _SignInFlowState extends ConsumerState<_SignInFlow> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _sentTo; // null = email step, set = code step
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = normalizeEmail(_emailController.text);
    if (email == null) {
      setState(() => _error = 'That does not look like an email address.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(syncServiceProvider).sendOtp(email);
      if (mounted) setState(() => _sentTo = email);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (!isValidOtpCode(code)) {
      setState(() => _error = 'Enter the sign-in code from the email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Success flips signedInEmailProvider and the parent swaps to the
      // signed-in card; the sync service uploads local history in the
      // background (spec §8.1).
      await ref
          .read(syncServiceProvider)
          .verifyOtp(email: _sentTo!, code: code);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onCodeStep = _sentTo != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.cloud_sync_outlined, size: 48),
        const SizedBox(height: 12),
        Text(
          'Sign in to sync watch progress',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          onCodeStep
              ? 'Enter the 6-digit code sent to $_sentTo.'
              : 'No password — you get a one-time code by email. '
                  'Your history on this device uploads on first sign-in.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        if (!onCodeStep) ...[
          TextField(
            controller: _emailController,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: Text(_busy ? 'Sending…' : 'Send code'),
          ),
        ] else ...[
          TextField(
            controller: _codeController,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _verify,
            child: Text(_busy ? 'Verifying…' : 'Verify'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                      _sentTo = null;
                      _codeController.clear();
                      _error = null;
                    }),
            child: const Text('Use a different email'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Login / sign up. With Firebase set up it uses real accounts (email + password, Google).
/// Without Firebase it falls back to a simple login that just remembers your name.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _loading = false;
  String? _error;

  /// Old simple login, used when Firebase isn't set up.
  void _localLogin() {
    final email = _email.text.trim();
    final name = email.contains('@') ? email.split('@').first : email;
    context.read<AppState>().signIn(name.isEmpty ? 'Friend' : name[0].toUpperCase() + name.substring(1));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      // On success Firebase tells the app, and the app moves to the home screen by itself.
    } catch (e) {
      final msg = Auth.message(e);
      if (mounted && msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _submit() {
    if (!Auth.ready) return _localLogin();
    final email = _email.text.trim();
    final pass = _password.text;
    if (!email.contains('@') || !email.contains('.')) return setState(() => _error = 'Enter a valid email address.');
    if (pass.length < 6) return setState(() => _error = 'Password must be at least 6 characters.');
    _run(() => _signUp ? Auth.signUp(email, pass) : Auth.signIn(email, pass));
  }

  void _google() {
    if (!Auth.ready) return _localLogin();
    _run(Auth.google);
  }

  Future<void> _forgot() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _email.text.trim();
    if (!Auth.ready) {
      messenger.showSnackBar(const SnackBar(content: Text('Accounts aren\'t set up yet.')));
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Type your email above first, then tap Forgot password.');
      return;
    }
    try {
      await Auth.resetPassword(email);
      messenger.showSnackBar(SnackBar(content: Text('Reset link sent to $email. Check your inbox.')));
    } catch (e) {
      final msg = Auth.message(e);
      if (mounted && msg != null) setState(() => _error = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: W2T.rust,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 230 + top,
              child: Stack(
                children: [
                  Positioned(right: -40, top: top, child: Transform.rotate(angle: .3, child: Image.asset('assets/images/tomato.webp', width: 110))),
                  Align(alignment: const Alignment(0, .3), child: Image.asset('assets/images/logo-cream.webp', width: 150)),
                ],
              ),
            ),
            Container(
              constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 230 - top),
              padding: const EdgeInsets.fromLTRB(Gap.page, 32, Gap.page, 32),
              decoration: const BoxDecoration(color: W2T.butter, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_signUp ? 'Sign up' : 'Login', style: heading(30)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded, color: W2T.rust)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded, color: W2T.rust)),
                  ),
                  if (!_signUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _forgot, child: const Text('Forgot password?', style: TextStyle(color: W2T.rust))),
                    )
                  else
                    const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: W2T.danger, fontSize: 13)),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_signUp ? 'Create account' : 'Login'),
                  ),
                  const SizedBox(height: 20),
                  const Row(children: [
                    Expanded(child: Divider(color: W2T.divider)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Or continue with', style: TextStyle(fontSize: 12, color: W2T.brownText))),
                    Expanded(child: Divider(color: W2T.divider)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _SocialButton('Google', onTap: _loading ? null : _google)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        'Apple',
                        onTap: _loading
                            ? null
                            : () => Auth.ready
                                ? ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apple sign-in is coming soon.')))
                                : _localLogin(),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => setState(() {
                      _signUp = !_signUp;
                      _error = null;
                    }),
                    child: Text(_signUp ? 'Already have an account? Login' : "Don't have an account? Sign up",
                        style: const TextStyle(color: W2T.rust, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SocialButton(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide.none,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: W2T.ink,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

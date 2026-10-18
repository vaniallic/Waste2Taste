import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Demo sign-in: no server yet, it just remembers your name on the phone.
/// (Real accounts with Firebase/Supabase can come later.)
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

  void _submit() {
    final email = _email.text.trim();
    final name = email.contains('@') ? email.split('@').first : email;
    context.read<AppState>().signIn(name.isEmpty ? 'Friend' : name[0].toUpperCase() + name.substring(1));
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
                      child: TextButton(onPressed: () {}, child: const Text('Forgot password?', style: TextStyle(color: W2T.rust))),
                    )
                  else
                    const SizedBox(height: 16),
                  FilledButton(onPressed: _submit, child: Text(_signUp ? 'Create account' : 'Login')),
                  const SizedBox(height: 20),
                  const Row(children: [
                    Expanded(child: Divider(color: W2T.divider)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Or continue with', style: TextStyle(fontSize: 12, color: W2T.brownText))),
                    Expanded(child: Divider(color: W2T.divider)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _SocialButton('Google', onTap: _submit)),
                    const SizedBox(width: 12),
                    Expanded(child: _SocialButton('Apple', onTap: _submit)),
                  ]),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => setState(() => _signUp = !_signUp),
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
  final VoidCallback onTap;
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

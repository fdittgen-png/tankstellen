import 'package:flutter/material.dart';

import '../../../../core/widgets/snackbar_helper.dart';

/// Reusable authentication form: anonymous or email with password.
///
/// Designed to be app-agnostic. Any app needing Supabase auth can use this.
/// Provides email sign-up (with confirm password) and sign-in flows.
class AuthFormWidget extends StatefulWidget {
  /// Called when authentication succeeds.
  /// [isEmail] is false for anonymous, true for email auth.
  final Future<void> Function({required bool isEmail, String? email, String? password, required bool isSignUp}) onSubmit;
  final bool isLoading;
  final String? error;

  const AuthFormWidget({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.error,
  });

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  bool _useEmail = false;
  bool _isSignUp = true;
  bool _showPassword = false;
  bool _showConfirm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (!_useEmail) return null; // Anonymous needs no validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) return 'Please enter your email';
    if (!email.contains('@')) return 'Invalid email address';
    if (_isSignUp && password.length < 6) return 'Password must be at least 6 characters';
    if (_isSignUp && password != _confirmController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      SnackBarHelper.showError(context, error);
      return;
    }
    widget.onSubmit(
      isEmail: _useEmail,
      email: _useEmail ? _emailController.text.trim() : null,
      password: _useEmail ? _passwordController.text : null,
      isSignUp: _isSignUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose your account type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Anonymous / Email toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Anonymous'), icon: Icon(Icons.person_outline, size: 18)),
            ButtonSegment(value: true, label: Text('Email'), icon: Icon(Icons.email_outlined, size: 18)),
          ],
          selected: {_useEmail},
          onSelectionChanged: (s) => setState(() => _useEmail = s.first),
        ),
        const SizedBox(height: 8),

        // Description text
        Text(
          _useEmail
              ? 'Sign in from any device. Recover your data if your phone is lost.'
              : 'Instant access, no email needed. Data tied to this device.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),

        // Email fields
        if (_useEmail) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email, size: 18),
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock, size: 18),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            obscureText: !_showPassword,
            enabled: !widget.isLoading,
          ),
          if (_isSignUp) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              obscureText: !_showConfirm,
              enabled: !widget.isLoading,
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading ? null : () => setState(() {
                _isSignUp = !_isSignUp;
                _confirmController.clear();
              }),
              child: Text(
                _isSignUp ? 'Already have an account? Sign in' : 'Create new account',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],

        // Error display
        if (widget.error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.error!, style: TextStyle(fontSize: 12, color: theme.colorScheme.error))),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.isLoading ? null : _submit,
          icon: widget.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_useEmail ? (_isSignUp ? Icons.person_add : Icons.login) : Icons.flash_on),
          label: Text(widget.isLoading ? 'Connecting...'
              : _useEmail ? (_isSignUp ? 'Create account & connect' : 'Sign in & connect')
              : 'Connect anonymously'),
        ),
      ],
    );
  }
}

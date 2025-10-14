// import 'package:flutter/material.dart';
// import '../../data/services/auth_api.dart';
// import '../../data/services/tenant_service.dart';
// import '../../data/services/auth_service.dart'; // for sessionController tokens
//
// class LoginScreen extends StatefulWidget {
//   /// Optional: if provided, the shell (app.dart) can handle persistence + navigation.
//   /// Signature matches the legacy usage in your app.dart.
//   final void Function(String access, String refresh, String displayName)? onSignedIn;
//
//   const LoginScreen({super.key, this.onSignedIn});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _tenantCtrl = TextEditingController();
//   final _usernameCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();
//   bool _loading = false;
//   bool _obscure = true;
//
//   @override
//   void dispose() {
//     _tenantCtrl.dispose();
//     _usernameCtrl.dispose();
//     _passwordCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _doLogin() async {
//     final tenant = _tenantCtrl.text.trim();
//     final username = _usernameCtrl.text.trim();
//     final password = _passwordCtrl.text;
//
//     if (tenant.isEmpty || username.isEmpty || password.isEmpty) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Tenant, username and password are required')),
//       );
//       return;
//     }
//
//     setState(() => _loading = true);
//     try {
//       // 1) Set tenant FIRST (required for /{tenant}/api/... calls)
//       // Keep as await-friendly in case setTenantId becomes async (we implemented it async in the shim).
//       await TenantService.instance.setTenantId(tenant);
//
//       // 2) Login (persists tokens inside AuthService/sessionController)
//       await AuthApi().login(username: username, password: password);
//
//       // 3) Hand control to app shell if it provided a callback; otherwise self-navigate
//       final access = sessionController.token ?? '';
//       final refresh = sessionController.refreshToken ?? '';
//       // If your backend returns displayName via login, wire it into AuthService and read it here.
//       final displayName = username;
//
//       if (widget.onSignedIn != null) {
//         widget.onSignedIn!(access, refresh, displayName);
//         return; // caller decides navigation
//       }
//
//       if (!mounted) return;
//       // Fallback: navigate internally
//       Navigator.of(context).pushReplacementNamed('/home');
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login failed: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Sign in')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _tenantCtrl,
//               decoration: const InputDecoration(
//                 labelText: 'Tenant ID',
//                 hintText: 'e.g. wfm-experts-india-pvt-ltd',
//               ),
//               textInputAction: TextInputAction.next,
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _usernameCtrl,
//               decoration: const InputDecoration(
//                 labelText: 'Username',
//                 hintText: 'name@company.com or employee id',
//               ),
//               textInputAction: TextInputAction.next,
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _passwordCtrl,
//               decoration: InputDecoration(
//                 labelText: 'Password',
//                 suffixIcon: IconButton(
//                   icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
//                   onPressed: () => setState(() => _obscure = !_obscure),
//                 ),
//               ),
//               obscureText: _obscure,
//               onSubmitted: (_) => _loading ? null : _doLogin(),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: _loading ? null : _doLogin,
//                 child: _loading
//                     ? const SizedBox(
//                     width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
//                     : const Text('Sign In'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import '../../data/services/auth_api.dart';
import '../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await AuthApi.instance.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Ensure session is marked signed-in:
      if (AuthService.instance.accessToken == null ||
          AuthService.instance.employeeId == null) {
        throw StateError('Login succeeded but session is incomplete.');
      }

      if (!mounted) return;

      // Navigate to your root/home. Adjust route if you use named routes.
      Navigator.of(context).pushReplacementNamed('/');

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final btnChild = _isBusy
        ? const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    )
        : const Text('Sign in');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter username' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      onFieldSubmitted: (_) => _doLogin(),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 16),

                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isBusy ? null : _doLogin,
                        child: btnChild,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

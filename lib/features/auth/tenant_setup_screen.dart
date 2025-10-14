import 'package:flutter/material.dart';
import '../../data/services/tenant_service.dart';

class TenantSetupScreen extends StatefulWidget {
  final VoidCallback onConfigured;
  const TenantSetupScreen({super.key, required this.onConfigured});

  @override
  State<TenantSetupScreen> createState() => _TenantSetupScreenState();
}

class _TenantSetupScreenState extends State<TenantSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenant = TextEditingController();

  bool _busy = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    FocusScope.of(context).unfocus(); // optional: dismiss keyboard
    try {
      // FIX: use the singleton service instead of an undefined tenantController
      // TenantService.instance.setTenantId(_tenant.text.trim());
      // ✅ Persist the tenant BEFORE moving on
      await TenantService.instance.setTenantId(_tenant.text.trim());
      // navigate or notify
      if (!mounted) return;
      // ✅ Notify your app shell/router to move to Login (or wherever)
      widget.onConfigured();
      // widget.onConfigured();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  void dispose() {
    _tenant.dispose(); // ✅ avoid controller leak
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Enter Tenant ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tenant,
                    decoration: const InputDecoration(
                      labelText: 'Tenant ID',
                      hintText: 'e.g. wfm-experts-india-pvt-ltd',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Tenant is required' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _save,
                      child: _busy ? const CircularProgressIndicator() : const Text('Continue'),
                    ),
                  )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

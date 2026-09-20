import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_glass_field.dart';
import '../widgets/animated_primary_button.dart';
import 'manager_home.dart';
import 'admin_home.dart';

class DeputyLoginScreen extends StatefulWidget {
  const DeputyLoginScreen({super.key});
  @override
  State<DeputyLoginScreen> createState() => _DeputyLoginScreenState();
}

class _DeputyLoginScreenState extends State<DeputyLoginScreen> {
  final _schoolCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nationalCodeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.getBool('admin_remember_me') ?? false;
      if (_rememberMe) {
        _schoolCodeCtrl.text = prefs.getString('admin_login_code') ?? '';
        _nameCtrl.text = prefs.getString('admin_login_name') ?? '';
        _nationalCodeCtrl.text = prefs.getString('admin_login_national_code') ?? '';
      }
    });
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.post('auth/login-deputy', {
      'school_code': _schoolCodeCtrl.text.trim(),
      'full_name': _nameCtrl.text.trim(),
      'national_code': _nationalCodeCtrl.text.trim(),
    });
    if (res['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('admin_remember_me', true);
        await prefs.setString('admin_login_code', _schoolCodeCtrl.text.trim());
        await prefs.setString('admin_login_name', _nameCtrl.text.trim());
        await prefs.setString('admin_login_national_code', _nationalCodeCtrl.text.trim());
      } else {
        await prefs.remove('admin_remember_me');
        await prefs.remove('admin_login_code');
        await prefs.remove('admin_login_name');
        await prefs.remove('admin_login_national_code');
      }
      await ApiService.saveSession(res['token'], res['user']);
      appTheme.value = await SchoolTheme.fetch();
      if (!mounted) return;
      final role = res['user']['role'];
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminHome() : const ManagerHome()));
    } else {
      setState(() { _error = res['message'] ?? 'خطا در ورود'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('ورود معاون')),
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn, primary: primary, secondary: secondary, showParticles: false,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 84, 20, 30),
                child: GlassCard(
                  blurEnabled: effectsOn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedGlassField(controller: _schoolCodeCtrl, label: 'کد مدرسه', icon: Icons.qr_code_rounded),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _nameCtrl, label: 'نام و نام‌خانوادگی', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _nationalCodeCtrl, label: 'کد ملی', icon: Icons.badge_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        title: const Text('مرا به خاطر بسپار', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        activeColor: secondary,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                      ],
                      const SizedBox(height: 18),
                      AnimatedPrimaryButton(label: 'ورود', loading: _loading, color: secondary, onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

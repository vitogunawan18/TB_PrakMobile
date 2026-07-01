import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
import '../theme/app_theme.dart';
import 'health_page.dart';

class ProfilePage extends StatefulWidget {
  final ApiService apiService;
  final AuthManager? authManager;

  const ProfilePage({super.key, required this.apiService, this.authManager});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  final _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _online = true;
  bool _isEditingName = false;
  String _originalName = '';

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((ev) {
      setState(() => _online = ev != ConnectivityResult.none);
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await widget.apiService.fetchProfile();
      final data = res['data'] as Map<String, dynamic>? ?? res;
      setState(() {
        _profile = data;
        _nameController.text = data['name'] ?? '';
        _originalName = data['name'] ?? '';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await widget.apiService.updateProfile(name);
      final data = res['data'] as Map<String, dynamic>? ?? res;
      setState(() {
        _profile = data;
        _originalName = data['name'] ?? '';
        _isEditingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama berhasil diperbarui', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.statusExpired,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await widget.apiService.logout();
    } catch (_) {
      // ignore api errors on logout
    }
    await widget.authManager?.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialName = _profile?['name']?.toString() ?? '?';
    final avatarLetter = initialName.isNotEmpty ? initialName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          if (!_online)
            Container(
              color: AppTheme.statusExpired.withOpacity(0.2),
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: const Text('Anda sedang offline', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppTheme.textSecondary))))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80), // extra padding to avoid floating bottom nav
                        child: Column(
                          children: [
                            // 1. Glowing Avatar Header
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.accentPrimary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentPrimary.withOpacity(0.35),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    avatarLetter,
                                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // 2. Profile Details Form (Glassmorphic Container)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassCardDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('INFORMASI PERSONAL', style: TextStyle(color: AppTheme.accentPrimary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                                  const SizedBox(height: 16),
                                  
                                  // Name Field Input
                                  TextFormField(
                                    controller: _nameController,
                                    focusNode: _nameFocusNode,
                                    readOnly: !_isEditingName,
                                    style: TextStyle(
                                      color: _isEditingName ? Colors.white : Colors.white.withOpacity(0.6),
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Nama Lengkap',
                                      labelStyle: const TextStyle(color: AppTheme.textSecondary),
                                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                                      suffixIcon: !_isEditingName
                                          ? IconButton(
                                              icon: const Icon(Icons.edit, color: AppTheme.accentPrimary),
                                              onPressed: () {
                                                setState(() {
                                                  _isEditingName = true;
                                                });
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  _nameFocusNode.requestFocus();
                                                });
                                              },
                                            )
                                          : null,
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppTheme.accentPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Edit Action Buttons
                                  if (_isEditingName)
                                    Row(
                                      children: [
                                        // 1. Cancel Button (Batal)
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _nameController.text = _originalName;
                                                _isEditingName = false;
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.textSecondary,
                                              side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                              minimumSize: const Size(0, 44),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // 2. Save Button (Simpan)
                                        Expanded(
                                          child: Container(
                                            decoration: AppTheme.gradientButtonDecoration(),
                                            child: ElevatedButton(
                                              onPressed: _saveName,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                minimumSize: const Size(0, 44),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 3. User Identity Details Box
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: AppTheme.glassCardDecoration(),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('User ID', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                      Text(
                                        _profile?['id']?.toString() ?? '-',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(color: Colors.white10),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Email', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                                      Text(
                                        _profile?['email'] ?? '-',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 4. Server Diagnosis Menu
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HealthPage(apiService: widget.apiService),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: AppTheme.glassCardDecoration(),
                                child: const Row(
                                  children: [
                                    Icon(Icons.health_and_safety_outlined, color: AppTheme.accentPrimary, size: 24),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Diagnosis Server', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                          SizedBox(height: 2),
                                          Text('Uji kesehatan & latency backend', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Footer / Credits
                            const Text(
                              'Aplikasi EduTick v1.0.0\nDikembangkan oleh Mahasiswa ITG',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            
                            // 5. Logout Button (Premium Red Outlined with Tinted Background)
                            ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.statusExpired.withOpacity(0.08),
                                foregroundColor: AppTheme.statusExpired,
                                elevation: 0,
                                side: const BorderSide(color: AppTheme.statusExpired, width: 1.5),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, size: 20),
                                  SizedBox(width: 8),
                                  Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}


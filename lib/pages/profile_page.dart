import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
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
  bool _online = true;

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
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama diperbarui')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Column(
        children: [
          if (!_online)
            Container(
              color: Colors.red.shade100,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: const Text('Anda sedang offline', textAlign: TextAlign.center),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(onPressed: _saveName, child: const Text('Simpan')),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              title: const Text('User ID'),
                              subtitle: Text(_profile?['id']?.toString() ?? '-'),
                            ),
                            ListTile(
                              title: const Text('Email'),
                              subtitle: Text(_profile?['email'] ?? '-'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.health_and_safety_outlined, color: Colors.green),
                              title: const Text('Status Koneksi Server'),
                              subtitle: const Text('Uji kesehatan endpoint backend'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HealthPage(apiService: widget.apiService),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            const Text(
                              'Aplikasi EduTick v1.0.0\nDikembangkan oleh Mahasiswa Informatika ITG',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(onPressed: _logout, child: const Text('Logout')),
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

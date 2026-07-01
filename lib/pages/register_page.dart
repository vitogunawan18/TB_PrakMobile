import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final ApiService apiService;
  final AuthManager? authManager;

  const RegisterPage({super.key, required this.apiService, this.authManager});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.apiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final token = data['data']?['access_token'] ?? data['access_token'];
      if (token is String && token.isNotEmpty) {
        widget.apiService.updateToken(token);
        await widget.authManager?.saveToken(token);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        return;
      }
      throw Exception('Token registrasi tidak ditemukan dalam respons.');
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          // 1. Top-Left Glowing Planet/Sphere Curve
          Positioned(
            top: -240,
            left: -240,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentSecondary.withOpacity(0.3),
                  width: 1.5,
                ),
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentSecondary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  center: Alignment.bottomRight,
                  radius: 0.85,
                ),
              ),
            ),
          ),

          // 2. Bottom-Right Glowing Planet/Sphere Curve
          Positioned(
            bottom: -240,
            right: -240,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accentPrimary.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPrimary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  center: Alignment.topLeft,
                  radius: 0.85,
                ),
              ),
            ),
          ),

          // 3. Side Dotted Grids
          Positioned(
            left: 24,
            bottom: 240,
            child: CustomPaint(
              size: const Size(60, 80),
              painter: DottedGridPainter(cols: 5, rows: 6),
            ),
          ),
          Positioned(
            right: 24,
            top: 180,
            child: CustomPaint(
              size: const Size(60, 80),
              painter: DottedGridPainter(cols: 5, rows: 6),
            ),
          ),

          // 4. Main Body Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Ticket Logo Icon
                      Center(
                        child: CustomPaint(
                          size: const Size(78, 54),
                          painter: TicketIconPainter(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Brand Title "EDUTICK"
                      Center(
                        child: Column(
                          children: [
                            RichText(
                              text: const TextSpan(
                                text: 'EDU',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'TICK',
                                    style: TextStyle(
                                      color: AppTheme.accentPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Underline Glowing Line
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 48,
                              height: 2.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [AppTheme.accentSecondary, AppTheme.accentPrimary],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentPrimary.withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subtitle
                      const Text(
                        'Buat akun baru untuk mulai memesan tiket event.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Translucent Glassmorphic Form Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name Field Label
                              const Text(
                                'Nama Lengkap',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Name TextFormField
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan nama lengkap',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 14),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 14, right: 10),
                                    child: Icon(Icons.person_outline, color: AppTheme.accentPrimary, size: 22),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgPrimary,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.accentSecondary.withOpacity(0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.accentPrimary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nama wajib diisi';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Nama minimal 2 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Email Field Label
                              const Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Email TextFormField
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan email Anda',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 14),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 14, right: 10),
                                    child: Icon(Icons.email_outlined, color: AppTheme.accentPrimary, size: 22),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgPrimary,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.accentSecondary.withOpacity(0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.accentPrimary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Field Label
                              const Text(
                                'Password',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Password TextFormField
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan password (min 8 karakter)',
                                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 14),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 14, right: 10),
                                    child: Icon(Icons.lock_outlined, color: AppTheme.accentPrimary, size: 22),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary.withOpacity(0.7),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.bgPrimary,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.accentSecondary.withOpacity(0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.accentPrimary, width: 1.5),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.statusExpired, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password wajib diisi';
                                  }
                                  if (value.length < 8) {
                                    return 'Password minimal 8 karakter';
                                  }
                                  return null;
                                },
                              ),
                              
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppTheme.statusExpired, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              
                              const SizedBox(height: 28),

                              // Daftar Button (Gradient)
                              Container(
                                decoration: AppTheme.gradientButtonDecoration(),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Daftar Sekarang',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                      if (!_isLoading) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Divider with Shield Icon
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.06), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: AppTheme.accentPrimary.withOpacity(0.7),
                              size: 18,
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.06), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      const Center(
                        child: Text(
                          'Data Anda aman bersama kami',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer: Sudah punya akun? Masuk
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'Sudah punya akun?',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                                    },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Masuk',
                                    style: TextStyle(
                                      color: AppTheme.accentPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.chevron_right, color: AppTheme.accentPrimary, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_manager.dart';
import '../theme/app_theme.dart';
import '../routes.dart';

class SplashPage extends StatefulWidget {
  final ApiService apiService;
  final AuthManager authManager;

  const SplashPage({super.key, required this.apiService, required this.authManager});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await widget.authManager.loadToken();
    // Delayed to let user appreciate the stunning splash screen design
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          // Radial Gradient Background glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentSecondary.withOpacity(0.18),
                    AppTheme.bgPrimary,
                  ],
                  center: Alignment.center,
                  radius: 1.0,
                ),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Logo Container
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withOpacity(0.2),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: const Size(90, 62),
                    painter: SplashTicketPainter(),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Brand Title "EDUTICK"
                RichText(
                  text: const TextSpan(
                    text: 'EDU',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
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
                  width: 50,
                  height: 3,
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
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Akses Event Edukasi Terbaik',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Circular progress indicator at bottom
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SplashTicketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.accentSecondary, AppTheme.accentPrimary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double r = 8.0; 
    double cutR = 6.0; 

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    path.lineTo(w, h / 2 - cutR);
    path.arcToPoint(Offset(w, h / 2 + cutR), radius: Radius.circular(cutR), clockwise: false);
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    
    path.lineTo(0, h / 2 + cutR);
    path.arcToPoint(Offset(0, h / 2 - cutR), radius: Radius.circular(cutR), clockwise: false);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(w / 2, h / 2 - 10), 3, dotPaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 3, dotPaint);
    canvas.drawCircle(Offset(w / 2, h / 2 + 10), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


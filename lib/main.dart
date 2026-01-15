// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const VibeNoteApp());
}

class VibeNoteApp extends StatelessWidget {
  const VibeNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeNote',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        fontFamily: 'SF Pro',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late AnimationController _expandController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _expandAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _heartbeatController,
      curve: Curves.easeInOut,
    ));

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _expandAnimation = Tween<double>(begin: 1.0, end: 8.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _heartbeatController.forward();
    await _heartbeatController.reverse();
    await Future.delayed(const Duration(milliseconds: 200));
    await _heartbeatController.forward();
    await _heartbeatController.reverse();
    await Future.delayed(const Duration(milliseconds: 500));
    await _expandController.forward();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2a2a4a), Color(0xFF1a1a2e)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_heartbeatController, _expandController]),
                builder: (context, child) {
                  final scale = _scaleAnimation.value * _expandAnimation.value;
                  final opacity = _opacityAnimation.value;

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: const ParticleSphere(size: 250, isActive: true),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Text(
                      "I'm here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticleSphere extends StatefulWidget {
  final double size;
  final bool isActive;
  final double audioLevel;

  const ParticleSphere({
    super.key,
    required this.size,
    this.isActive = false,
    this.audioLevel = 0.0,
  });

  @override
  State<ParticleSphere> createState() => _ParticleSphereState();
}

class _ParticleSphereState extends State<ParticleSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    
    // Generate particles on a sphere surface
    for (int i = 0; i < 150; i++) {
      final theta = random.nextDouble() * 2 * math.pi;
      final phi = math.acos(2 * random.nextDouble() - 1);
      
      _particles.add(Particle(
        theta: theta,
        phi: phi,
        radius: widget.size / 2.5,
        phaseOffset: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: ParticleSpherePainter(
            particles: _particles,
            animValue: _animController.value,
            isActive: widget.isActive,
            audioLevel: widget.audioLevel,
          ),
        );
      },
    );
  }
}

class Particle {
  final double theta;
  final double phi;
  final double radius;
  final double phaseOffset;

  Particle({
    required this.theta,
    required this.phi,
    required this.radius,
    required this.phaseOffset,
  });
}

class ParticleSpherePainter extends CustomPainter {
  final List<Particle> particles;
  final double animValue;
  final bool isActive;
  final double audioLevel;

  ParticleSpherePainter({
    required this.particles,
    required this.animValue,
    required this.isActive,
    required this.audioLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Sort particles by z-depth for proper layering
    final sortedParticles = List<_ParticlePosition>.from(
      particles.map((p) => _calculatePosition(p, size, center))
    )..sort((a, b) => a.z.compareTo(b.z));

    // Draw particles
    for (final particle in sortedParticles) {
      _drawParticle(canvas, particle);
    }

    // Draw center glow
    final glowPaint = Paint()
      ..color = const Color(0xFF6366f1).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, size.width / 3, glowPaint);
  }

  _ParticlePosition _calculatePosition(Particle p, Size size, Offset center) {
    // Add wave motion based on animation and audio
    final waveAmount = isActive ? (0.15 + audioLevel * 0.3) : 0.1;
    final wave = math.sin(animValue * 2 * math.pi + p.phaseOffset) * waveAmount;
    final currentRadius = p.radius * (1 + wave);

    // Convert spherical to 3D cartesian
    final x = currentRadius * math.sin(p.phi) * math.cos(p.theta);
    final y = currentRadius * math.sin(p.phi) * math.sin(p.theta);
    final z = currentRadius * math.cos(p.phi);

    // Simple rotation for depth effect
    final rotatedY = y * math.cos(animValue * 0.5) - z * math.sin(animValue * 0.5);
    final rotatedZ = y * math.sin(animValue * 0.5) + z * math.cos(animValue * 0.5);

    // Project to 2D
    final position = Offset(
      center.dx + x,
      center.dy + rotatedY,
    );

    // Calculate opacity based on z-depth
    final depthFactor = (rotatedZ + currentRadius) / (2 * currentRadius);
    final opacity = 0.3 + depthFactor * 0.7;

    // Calculate size based on depth
    final particleSize = 1.5 + depthFactor * 2.0;

    return _ParticlePosition(
      position: position,
      z: rotatedZ,
      opacity: opacity,
      size: particleSize,
    );
  }

  void _drawParticle(Canvas canvas, _ParticlePosition particle) {
    final particlePaint = Paint()
      ..color = const Color(0xFF6366f1).withOpacity(particle.opacity)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF818cf8).withOpacity(particle.opacity * 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);

    canvas.drawCircle(particle.position, particle.size * 2, glowPaint);
    canvas.drawCircle(particle.position, particle.size, particlePaint);
  }

  @override
  bool shouldRepaint(ParticleSpherePainter oldDelegate) => true;
}

class _ParticlePosition {
  final Offset position;
  final double z;
  final double opacity;
  final double size;

  _ParticlePosition({
    required this.position,
    required this.z,
    required this.opacity,
    required this.size,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2a2a4a), Color(0xFF1a1a2e)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🧠',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                const Text(
                  'VibeNote',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Think Out Loud. Understand Deeply.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
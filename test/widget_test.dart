// ignore_for_file: use_super_parameters, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:io';

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
    
    final sortedParticles = List<_ParticlePosition>.from(
      particles.map((p) => _calculatePosition(p, size, center))
    )..sort((a, b) => a.z.compareTo(b.z));

    for (final particle in sortedParticles) {
      _drawParticle(canvas, particle);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF6366f1).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, size.width / 3, glowPaint);
  }

  _ParticlePosition _calculatePosition(Particle p, Size size, Offset center) {
    final waveAmount = isActive ? (0.15 + audioLevel * 0.3) : 0.1;
    final wave = math.sin(animValue * 2 * math.pi + p.phaseOffset) * waveAmount;
    final currentRadius = p.radius * (1 + wave);

    final x = currentRadius * math.sin(p.phi) * math.cos(p.theta);
    final y = currentRadius * math.sin(p.phi) * math.sin(p.theta);
    final z = currentRadius * math.cos(p.phi);

    final rotatedY = y * math.cos(animValue * 0.5) - z * math.sin(animValue * 0.5);
    final rotatedZ = y * math.sin(animValue * 0.5) + z * math.cos(animValue * 0.5);

    final position = Offset(center.dx + x, center.dy + rotatedY);
    final depthFactor = (rotatedZ + currentRadius) / (2 * currentRadius);
    final opacity = 0.3 + depthFactor * 0.7;
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
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThinkingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366f1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Start Thinking',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
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

class ThinkingScreen extends StatefulWidget {
  const ThinkingScreen({super.key});

  @override
  State<ThinkingScreen> createState() => _ThinkingScreenState();
}

class _ThinkingScreenState extends State<ThinkingScreen> {
  final _audioRecorder = AudioRecorder();
  bool isListening = false;
  bool isPaused = false;
  double audioLevel = 0.0;
  String? recordingPath;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndStart();
  }

  Future<void> _requestPermissionAndStart() async {
    final micStatus = await Permission.microphone.request();
    
    if (!micStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    
    // For Android 13+, use manageExternalStorage
    if (await Permission.manageExternalStorage.isGranted) {
      await _startRecording();
    } else {
      final storageStatus = await Permission.manageExternalStorage.request();
      if (storageStatus.isGranted) {
        await _startRecording();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Get Downloads directory
        final directory = Directory('/storage/emulated/0/Download/VibeNote');
        
        // Create VibeNote folder if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory.path}/vibenote_$timestamp.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          isListening = true;
          recordingPath = filePath;
        });

        _listenToAmplitude();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _listenToAmplitude() async {
    while (isListening && mounted && !isPaused) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final amplitude = await _audioRecorder.getAmplitude();
      
      if (mounted) {
        setState(() {
          // Convert dB to 0-1 range (typical speech is -40 to -10 dB)
          final db = amplitude.current;
          if (db < -50) {
            audioLevel = 0.0; // Silence
          } else if (db > -10) {
            audioLevel = 1.0; // Very loud
          } else {
            // Map -50 to -10 dB to 0.0 to 1.0
            audioLevel = (db + 50) / 40;
          }
        });
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _audioRecorder.pause();
    setState(() {
      isPaused = true;
      audioLevel = 0.0;
    });
  }

  Future<void> _resumeRecording() async {
    await _audioRecorder.resume();
    setState(() {
      isPaused = false;
    });
    _listenToAmplitude();
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    
    setState(() {
      isListening = false;
      audioLevel = 0.0;
    });

    if (mounted) {
      if (path != null && path.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording saved to:\n$path'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording failed to save'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
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
            colors: [Color(0xFF1a1a3e), Color(0xFF0f0f1e)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: VoiceReactiveHologram(
                  audioLevel: audioLevel,
                  isActive: isListening && !isPaused,
                ),
              ),
              
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: isPaused ? Icons.play_arrow : Icons.pause,
                      onTap: () {
                        if (isPaused) {
                          _resumeRecording();
                        } else {
                          _pauseRecording();
                        }
                      },
                    ),
                    
                    _buildControlButton(
                      icon: Icons.stop,
                      onTap: _stopRecording,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF6366f1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366f1).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class VoiceReactiveHologram extends StatefulWidget {
  final double audioLevel;
  final bool isActive;

  const VoiceReactiveHologram({
    super.key,
    required this.audioLevel,
    required this.isActive,
  });

  @override
  State<VoiceReactiveHologram> createState() => _VoiceReactiveHologramState();
}

class _VoiceReactiveHologramState extends State<VoiceReactiveHologram>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<VoiceParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    
    for (int i = 0; i < 200; i++) {
      final theta = random.nextDouble() * 2 * math.pi;
      final phi = math.acos(2 * random.nextDouble() - 1);
      
      _particles.add(VoiceParticle(
        theta: theta,
        phi: phi,
        baseRadius: 80 + random.nextDouble() * 20,
        phaseOffset: random.nextDouble() * 2 * math.pi,
        speed: 0.5 + random.nextDouble() * 0.5,
        spikeAmount: random.nextDouble(),
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
          size: const Size(300, 300),
          painter: VoiceHologramPainter(
            particles: _particles,
            animValue: _animController.value,
            audioLevel: widget.audioLevel,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

class VoiceParticle {
  final double theta;
  final double phi;
  final double baseRadius;
  final double phaseOffset;
  final double speed;
  final double spikeAmount;

  VoiceParticle({
    required this.theta,
    required this.phi,
    required this.baseRadius,
    required this.phaseOffset,
    required this.speed,
    required this.spikeAmount,
  });
}

class VoiceHologramPainter extends CustomPainter {
  final List<VoiceParticle> particles;
  final double animValue;
  final double audioLevel;
  final bool isActive;

  VoiceHologramPainter({
    required this.particles,
    required this.animValue,
    required this.audioLevel,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final sortedParticles = List<_VoiceParticlePosition>.from(
      particles.map((p) => _calculatePosition(p, size, center))
    )..sort((a, b) => a.z.compareTo(b.z));

    for (final particle in sortedParticles) {
      _drawParticle(canvas, particle);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF6366f1).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(center, size.width / 2.5, glowPaint);
  }

  _VoiceParticlePosition _calculatePosition(VoiceParticle p, Size size, Offset center) {
    // Only show breathing when truly silent (audioLevel near 0)
    final breathAmount = audioLevel < 0.05 ? 0.05 : 0.0;
    final breath = math.sin(animValue * 2 * math.pi * 0.3) * breathAmount;
    
    // Voice drives expansion - main reactive effect
    final voiceExpansion = audioLevel * 0.6;
    
    // Spikes only appear with voice activity
    final spikePhase = math.sin(animValue * 2 * math.pi * p.speed + p.phaseOffset);
    final spike = (p.spikeAmount > 0.7 && audioLevel > 0.3) 
        ? spikePhase * 0.2 * audioLevel 
        : 0.0;
    
    // Jitter only for loud/fast speech
    final jitter = audioLevel > 0.7 
        ? (math.Random().nextDouble() - 0.5) * 0.12 * audioLevel 
        : 0.0;
    
    // Minimal wave only during silence
    final wave = audioLevel < 0.05 
        ? math.sin(animValue * 2 * math.pi * p.speed + p.phaseOffset) * 0.03 
        : 0.0;
    
    final currentRadius = p.baseRadius * (1 + breath + voiceExpansion + wave + spike + jitter);

    final x = currentRadius * math.sin(p.phi) * math.cos(p.theta);
    final y = currentRadius * math.sin(p.phi) * math.sin(p.theta);
    final z = currentRadius * math.cos(p.phi);

    final rotY = y * math.cos(animValue * 0.3) - z * math.sin(animValue * 0.3);
    final rotZ = y * math.sin(animValue * 0.3) + z * math.cos(animValue * 0.3);

    final position = Offset(center.dx + x, center.dy + rotY);

    final depthFactor = (rotZ + currentRadius) / (2 * currentRadius);
    
    // Brightness increases with voice
    final baseOpacity = audioLevel > 0.1 ? 0.5 + (audioLevel * 0.3) : 0.2;
    final opacity = baseOpacity + depthFactor * 0.5;

    final particleSize = 0.8 + depthFactor * 1.5;

    return _VoiceParticlePosition(
      position: position,
      z: rotZ,
      opacity: opacity,
      size: particleSize,
    );
  }

  void _drawParticle(Canvas canvas, _VoiceParticlePosition particle) {
    final particlePaint = Paint()
      ..color = const Color(0xFF818cf8).withOpacity(particle.opacity)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF6366f1).withOpacity(particle.opacity * 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);

    canvas.drawCircle(particle.position, particle.size * 2, glowPaint);
    canvas.drawCircle(particle.position, particle.size, particlePaint);
  }

  @override
  bool shouldRepaint(VoiceHologramPainter oldDelegate) => true;
}

class _VoiceParticlePosition {
  final Offset position;
  final double z;
  final double opacity;
  final double size;

  _VoiceParticlePosition({
    required this.position,
    required this.z,
    required this.opacity,
    required this.size,
  });
}
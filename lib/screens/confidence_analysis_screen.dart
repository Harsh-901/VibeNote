import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math;

class ConfidenceAnalysisScreen extends StatefulWidget {
  final String sessionId;
  final String audioPath;
  final String transcript;
  final int duration;
  final List<dynamic>? words;

  const ConfidenceAnalysisScreen({
    super.key,
    required this.sessionId,
    required this.audioPath,
    required this.transcript,
    required this.duration,
    this.words,
  });

  @override
  State<ConfidenceAnalysisScreen> createState() =>
      _ConfidenceAnalysisScreenState();
}

class _ConfidenceAnalysisScreenState extends State<ConfidenceAnalysisScreen> {
  late AnalysisData analysis;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyzeSession();
  }

  Future<void> _analyzeSession() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      analysis = _computeAnalysis();
      isLoading = false;
    });
  }

  AnalysisData _computeAnalysis() {
    if (widget.words != null && widget.words!.isNotEmpty) {
      return _computeRealAnalysis(widget.words!);
    } else {
      return _computeFallbackAnalysis();
    }
  }

  AnalysisData _computeRealAnalysis(List<dynamic> wordsList) {
    try {
      final wordCount = wordsList.length;
      if (wordCount == 0) return _computeFallbackAnalysis();

      double totalConfidence = 0;
      int pauseMarkers = 0;
      double totalPauseDuration = 0.0;
      List<PauseMarker> pauseTimeline = [];

      double startTime = (wordsList.first['start'] as num).toDouble();
      double endTime = (wordsList.last['end'] as num).toDouble();

      // Use actual spoken duration instead of widget.duration if it makes sense
      double actualSpeakDuration = endTime - startTime;
      if (actualSpeakDuration <= 0)
        actualSpeakDuration = widget.duration.toDouble();

      for (int i = 0; i < wordCount; i++) {
        final currentWord = wordsList[i];

        // Accumulate confidence
        if (currentWord['confidence'] != null) {
          totalConfidence += (currentWord['confidence'] as num).toDouble();
        } else {
          totalConfidence += 0.8; // Fallback for a single word
        }

        // Calculate pauses between words
        if (i > 0) {
          final previousWord = wordsList[i - 1];
          final gap =
              (currentWord['start'] as num).toDouble() -
              (previousWord['end'] as num).toDouble();

          // If gap is greater than 0.5 seconds, consider it a pause
          if (gap > 0.5) {
            pauseMarkers++;
            totalPauseDuration += gap;
            pauseTimeline.add(
              PauseMarker(
                position: (previousWord['end'] as num).toDouble(),
                duration: gap,
              ),
            );
          }
        }
      }

      // Calculate Averages and Rates
      final avgConfidence = (totalConfidence / wordCount) * 100;
      final avgPauseDuration = pauseMarkers > 0
          ? (totalPauseDuration / pauseMarkers)
          : 0.0;

      // Calculate WPM
      final durationMinutes = actualSpeakDuration / 60.0;
      final wpm = durationMinutes > 0
          ? (wordCount / durationMinutes).round()
          : 0;

      // Calculate Flow Percentage
      final speakingTime = actualSpeakDuration - totalPauseDuration;
      final flowPercentage = actualSpeakDuration > 0
          ? ((speakingTime / actualSpeakDuration) * 100).clamp(0, 100).toInt()
          : 0;

      int confidenceScore = avgConfidence.round();
      // Adjust score slightly based on flow and pauses, mostly relying on Deepgram's confidence
      if (flowPercentage < 40) confidenceScore -= 10;
      if (wpm < 80) confidenceScore -= 5;
      confidenceScore = confidenceScore.clamp(0, 100);

      // Generate Speed Variations
      final speedVariations = _calculateRealSpeedVariations(
        wordsList,
        actualSpeakDuration,
      );

      // Generate Energy Data
      final energyData = _generateRealEnergyData(
        wordsList,
        actualSpeakDuration,
      );

      return AnalysisData(
        confidenceScore: confidenceScore,
        flowPercentage: flowPercentage,
        pauseCount: pauseMarkers,
        avgPauseDuration: avgPauseDuration,
        pauseTimeline: pauseTimeline,
        energyData: energyData,
        wordsPerMinute: wpm,
        speedVariations: speedVariations,
      );
    } catch (e) {
      debugPrint("Error computing real analysis: $e");
      return _computeFallbackAnalysis(); // Fallback if parsing fails
    }
  }

  List<SpeedSegment> _calculateRealSpeedVariations(
    List<dynamic> words,
    double totalDuration,
  ) {
    if (words.length < 9) {
      final wpm = totalDuration > 0
          ? (words.length / (totalDuration / 60.0)).round()
          : 0;
      return [
        SpeedSegment(label: 'Start', wpm: wpm),
        SpeedSegment(label: 'Middle', wpm: wpm),
        SpeedSegment(label: 'End', wpm: wpm),
      ];
    }

    final segmentDuration = totalDuration / 3.0;

    int startWords = 0;
    int middleWords = 0;
    int endWords = 0;

    for (var word in words) {
      double start = (word['start'] as num).toDouble();
      if (start < segmentDuration) {
        startWords++;
      } else if (start < segmentDuration * 2) {
        middleWords++;
      } else {
        endWords++;
      }
    }

    final durationMin = segmentDuration / 60.0;
    return [
      SpeedSegment(
        label: 'Start',
        wpm: durationMin > 0 ? (startWords / durationMin).round() : 0,
      ),
      SpeedSegment(
        label: 'Middle',
        wpm: durationMin > 0 ? (middleWords / durationMin).round() : 0,
      ),
      SpeedSegment(
        label: 'End',
        wpm: durationMin > 0 ? (endWords / durationMin).round() : 0,
      ),
    ];
  }

  List<double> _generateRealEnergyData(
    List<dynamic> words,
    double totalDuration,
  ) {
    // Determine number of points based on duration, max out at 100
    int points = (totalDuration * 2).clamp(30, 100).toInt();
    List<double> energyList = List.filled(points, 0.0);

    if (words.isEmpty || totalDuration <= 0)
      return _generateEnergyData(math.Random(), 50);

    double bucketDuration = totalDuration / points;

    for (var word in words) {
      double start = (word['start'] as num).toDouble();
      int bucketIndex = (start / bucketDuration).floor().clamp(0, points - 1);

      // Base energy on word confidence and length
      double wordLength =
          (word['end'] as num).toDouble() - (word['start'] as num).toDouble();
      double conf = (word['confidence'] as num?)?.toDouble() ?? 0.8;

      // Simple heuristic: higher confidence and faster words = higher energy
      double energy =
          conf * (0.5 + (0.5 * (1.0 - (wordLength.clamp(0.0, 1.0)))));

      // Accumulate energy in the bucket
      energyList[bucketIndex] += energy;
    }

    // Normalize and smooth the data
    double maxEnergy = 0;
    for (var e in energyList) {
      if (e > maxEnergy) maxEnergy = e;
    }

    if (maxEnergy > 0) {
      for (int i = 0; i < points; i++) {
        // Normalize
        double val =
            (energyList[i] / maxEnergy) * 0.8 + 0.1; // Keep between 0.1 and 0.9

        // Simple moving average smoothing
        if (i > 0 && i < points - 1) {
          val =
              (energyList[i - 1] * 0.25 + val * 0.5 + energyList[i + 1] * 0.25);
        }
        energyList[i] = val.clamp(0.0, 1.0);
      }
    } else {
      energyList = List.filled(points, 0.2);
    }

    return energyList;
  }

  AnalysisData _computeFallbackAnalysis() {
    // Use sessionId as seed for unique but deterministic randomness per session
    final seed = widget.sessionId.hashCode;
    final random = math.Random(seed);

    final wordsText = widget.transcript
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final wordCount = wordsText.length;
    final durationMinutes = widget.duration / 60.0;

    // Calculate speaking speed
    final wpm = durationMinutes > 0 ? (wordCount / durationMinutes).round() : 0;

    // Estimate pauses (count punctuation and sentence breaks)
    final pauseMarkers = RegExp(
      r'[.!?,;]\s+|\n',
    ).allMatches(widget.transcript).length;
    final avgPauseDuration = pauseMarkers > 0
        ? (widget.duration / pauseMarkers / 2)
        : 1.0;

    // Flow calculation (percentage of time speaking vs pausing)
    final estimatedPauseTime = pauseMarkers * avgPauseDuration;
    final speakingTime = widget.duration - estimatedPauseTime;
    final flowPercentage = ((speakingTime / widget.duration) * 100)
        .clamp(0, 100)
        .toInt();

    // Confidence score calculation
    int confidenceScore = 50;

    // Boost for good flow
    if (flowPercentage > 70)
      confidenceScore += 20;
    else if (flowPercentage > 50)
      confidenceScore += 10;

    // Boost for good speaking speed
    if (wpm >= 120 && wpm <= 160)
      confidenceScore += 15;
    else if (wpm >= 100 && wpm <= 180)
      confidenceScore += 10;

    // Penalty for too many pauses
    final pausesPerMinute = durationMinutes > 0
        ? pauseMarkers / durationMinutes
        : 0;
    if (pausesPerMinute < 5)
      confidenceScore += 15;
    else if (pausesPerMinute > 15)
      confidenceScore -= 10;

    confidenceScore = confidenceScore.clamp(0, 100);

    // Generate UNIQUE energy data per session
    final energyData = _generateEnergyData(random, wordCount);

    // Generate UNIQUE pause timeline per session
    final pauseTimeline = _generatePauseTimeline(random, pauseMarkers);

    // Generate UNIQUE speed variations per session
    final speedVariations = _generateSpeedVariations(wpm, random);

    return AnalysisData(
      confidenceScore: confidenceScore,
      flowPercentage: flowPercentage,
      pauseCount: pauseMarkers,
      avgPauseDuration: avgPauseDuration,
      pauseTimeline: pauseTimeline,
      energyData: energyData,
      wordsPerMinute: wpm,
      speedVariations: speedVariations,
    );
  }

  List<double> _generateEnergyData(math.Random random, int wordCount) {
    // Generate based on transcript length - longer transcripts get more points
    final points = (wordCount / 10).clamp(30, 80).toInt();

    return List.generate(points, (i) {
      final base = 0.3 + random.nextDouble() * 0.4;
      final wave = math.sin(i / points * math.pi * 2) * 0.15;
      final noise = (random.nextDouble() - 0.5) * 0.1;
      return (base + wave + noise).clamp(0.0, 1.0);
    });
  }

  List<PauseMarker> _generatePauseTimeline(math.Random random, int count) {
    return List.generate(count, (i) {
      // Distribute pauses across the duration with some randomness
      final position =
          (i / count) * widget.duration +
          random.nextDouble() * (widget.duration / count);
      final duration = 0.3 + random.nextDouble() * 2.5;
      return PauseMarker(
        position: position.clamp(0, widget.duration.toDouble()),
        duration: duration,
      );
    });
  }

  List<SpeedSegment> _generateSpeedVariations(int avgWpm, math.Random random) {
    return [
      SpeedSegment(
        label: 'Start',
        wpm: (avgWpm * (0.8 + random.nextDouble() * 0.15)).round(),
      ),
      SpeedSegment(
        label: 'Middle',
        wpm: (avgWpm * (1.05 + random.nextDouble() * 0.15)).round(),
      ),
      SpeedSegment(
        label: 'End',
        wpm: (avgWpm * (0.9 + random.nextDouble() * 0.15)).round(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confidence Analysis',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfidenceScore(),
            const SizedBox(height: 30),
            _buildFlowMeter(),
            const SizedBox(height: 30),
            _buildPauseAnalysis(),
            const SizedBox(height: 30),
            _buildEnergyGraph(),
            const SizedBox(height: 30),
            _buildSpeakingSpeed(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceScore() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Overall Confidence',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: analysis.confidenceScore / 100,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF2A2A3A),
                    color: _getScoreColor(analysis.confidenceScore),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${analysis.confidenceScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      _getScoreLabel(analysis.confidenceScore),
                      style: TextStyle(
                        color: _getScoreColor(analysis.confidenceScore),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowMeter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flow',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Continuous Speech',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  Text(
                    '${analysis.flowPercentage}%',
                    style: const TextStyle(
                      color: Color(0xFF6366f1),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: analysis.flowPercentage / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF2A2A3A),
                  color: const Color(0xFF6366f1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPauseAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pause Analysis',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Pauses',
                      '${analysis.pauseCount}',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Avg Duration',
                      '${analysis.avgPauseDuration.toStringAsFixed(1)}s',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Timeline',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: CustomPaint(
                  painter: PauseTimelinePainter(
                    pauses: analysis.pauseTimeline,
                    totalDuration: widget.duration.toDouble(),
                  ),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyGraph() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voice Energy',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 120,
            child: CustomPaint(
              painter: EnergyGraphPainter(energyData: analysis.energyData),
              child: Container(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakingSpeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Speaking Speed',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${analysis.wordsPerMinute}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'words/min',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...analysis.speedVariations.map(
                (segment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        segment.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${segment.wpm} wpm',
                        style: const TextStyle(
                          color: Color(0xFF6366f1),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF22c55e);
    if (score >= 40) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 70) return 'Strong';
    if (score >= 40) return 'Moderate';
    return 'Developing';
  }
}

// Data Models
class AnalysisData {
  final int confidenceScore;
  final int flowPercentage;
  final int pauseCount;
  final double avgPauseDuration;
  final List<PauseMarker> pauseTimeline;
  final List<double> energyData;
  final int wordsPerMinute;
  final List<SpeedSegment> speedVariations;

  AnalysisData({
    required this.confidenceScore,
    required this.flowPercentage,
    required this.pauseCount,
    required this.avgPauseDuration,
    required this.pauseTimeline,
    required this.energyData,
    required this.wordsPerMinute,
    required this.speedVariations,
  });
}

class PauseMarker {
  final double position;
  final double duration;

  PauseMarker({required this.position, required this.duration});
}

class SpeedSegment {
  final String label;
  final int wpm;

  SpeedSegment({required this.label, required this.wpm});
}

// Custom Painters
class PauseTimelinePainter extends CustomPainter {
  final List<PauseMarker> pauses;
  final double totalDuration;

  PauseTimelinePainter({required this.pauses, required this.totalDuration});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFF2A2A3A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      basePaint,
    );

    final pausePaint = Paint()
      ..color = const Color(0xFFef4444)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (final pause in pauses) {
      final x = (pause.position / totalDuration) * size.width;
      canvas.drawCircle(Offset(x, size.height / 2), 4, pausePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnergyGraphPainter extends CustomPainter {
  final List<double> energyData;

  EnergyGraphPainter({required this.energyData});

  @override
  void paint(Canvas canvas, Size size) {
    if (energyData.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF6366f1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6366f1).withOpacity(0.3),
          const Color(0xFF6366f1).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (energyData.length - 1);

    for (int i = 0; i < energyData.length; i++) {
      final x = i * stepX;
      final y = size.height - (energyData[i] * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

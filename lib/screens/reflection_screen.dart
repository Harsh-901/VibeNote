import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// Add to pubspec.yaml:
// speech_to_text: ^6.6.0
// http: ^1.1.0

class TranscriptionService {
  final SpeechToText _speechToText = SpeechToText();
  
  // Method 1: Using Flutter's speech_to_text (real-time)
  Future<Map<String, dynamic>> transcribeRealtime(File audioFile) async {
    bool available = await _speechToText.initialize();
    
    if (!available) {
      throw Exception('Speech recognition not available');
    }
    
    String transcription = '';
    String detectedLanguage = 'English';
    
    // Listen and transcribe
    await _speechToText.listen(
      onResult: (result) {
        transcription = result.recognizedWords;
        detectedLanguage = 'en-US';
      },
    );
    
    return {
      'transcript': transcription,
      'language': _mapLanguageCode(detectedLanguage),
    };
  }
  
  // Method 2: Using OpenAI Whisper API (more accurate, supports multiple languages)
  Future<Map<String, dynamic>> transcribeWithWhisper(File audioFile) async {
    const apiKey = 'YOUR_OPENAI_API_KEY'; // Replace with your key
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );
    
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.files.add(await http.MultipartFile.fromPath('file', audioFile.path));
    request.fields['model'] = 'whisper-1';
    request.fields['response_format'] = 'verbose_json'; // Get language detection
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = jsonDecode(responseData);
    
    return {
      'transcript': jsonData['text'],
      'language': _mapLanguageCode(jsonData['language']),
    };
  }
  
  // Method 3: Using Google Cloud Speech-to-Text
  Future<Map<String, dynamic>> transcribeWithGoogle(File audioFile) async {
    const apiKey = 'YOUR_GOOGLE_API_KEY'; // Replace with your key
    
    // Read audio file as base64
    final bytes = await audioFile.readAsBytes();
    final audioContent = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'config': {
          'encoding': 'LINEAR16',
          'languageCode': 'en-US', // Auto-detect or specify
          'alternativeLanguageCodes': ['hi-IN', 'mr-IN'], // Add languages
          'enableAutomaticPunctuation': true,
        },
        'audio': {
          'content': audioContent,
        },
      }),
    );
    
    var jsonData = jsonDecode(response.body);
    var result = jsonData['results'][0];
    
    return {
      'transcript': result['alternatives'][0]['transcript'],
      'language': _mapLanguageCode(result['languageCode']),
    };
  }
  
  String _mapLanguageCode(String code) {
    if (code.contains('en')) return 'English';
    if (code.contains('hi')) return 'Hindi';
    if (code.contains('mr')) return 'Marathi';
    if (code.contains('mixed')) return 'Hinglish';
    return 'English';
  }
}

// AI Service for generating summary
class AIService {
  Future<String> generateSummary(String transcript, String language) async {
    const apiKey = 'YOUR_OPENAI_API_KEY';
    
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a reflection assistant. Generate concise summaries in the SAME language as the input. If Hindi/Marathi, respond in Hindi/Marathi.',
          },
          {
            'role': 'user',
            'content': 'Summarize this reflection in 2-3 sentences in $language:\n\n$transcript',
          },
        ],
      }),
    );
    
    var jsonData = jsonDecode(response.body);
    return jsonData['choices'][0]['message']['content'];
  }
}

// Updated Recording Screen Integration
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  RecordingScreenState createState() => RecordingScreenState();
}

class RecordingScreenState extends State<RecordingScreen> {
  // final TranscriptionService _transcriptionService = TranscriptionService();
  // final AIService _aiService = AIService();
  
  bool isProcessing = false;
  String processingStatus = '';
  
  // Call this after recording completes
  
  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                processingStatus,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    // Your existing recording UI
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Text('Recording UI', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Keep your existing ReflectionLibraryScreen code unchanged
class ReflectionLibraryScreen extends StatefulWidget {
  const ReflectionLibraryScreen({super.key});

  @override
  ReflectionLibraryScreenState createState() => ReflectionLibraryScreenState();
}

class ReflectionLibraryScreenState extends State<ReflectionLibraryScreen> {
  List<Session> sessions = [];
  Session? selectedSession;
  bool showTranslation = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList('sessions') ?? [];

      final loadedSessions = sessionsJson.map((sessionJson) {
        final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
        return Session(
          id: sessionMap['id'] as String,
          timestamp: DateTime.parse(sessionMap['timestamp'] as String),
          duration: sessionMap['duration'] as int,
          language: sessionMap['language'] as String,
          transcript: sessionMap['transcript'] as String,
          summary: sessionMap['summary'] as String,
          translatedTranscript: null,
        );
      }).toList();

      loadedSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        sessions = loadedSessions;
      });
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      setState(() {
        sessions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedSession != null) {
      return _buildDetailView();
    }
    return _buildListView();
  }

  Widget _buildListView() {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reflection',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: sessions.isEmpty
          ? Center(
              child: Text(
                'No sessions yet',
                style: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(session);
              },
            ),
    );
  }

  Widget _buildSessionCard(Session session) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedSession = session;
              showTranslation = false;
            });
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(session.timestamp),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white30,
                      size: 20,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white38, size: 16),
                    SizedBox(width: 6),
                    Text(
                      _formatDuration(session.duration),
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    SizedBox(width: 20),
                    Icon(Icons.language, color: Colors.white38, size: 16),
                    SizedBox(width: 6),
                    Text(
                      session.language,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
          onPressed: () {
            setState(() {
              selectedSession = null;
              showTranslation = false;
            });
          },
        ),
        title: Text(
          _formatDate(selectedSession!.timestamp),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white38, size: 16),
                SizedBox(width: 6),
                Text(
                  _formatDuration(selectedSession!.duration),
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                SizedBox(width: 20),
                Icon(Icons.language, color: Colors.white38, size: 16),
                SizedBox(width: 6),
                Text(
                  selectedSession!.language,
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 30),
            Text(
              'Transcript',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                showTranslation && selectedSession!.translatedTranscript != null
                    ? selectedSession!.translatedTranscript!
                    : selectedSession!.transcript,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Reflection Summary',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedSession!.summary,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (sessionDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}

class Session {
  final String id;
  final DateTime timestamp;
  final int duration;
  final String language;
  final String transcript;
  final String summary;
  final String? translatedTranscript;

  Session({
    required this.id,
    required this.timestamp,
    required this.duration,
    required this.language,
    required this.transcript,
    required this.summary,
    this.translatedTranscript,
  });
}
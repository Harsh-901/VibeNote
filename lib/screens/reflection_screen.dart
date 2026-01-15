import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
          translatedTranscript: null, // For now, no translation
        );
      }).toList();

      // Sort by timestamp (newest first)
      loadedSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        sessions = loadedSessions;
      });
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      // If loading fails, show empty list
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
            // Session Info
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

            // Transcript
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

            // Summary
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
            SizedBox(height: 30),

            // Translate Button
            if (selectedSession!.translatedTranscript != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showTranslation = !showTranslation;
                    });
                  },
                  icon: Icon(
                    Icons.translate,
                    size: 18,
                    color: showTranslation ? Color(0xFF0A0A0F) : Colors.white,
                  ),
                  label: Text(
                    showTranslation ? 'Show Original' : 'Translate to English',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: showTranslation ? Color(0xFF0A0A0F) : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showTranslation ? Colors.white : Color(0xFF2A2A3A),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
  final int duration; // in seconds
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
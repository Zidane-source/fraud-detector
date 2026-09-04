import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const FraudDetectorApp());
}

class FraudDetectorApp extends StatelessWidget {
  const FraudDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singapore Fraud Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── COLOURS ───────────────────────────────────────────
const kDarkGreen = Color(0xFF1B5E20);
const kGreen = Color(0xFF2E7D32);
const kLightGreen = Color(0xFFE8F5E9);
const kBorderGreen = Color(0xFFC8E6C9);
const kBackground = Color(0xFFF0F7F1);
const kBlack = Color(0xFF1A1A1A);

// ─── HOME SCREEN ───────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _screen = 1;
  Map<String, dynamic>? _result;
  String _inputText = '';
  File? _uploadedImage;
  bool _isLoading = false;

  final String _backendUrl = 'http://10.0.2.2:8000';

  Future<void> _analyse() async {
    setState(() {
      _screen = 2;
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (_uploadedImage != null) {
        // Image analysis
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_backendUrl/analyse/image'),
        );
        request.files.add(
          await http.MultipartFile.fromPath('file', _uploadedImage!.path),
        );
       var streamedResponse = await request.send();
var response = await http.Response.fromStream(streamedResponse);
result = json.decode(response.body);
      } else {
        // Text analysis
        var response = await http.post(
  Uri.parse('$_backendUrl/analyse/text'),
  body: {'message': _inputText},
);
result = Map<String, dynamic>.from(json.decode(response.body));
      }

      setState(() {
        _result = result;
        _screen = 3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _screen = 1;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _uploadedImage = File(picked.path);
      });
    }
  }

  void _reset() {
    setState(() {
      _screen = 1;
      _result = null;
      _inputText = '';
      _uploadedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildProgressBar(),
              const SizedBox(height: 16),
              if (_screen == 1) _buildUploadScreen(),
              if (_screen == 2) _buildAnalysingScreen(),
              if (_screen == 3) _buildResultsScreen(),
              if (_screen == 4) _buildNextStepsScreen(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGreen),
      ),
      child: const Column(
        children: [
          Text(
            '🛡️ Singapore Fraud Detector',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kDarkGreen,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Powered by AI · Protect yourself from scams',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS BAR ────────────────────────────────────
  Widget _buildProgressBar() {
    final steps = ['📤 Upload', '🔍 Analysing', '📊 Results', '✅ Next Steps'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i + 1 == _screen;
        final isDone = i + 1 < _screen;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(
              vertical: isActive ? 10 : 6,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? kDarkGreen
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: kDarkGreen.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Text(
              steps[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isActive ? 11 : 10,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : isDone
                        ? const Color(0xFFA5D6A7)
                        : const Color(0xFF555555),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── SCREEN 1 — UPLOAD ───────────────────────────────
  Widget _buildUploadScreen() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload or paste suspicious content',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kBlack,
            ),
          ),
          const SizedBox(height: 16),

          // Upload zone
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FFF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFA5D6A7),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Text('📁', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload screenshot',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Supports PNG, JPG, JPEG',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (_uploadedImage != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '✅ Image selected',
                      style: TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '— or paste message / link —',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

          // Text input
          TextField(
            maxLines: 4,
            onChanged: (val) => _inputText = val,
            decoration: InputDecoration(
              hintText:
                  "e.g. 'Your DBS account has been suspended. Click: dbs-secure-login.com/verify'",
              hintStyle:
                  const TextStyle(fontSize: 12, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBorderGreen),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kGreen),
              ),
              filled: true,
              fillColor: const Color(0xFFFAFFF9),
            ),
          ),

          const SizedBox(height: 16),

          // Analyse button
          ElevatedButton(
            onPressed: () {
              if (_uploadedImage == null && _inputText.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please upload a screenshot or paste a message first.'),
                  ),
                );
                return;
              }
              _analyse();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Analyse for fraud →',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SCREEN 2 — ANALYSING ────────────────────────────
  Widget _buildAnalysingScreen() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderGreen),
      ),
      child: Column(
        children: [
          _HoverEmoji(),
          const SizedBox(height: 16),
          const Text(
            'Analysing for fraud...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our AI is scanning your content',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: kGreen),
          const SizedBox(height: 24),
          _buildCheckItem('✓', 'Checking URL structure', true),
          _buildCheckItem('✓', 'Scanning for urgency language', true),
          _buildCheckItem('⟳', 'Detecting impersonation patterns', false),
          _buildCheckItem('○', 'Calculating risk score', false),
          _buildCheckItem('○', 'Generating recommendations', false),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String icon, String text, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: done ? kLightGreen : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 10,
                  color: done ? kGreen : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: done ? kBlack : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SCREEN 3 — RESULTS ──────────────────────────────
  Widget _buildResultsScreen() {
    if (_result == null) return const SizedBox();

    final score = _result!['risk_score'] as int? ?? 5;
    final verdict = _result!['verdict'] as String? ?? 'MEDIUM RISK';
    final summary = _result!['summary'] as String? ?? '';
    final flags = _result!['flags'] as List? ?? [];
    final phrases = _result!['highlighted_phrases'] as List? ?? [];
    final urlParts = _result!['url_parts'] as List? ?? [];

    Color scoreColor = kGreen;
    if (score > 6) scoreColor = const Color(0xFFEF5350);
    else if (score > 3) scoreColor = const Color(0xFFFF9800);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Risk score card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderGreen),
          ),
          child: Column(
            children: [
              const Text(
                'Risk Assessment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      '/10',
                      style: TextStyle(fontSize: 12, color: scoreColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⚠️ $verdict',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                summary,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Flags card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why it\'s suspicious',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 8),
              ...flags.map((flag) {
                Color dotColor = kGreen;
                if (flag['severity'] == 'red') {
                  dotColor = const Color(0xFFEF5350);
                } else if (flag['severity'] == 'orange') {
                  dotColor = const Color(0xFFFF9800);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flag['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kBlack,
                              ),
                            ),
                            Text(
                              flag['reason'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Highlighted phrases
        if (phrases.isNotEmpty && _inputText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorderGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suspicious message breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHighlightedText(phrases),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kLightGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderGreen),
                  ),
                  child: const Text(
                    '👇 Tap highlighted words to learn why they are suspicious',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: kDarkGreen),
                  ),
                ),
                const SizedBox(height: 12),
                ...phrases.map((phrase) => _buildExpandablePhraseCard(phrase)),
              ],
            ),
          ),
        ],

        // URL parts
        if (urlParts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorderGreen),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suspicious link breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kLightGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderGreen),
                  ),
                  child: const Text(
                    '👇 Tap each part of the link to understand why it is suspicious',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: kDarkGreen),
                  ),
                ),
                const SizedBox(height: 12),
                ...urlParts.map((part) => _buildExpandableUrlCard(part)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _screen = 4),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'View next steps →',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(List phrases) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: RichText(
        text: _buildRichText(phrases),
      ),
    );
  }

  TextSpan _buildRichText(List phrases) {
    String text = _inputText;
    List<TextSpan> spans = [];
    int currentIndex = 0;

    List<Map<String, dynamic>> sortedPhrases = phrases
        .map((p) => Map<String, dynamic>.from(p))
        .toList()
      ..sort((a, b) =>
          text.indexOf(a['phrase']).compareTo(text.indexOf(b['phrase'])));

    for (var phrase in sortedPhrases) {
      String p = phrase['phrase'];
      int index = text.indexOf(p, currentIndex);
      if (index == -1) continue;

      if (index > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, index),
          style: const TextStyle(
            fontSize: 14,
            color: kBlack,
            height: 1.8,
          ),
        ));
      }

      Color bg = phrase['severity'] == 'red'
          ? const Color(0xFFFFCDD2)
          : const Color(0xFFFFE0B2);
      Color tc = phrase['severity'] == 'red'
          ? const Color(0xFFC62828)
          : const Color(0xFFE65100);

      spans.add(TextSpan(
        text: p,
        style: TextStyle(
          fontSize: 14,
          color: tc,
          backgroundColor: bg,
          fontWeight: FontWeight.w600,
          height: 1.8,
        ),
      ));

      currentIndex = index + p.length;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: const TextStyle(
          fontSize: 14,
          color: kBlack,
          height: 1.8,
        ),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildExpandablePhraseCard(Map phrase) {
    final sev = phrase['severity'];
    final icon = sev == 'red' ? '🔴' : '🟠';
    return _ExpandableCard(
      title: '$icon  ${phrase['phrase']}',
      explanation: phrase['explanation'] ?? '',
    );
  }

  Widget _buildExpandableUrlCard(Map part) {
    final status = part['status'];
    final icon = status == 'safe' ? '✅' : status == 'danger' ? '🔴' : '⚠️';
    return _ExpandableCard(
      title: '$icon  ${part['part']}',
      explanation: part['explanation'] ?? '',
    );
  }

  // ─── SCREEN 4 — NEXT STEPS ───────────────────────────
  Widget _buildNextStepsScreen() {
    if (_result == null) return const SizedBox();
    final nextSteps = _result!['next_steps'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Immediate actions to take',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 12),
              ...nextSteps.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: kLightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$i',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kBlack,
                              ),
                            ),
                            Text(
                              step['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderGreen),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report to Singapore authorities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kBlack,
                ),
              ),
              const SizedBox(height: 12),
              _buildReportLink('🛡️ ScamShield — Report scam message'),
              _buildReportLink('👮 Singapore Police Force — Lodge a report'),
              _buildReportLink('🏦 MAS — Report financial scam'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            '← Check another message',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildReportLink(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kLightGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderGreen),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kDarkGreen,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: kGreen),
        ],
      ),
    );
  }
}

// ─── EXPANDABLE CARD WIDGET ──────────────────────────
class _ExpandableCard extends StatefulWidget {
  final String title;
  final String explanation;

  const _ExpandableCard({
    required this.title,
    required this.explanation,
  });

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  widget.explanation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _HoverEmoji extends StatefulWidget {
  @override
  State<_HoverEmoji> createState() => _HoverEmojiState();
}

class _HoverEmojiState extends State<_HoverEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: const Text('🔍', style: TextStyle(fontSize: 48)),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_player_state.dart';
import 'home_page.dart';
import 'video_player_page.dart';
import 'game_dialogs.dart';

class GameOptionsPage extends StatefulWidget {
  const GameOptionsPage({super.key});

  @override
  State<GameOptionsPage> createState() => _GameOptionsPageState();
}

class _GameOptionsPageState extends State<GameOptionsPage> {
  int humanPlayers = 1;
  final List<TextEditingController> _nameControllers = [
    TextEditingController(text: 'The Candidate')
  ];
  bool addAi1 = true;
  bool addAi2 = true;
  bool addAi3 = false;
  bool addAi4 = false;
  bool addAi5 = false; 
  int gridSize = 5;
  
  double decidedThresholdPercentage = 0.51;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenRules = prefs.getBool('has_seen_rules_v1') ?? false;
    
    if (!hasSeenRules) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRules(isFirstTime: true);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showRules({bool isFirstTime = false}) {
    GameDialogs.showDossier(context, isFirstTime: isFirstTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMPAIGN CONFIGURATION'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book, color: Color(0xFFC5A059)),
            onPressed: _showRules,
            tooltip: 'Read Dossier',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF161B22), Color(0xFF0D1117)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader('WIN CONDITION'),
                      const SizedBox(height: 16),
                      _buildSlider(
                        value: decidedThresholdPercentage,
                        min: 0.1,
                        max: 1.0,
                        divisions: 90,
                        label: '${(decidedThresholdPercentage * 100).toInt()}%',
                        onChanged: (val) => setState(() => decidedThresholdPercentage = val),
                      ),
                      _buildStatusText('POLITICAL MATURITY: ${(decidedThresholdPercentage * 100).toInt()}% DECIDED VOTERS'),

                      const SizedBox(height: 48),
                      _buildHeader('GEOGRAPHICAL SCALE'),
                      const SizedBox(height: 16),
                      _buildSlider(
                        value: gridSize.toDouble(),
                        min: 5,
                        max: 11,
                        divisions: 3, // (11-5)/2 = 3 steps (5, 7, 9, 11)
                        label: '${gridSize}x$gridSize',
                        onChanged: (val) {
                          setState(() {
                            int newVal = val.toInt();
                            if (newVal % 2 == 0) newVal++;
                            gridSize = newVal;
                          });
                        },
                      ),
                      _buildStatusText('${gridSize}x$gridSize GRID SYSTEM'),
                      
                      const SizedBox(height: 48),
                      _buildHeader('HUMAN CANDIDATES'),
                      const SizedBox(height: 16),
                      _buildSlider(
                        value: humanPlayers.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4, // (5-1) = 4 steps (1, 2, 3, 4, 5)
                        label: humanPlayers.toString(),
                        onChanged: (val) {
                          setState(() {
                            humanPlayers = val.toInt();
                            while (_nameControllers.length < humanPlayers) {
                              _nameControllers.add(TextEditingController(
                                text: 'Candidate ${_nameControllers.length + 1}'
                              ));
                            }
                            while (_nameControllers.length > humanPlayers) {
                              _nameControllers.removeLast().dispose();
                            }
                          });
                        },
                      ),
                      _buildStatusText('$humanPlayers AUTHORIZED CANDIDATE(S)'),

                      const SizedBox(height: 24),
                      ...List.generate(humanPlayers, (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextField(
                          controller: _nameControllers[index],
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'CANDIDATE ${index + 1} NAME',
                            labelStyle: const TextStyle(color: Color(0xFFC5A059), fontSize: 10, letterSpacing: 2),
                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFC5A059))),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.03),
                          ),
                        ),
                      )),

                      const SizedBox(height: 48),
                      _buildHeader('POLITICAL RIVALS'),
                      const SizedBox(height: 16),
                      _buildAiOption('THE FIREBRAND', 'CHAOTIC RESOURCE CONSUMPTION', addAi1, const Color(0xFFE57373), PlayerType.ai1, (val) => setState(() => addAi1 = val!)),
                      const SizedBox(height: 8),
                      _buildAiOption('THE PRAGMATIST', 'DIRECT CAPITAL ACQUISITION', addAi2, const Color(0xFFFFB74D), PlayerType.ai2, (val) => setState(() => addAi2 = val!)),
                      const SizedBox(height: 8),
                      _buildAiOption('THE TECHNOCRAT', 'MATHEMATICAL EFFICIENCY PROTOCOL', addAi3, const Color(0xFF90A4AE), PlayerType.ai3, (val) => setState(() => addAi3 = val!)),
                      const SizedBox(height: 8),
                      _buildAiOption('THE VISIONARY', 'MACRO-STRATEGIC CAMPAIGN PATHING', addAi4, const Color(0xFFCE93D8), PlayerType.ai4, (val) => setState(() => addAi4 = val!)),
                      const SizedBox(height: 8),
                      _buildAiOption('THE SOCIALIST', 'EASE OF CONVERSION & EQUALITY', addAi5, const Color(0xFF81C784), PlayerType.ai5, (val) => setState(() => addAi5 = val!)),
                    ],
                  ),
                ),
              ),
            ),
            
            // Fixed Bottom Button Area
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
                color: Color(0xFF0D1117),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    final names = _nameControllers.map((c) => c.text).toList();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerPage(
                          assetPath: 'assets/videos/game_start.mp4',
                          onFinished: () {
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (context, anim, second) => HomePage(
                                  humanNames: names,
                                  ai1: addAi1,
                                  ai2: addAi2,
                                  ai3: addAi3,
                                  ai4: addAi4,
                                  ai5: addAi5,
                                  gridSize: gridSize,
                                  decidedThresholdPercentage: decidedThresholdPercentage,
                                ),
                                transitionsBuilder: (context, anim, second, child) => FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 1000),
                              ),
                            );
                          },
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                        transitionDuration: const Duration(milliseconds: 1000),
                      ),
                    );
                  },
                  child: const Text('INITIALIZE CAMPAIGN'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFC5A059),
        letterSpacing: 2.0,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildSlider({required double value, required double min, required double max, int? divisions, required String label, required Function(double) onChanged}) {
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      onChanged: onChanged,
    );
  }

  Widget _buildStatusText(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAiOption(String title, String subtitle, bool value, Color color, PlayerType type, Function(bool?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: SvgPicture.string(_getMiniPlayerSvg(type, color), width: 24, height: 24),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 36.0),
          child: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFC5A059),
        checkColor: Colors.black,
      ),
    );
  }

  String _getMiniPlayerSvg(PlayerType type, Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    const bodyPath = 'M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z';
    switch (type) {
      case PlayerType.ai1: return '<svg viewBox="0 0 24 24"><path fill="#$hex" d="$bodyPath"/><path d="M11.5 14l-.5 2h1l-.5 2 1.5-2.5h-1l.5-1.5z" fill="white"/></svg>';
      case PlayerType.ai2: return '<svg viewBox="0 0 24 24"><path fill="#$hex" d="$bodyPath"/><path d="M12 14.5l-1.5 1 1.5 2 1.5-2-1.5-1z" fill="white"/></svg>';
      case PlayerType.ai3: return '<svg viewBox="0 0 24 24"><path fill="#$hex" d="$bodyPath"/><rect x="11" y="15" width="2" height="2" fill="white"/></svg>';
      case PlayerType.ai4: return '<svg viewBox="0 0 24 24"><path fill="#$hex" d="$bodyPath"/><path d="M12 14v4M10 16h4" stroke="white" stroke-width="1"/></svg>';
      case PlayerType.ai5: return '<svg viewBox="0 0 24 24"><path fill="#$hex" d="$bodyPath"/><circle cx="12" cy="16" r="1.5" fill="white"/></svg>';
      default: return '';
    }
  }
}

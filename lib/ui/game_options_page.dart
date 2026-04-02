import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_player_state.dart';
import 'home_page.dart';
import 'video_player_page.dart';

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
    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        insetPadding: const EdgeInsets.all(16),
        contentPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: Color(0xFFC5A059), size: 28),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE POLITAGON DOSSIER',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 18, letterSpacing: 2.0),
                        ),
                        Text(
                          isFirstTime ? 'NEW CANDIDATE ORIENTATION' : 'CLASSIFIED STRATEGY HANDBOOK',
                          style: const TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStorySection(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: Colors.white10, thickness: 1),
                      ),
                      
                      _buildRuleSection(
                        '01. MOVEMENT & NAVIGATION',
                        'You move one square at a time in cardinal directions (Up, Down, Left, Right). Diagonal movement is impossible.',
                        Icons.open_with,
                        visual: _buildAdjacencyVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '02. CAPTURE & CONVERSION',
                        'Landing on a cell captures its "Political Capital" (points). You drain Undecided voters first, then take points from the weakest opponents on that cell.',
                        Icons.public,
                        visual: _buildCaptureVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '03. THE INF-POP BALANCE',
                        'Your stats change based on where you land. Land at the Center to gain Influence (INF) for the elite classes. Land at the Edges to gain Popularity (POP) among the masses. Gaining one usually drains the other.',
                        Icons.trending_up,
                        visual: _buildStatBalanceVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '04. THE SHUFFLING TIDE',
                        'The electorate is unstable. Every turn, points randomly shuffle between cells of the same social class. You must maintain presence in a class to keep your votes.',
                        Icons.shuffle,
                        visual: _buildShuffleVisual(),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildRuleSection(
                        '05. THE WIN CONDITION',
                        'The Center (Politagon) is locked initially. It unlocks once any player hits 50% majority or all points are claimed. Enter the Center while you are the Leader to win.',
                        Icons.military_tech,
                        visual: _buildVictoryVisual(),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      if (isFirstTime) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_seen_rules_v1', true);
                      }
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC5A059)),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('I UNDERSTAND THE STAKES', style: TextStyle(color: Color(0xFFC5A059), letterSpacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE PREMISE',
          style: TextStyle(color: Color(0xFFC5A059), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            border: const Border(left: BorderSide(color: Color(0xFFC5A059), width: 2)),
          ),
          child: const Text(
            'In the aftermath of the Great Collapse, the physical borders of nations have vanished, replaced by the "Politagon Grid." You are a Candidate weaver of narratives. Your goal is to navigate the shifting social classes, gathering enough political capital to unlock the center and seize total control. Choose your path wisely: the climb to the top is paved with the voters you steal from your rivals.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleSection(String title, String body, IconData icon, {Widget? visual}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFC5A059)),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visual != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 12),
            child: visual,
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            body,
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAdjacencyVisual() {
    return Row(
      children: [
        Column(
          children: [
            _miniSquare(false),
            _miniSquare(true, isTarget: true),
            _miniSquare(false),
          ],
        ),
        Column(
          children: [
            _miniSquare(true, isTarget: true),
            _miniSquare(true, hasPlayer: true),
            _miniSquare(true, isTarget: true),
          ],
        ),
        Column(
          children: [
            _miniSquare(false),
            _miniSquare(true, isTarget: true),
            _miniSquare(false),
          ],
        ),
        const SizedBox(width: 20),
        const Icon(Icons.arrow_right_alt, color: Colors.white24),
        const SizedBox(width: 10),
        const Text('CARDINAL MOVES', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildCaptureVisual() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statBox('UNDECIDED', '1st', Colors.grey),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
          _statBox('WEAK RIVAL', '2nd', Colors.redAccent.withOpacity(0.5)),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 14),
          _statBox('STRONG RIVAL', '3rd', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatBalanceVisual() {
    return Row(
      children: [
        Expanded(
          child: _statEvolutionBox('CENTER', 'INF ↑', 'POP ↓', const Color(0xFFC5A059)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statEvolutionBox('EDGE', 'POP ↑', 'INF ↓', Colors.blueAccent),
        ),
      ],
    );
  }

  Widget _buildShuffleVisual() {
    return Row(
      children: [
        _miniSquare(true, color: Colors.indigo.withOpacity(0.3)),
        const Icon(Icons.sync, color: Color(0xFFC5A059), size: 16),
        _miniSquare(true, color: Colors.indigo.withOpacity(0.3)),
        const SizedBox(width: 12),
        const Text('SAME CLASS ONLY', style: TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _buildVictoryVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC5A059)),
        gradient: LinearGradient(colors: [const Color(0xFFC5A059).withOpacity(0.1), Colors.transparent]),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open, color: Color(0xFFC5A059), size: 16),
          SizedBox(width: 12),
          Text('> 50% MAJORITY', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _miniSquare(bool visible, {bool hasPlayer = false, bool isTarget = false, Color? color}) {
    return Container(
      width: 20, height: 20,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color ?? (visible ? Colors.white.withOpacity(0.05) : Colors.transparent),
        border: isTarget ? Border.all(color: const Color(0xFFC5A059), width: 1) : (visible ? Border.all(color: Colors.white10) : null),
      ),
      child: hasPlayer ? const Center(child: Icon(Icons.person, size: 12, color: Colors.white)) : null,
    );
  }

  Widget _statBox(String label, String priority, Color color) {
    return Column(
      children: [
        Text(priority, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      ],
    );
  }

  Widget _statEvolutionBox(String loc, String gain, String loss, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.03),
      child: Column(
        children: [
          Text(loc, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(gain, style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          Text(loss, style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
        ],
      ),
    );
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
                      _buildHeader('GEOGRAPHICAL SCALE'),
                      const SizedBox(height: 16),
                      _buildSlider(
                        value: gridSize.toDouble(),
                        min: 5,
                        max: 11,
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
                      _buildHeader('HUMAN DELEGATES'),
                      const SizedBox(height: 16),
                      _buildSlider(
                        value: humanPlayers.toDouble(),
                        min: 1,
                        max: 5,
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

  Widget _buildSlider({required double value, required double min, required double max, required String label, required Function(double) onChanged}) {
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: (max - min).toInt(),
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

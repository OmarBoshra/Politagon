import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/game_state.dart';
import 'home_page.dart';

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
  int gridSize = 5;

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        insetPadding: const EdgeInsets.all(20),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC5A059), width: 1.5),
          borderRadius: BorderRadius.zero,
        ),
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFFC5A059), size: 28),
            const SizedBox(width: 12),
            Text(
              'OPERATIONAL PROTOCOLS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20, letterSpacing: 2.0),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVisualRule(
                  title: 'I. NAVIGATION & ADJACENCY',
                  body: 'Units move in cardinal directions (Up, Down, Left, Right). Diagonal movement is prohibited. Valid moves are highlighted with a pulsing white border.',
                  visual: _buildAdjacencyVisual(),
                ),
                _buildVisualRule(
                  title: 'II. THE DUAL-STAT CYCLE',
                  body: 'Influence (INF) is gained at the Center but used to capture the Edges. Popularity (POP) is gained at the Edges but used to capture the Center. You must balance both to maintain efficiency.',
                  visual: _buildStatVisual(),
                ),
                _buildVisualRule(
                  title: 'III. THE THRONE OF POWER',
                  body: 'The Center Chair is locked until the Total Score reaches the threshold. To win, occupy the Chair while being at least tied for the highest score.',
                  visual: _buildVictoryVisual(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('ACKNOWLEDGED', style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold, letterSpacing: 2.0)),
          )
        ],
      ),
    );
  }

  Widget _buildVisualRule({required String title, required String body, required Widget visual}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          visual,
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }

  Widget _buildAdjacencyVisual() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            _miniCell(false),
            Row(
              children: [
                _miniCell(true, isTappable: true),
                _miniCell(true, hasPlayer: true),
                _miniCell(true, isTappable: true),
              ],
            ),
            _miniCell(false),
          ],
        ),
        const SizedBox(width: 20),
        const Icon(Icons.arrow_forward, color: Colors.white24),
        const SizedBox(width: 20),
        const Text('CARDINAL\nONLY', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatVisual() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statIndicator('POP', 'EDGE GAIN', const Color(0xFFC5A059)),
          const Icon(Icons.sync, color: Colors.white24),
          _statIndicator('INF', 'CENTER GAIN', Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildVictoryVisual() {
    return Center(
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC5A059), width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.3), blurRadius: 15)],
        ),
        child: const Icon(Icons.chair, color: Color(0xFFC5A059), size: 30),
      ),
    );
  }

  Widget _miniCell(bool visible, {bool hasPlayer = false, bool isTappable = false}) {
    return Container(
      width: 30, height: 30,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: visible ? (hasPlayer ? Colors.blueGrey : Colors.white.withOpacity(0.1)) : Colors.transparent,
        border: isTappable ? Border.all(color: Colors.white, width: 1.5) : null,
      ),
      child: hasPlayer ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
    );
  }

  Widget _statIndicator(String label, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      ],
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
            icon: const Icon(Icons.info_outline, color: Color(0xFFC5A059)),
            onPressed: _showRules,
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
                  min: 3,
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

                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => HomePage(
                          humanNames: _nameControllers.map((c) => c.text).toList(),
                          ai1: addAi1,
                          ai2: addAi2,
                          ai3: addAi3,
                          ai4: addAi4,
                          gridSize: gridSize,
                        )),
                      );
                    },
                    child: const Text('INITIALIZE CAMPAIGN'),
                  ),
                ),
              ],
            ),
          ),
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
      default: return '';
    }
  }
}

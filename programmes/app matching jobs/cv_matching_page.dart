import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/session_service.dart';
import '../models/user_model.dart';
import 'profile_view_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';

class CvMatchingPage extends StatefulWidget {
  const CvMatchingPage({super.key});

  @override
  State<CvMatchingPage> createState() => _CvMatchingPageState();
}

class _CvMatchingPageState extends State<CvMatchingPage> {
  final TextEditingController _requiredController = TextEditingController();
  final TextEditingController _optionalController = TextEditingController();
  double _threshold = 0.4; // 40%
  double _requiredWeight = 0.7;
  double _optionalWeight = 0.3;
  bool _loading = false;
  bool _onlyMyMatches = false;
  String _sortBy = 'Weighted score';
  List<_CandidateMatch> _matches = [];
  List<JobOffer> _offers = [];
  JobOffer? _selectedOffer;
  String? _userRole;
  String? _userId;
  Set<String> _allowedCandidateIds = {};
  String? _savedOfferId;
  final TextEditingController _presetNameController = TextEditingController();
  Map<String, Map<String, dynamic>> _presets = {};
  String? _selectedPresetName;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final role = await SessionService.getUserRole();
      final uid = await SessionService.getUserId();
      setState(() {
        _userRole = role;
        _userId = uid;
      });
    } catch (_) {}

    // Load saved preferences first
    await _loadPrefs();

    try {
      final offers = await DatabaseService.getAllJobOffers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        if (_offers.isNotEmpty) {
          _offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (_savedOfferId != null) {
            _selectedOffer =
                _offers.firstWhere((o) => o.id == _savedOfferId, orElse: () {
              return _offers.first;
            });
          } else {
            _selectedOffer = _offers.first;
          }
        }
      });
      if (_selectedOffer != null && (_userRole == 'employer')) {
        if (_requiredController.text.trim().isEmpty) {
          _requiredController.text = _selectedOffer!.skillsRequired.join(', ');
        }
      }
    } catch (e) {
      // Ignore; manual entry still works
    }

    try {
      if (_userId != null) {
        final myMatches = await DatabaseService.getMatchesForUser(_userId!);
        final ids = <String>{};
        for (final m in myMatches) {
          if (m.candidateId.isNotEmpty) ids.add(m.candidateId);
        }
        if (mounted) {
          setState(() {
            _allowedCandidateIds = ids;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _threshold = prefs.getDouble('cvMatch_threshold') ?? _threshold;
        _requiredWeight =
            prefs.getDouble('cvMatch_reqWeight') ?? _requiredWeight;
        _optionalWeight =
            prefs.getDouble('cvMatch_optWeight') ?? _optionalWeight;
        _onlyMyMatches =
            prefs.getBool('cvMatch_onlyMyMatches') ?? _onlyMyMatches;
        final req = prefs.getString('cvMatch_requiredSkills');
        final opt = prefs.getString('cvMatch_optionalSkills');
        if (req != null) _requiredController.text = req;
        if (opt != null) _optionalController.text = opt;
        _savedOfferId = prefs.getString('cvMatch_selectedOfferId');
        _sortBy = prefs.getString('cvMatch_sortBy') ?? _sortBy;
        final presetsJson = prefs.getString('cvMatch_presets');
        if (presetsJson != null && presetsJson.isNotEmpty) {
          final decoded = Map<String, dynamic>.from(
              (presetsJson.isNotEmpty) ? (jsonDecode(presetsJson)) : {});
          _presets = decoded.map((k, v) => MapEntry(
              k, Map<String, dynamic>.from(v as Map<String, dynamic>)));
        }
        _selectedPresetName = prefs.getString('cvMatch_lastPreset');
      });
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cvMatch_threshold', _threshold);
      await prefs.setDouble('cvMatch_reqWeight', _requiredWeight);
      await prefs.setDouble('cvMatch_optWeight', _optionalWeight);
      await prefs.setBool('cvMatch_onlyMyMatches', _onlyMyMatches);
      await prefs.setString('cvMatch_sortBy', _sortBy);
      await prefs.setString(
          'cvMatch_requiredSkills', _requiredController.text.trim());
      await prefs.setString(
          'cvMatch_optionalSkills', _optionalController.text.trim());
      if (_selectedOffer != null) {
        await prefs.setString('cvMatch_selectedOfferId', _selectedOffer!.id);
      }
      // Persist presets and selection too
      final encoded = jsonEncode(_presets);
      await prefs.setString('cvMatch_presets', encoded);
      if (_selectedPresetName != null) {
        await prefs.setString('cvMatch_lastPreset', _selectedPresetName!);
      }
    } catch (_) {}
  }

  Future<void> _savePreset() async {
    final name = _presetNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a preset name')),
      );
      return;
    }
    _presets[name] = {
      'threshold': _threshold,
      'reqWeight': _requiredWeight,
      'optWeight': _optionalWeight,
      'onlyMyMatches': _onlyMyMatches,
      'required': _requiredController.text.trim(),
      'optional': _optionalController.text.trim(),
    };
    setState(() {
      _selectedPresetName = name;
    });
    await _persistSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preset "$name" saved')),
      );
    }
  }

  Future<void> _applyPreset(String name) async {
    final preset = _presets[name];
    if (preset == null) return;
    setState(() {
      _threshold = (preset['threshold'] as num?)?.toDouble() ?? _threshold;
      _requiredWeight =
          (preset['reqWeight'] as num?)?.toDouble() ?? _requiredWeight;
      _optionalWeight =
          (preset['optWeight'] as num?)?.toDouble() ?? _optionalWeight;
      _onlyMyMatches = (preset['onlyMyMatches'] as bool?) ?? _onlyMyMatches;
      _requiredController.text = (preset['required'] as String?) ?? '';
      _optionalController.text = (preset['optional'] as String?) ?? '';
      _selectedPresetName = name;
    });
    await _persistSettings();
    _findMatches();
  }

  Future<void> _deletePreset(String name) async {
    if (_presets.containsKey(name)) {
      setState(() {
        _presets.remove(name);
        if (_selectedPresetName == name) _selectedPresetName = null;
      });
      await _persistSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preset "$name" deleted')),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matches to export')),
      );
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('Name,Job Title,Score,Required Coverage,Optional Coverage');
    for (final m in _matches) {
      String name = m.candidate.name.replaceAll('"', '""');
      String title = (m.candidate.jobTitle ?? '').replaceAll('"', '""');
      buffer.writeln(
          '"$name","$title",${m.score.toStringAsFixed(3)},${m.reqCover.toStringAsFixed(3)},${m.optCover.toStringAsFixed(3)}');
    }
    final csv = buffer.toString();
    await Clipboard.setData(ClipboardData(text: csv));
    String? filePath;
    try {
      final dir = Directory.systemTemp;
      final file = File(
          '${dir.path}/cv_matches_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      filePath = file.path;
    } catch (_) {}
    final msg = filePath != null
        ? 'CSV copied to clipboard and saved to: $filePath'
        : 'CSV copied to clipboard';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _findMatches() async {
    final rawReq = _requiredController.text.trim();
    final rawOpt = _optionalController.text.trim();
    // Persist current inputs
    await _persistSettings();
    if (rawReq.isEmpty && rawOpt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter required and/or nice-to-have skills')),
      );
      return;
    }

    final requiredSkills = rawReq
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();
    final optionalSkills = rawOpt
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();

    setState(() {
      _loading = true;
      _matches = [];
    });

    try {
      final candidates = await DatabaseService.getAllCandidates();
      final results = <_CandidateMatch>[];
      for (final candidate in candidates) {
        if (_onlyMyMatches && _allowedCandidateIds.isNotEmpty) {
          if (!_allowedCandidateIds.contains(candidate.id)) continue;
        }
        final skillSet = candidate.skills
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet();

        final reqCover = requiredSkills.isEmpty
            ? 0.0
            : requiredSkills.intersection(skillSet).length /
                requiredSkills.length;
        final optCover = optionalSkills.isEmpty
            ? 0.0
            : optionalSkills.intersection(skillSet).length /
                optionalSkills.length;
        final weightSum = (_requiredWeight + _optionalWeight).clamp(0.0001, 10);
        final score =
            ((_requiredWeight * reqCover) + (_optionalWeight * optCover)) /
                weightSum;
        results.add(_CandidateMatch(
            candidate: candidate,
            score: score,
            reqCover: reqCover,
            optCover: optCover));
      }
      // Initial sort by weighted score
      results.sort((a, b) => b.score.compareTo(a.score));

      setState(() {
        _matches = results;
        _sortMatchesInPlace();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to compute matches: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _sortMatchesInPlace() {
    if (_matches.isEmpty) return;
    switch (_sortBy) {
      case 'Required first':
        _matches.sort((a, b) => b.reqCover.compareTo(a.reqCover));
        break;
      case 'Optional first':
        _matches.sort((a, b) => b.optCover.compareTo(a.optCover));
        break;
      case 'Weighted score':
      default:
        _matches.sort((a, b) => b.score.compareTo(a.score));
    }
    setState(() {});
  }

  // Keeping jaccard available if needed for future ranking options

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('CV Matching'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Presets row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _presetNameController,
                            decoration: const InputDecoration(
                              hintText: 'Preset name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _savePreset,
                          child: const Text('Save Preset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_presets.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPresetName,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Load preset',
                              ),
                              items: _presets.keys
                                  .map((name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name),
                                      ))
                                  .toList(),
                              onChanged: (name) {
                                if (name != null) _applyPreset(name);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedPresetName != null)
                            IconButton(
                              tooltip: 'Delete preset',
                              onPressed: () {
                                _deletePreset(_selectedPresetName!);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (_offers.isNotEmpty && _userRole == 'employer') ...[
                      const Text('Select a job offer (auto-fills skills)'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<JobOffer>(
                        value: _selectedOffer,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _offers
                            .map((o) => DropdownMenuItem<JobOffer>(
                                  value: o,
                                  child: Text(o.title),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedOffer = val;
                            if (val != null) {
                              _requiredController.text =
                                  val.skillsRequired.join(', ');
                            }
                          });
                          _persistSettings();
                          _findMatches();
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        const Text('Sort by'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sortBy,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Required first',
                                child: Text('Required first'),
                              ),
                              DropdownMenuItem(
                                value: 'Weighted score',
                                child: Text('Weighted score'),
                              ),
                              DropdownMenuItem(
                                value: 'Optional first',
                                child: Text('Optional first'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _sortBy = v);
                              _persistSettings();
                              _sortMatchesInPlace();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Required skills (comma-separated)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _requiredController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Flutter, Dart, REST, Firebase',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _findMatches(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Nice-to-have skills (comma-separated)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _optionalController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. GraphQL, AWS, Docker',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _findMatches(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Match threshold'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _threshold,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: '${(_threshold * 100).round()}%',
                            onChanged: (v) {
                              setState(() => _threshold = v);
                              _persistSettings();
                            },
                          ),
                        ),
                        Text('${(_threshold * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Required weight'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _requiredWeight,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: _requiredWeight.toStringAsFixed(1),
                            onChanged: (v) {
                              setState(() => _requiredWeight = v);
                              _persistSettings();
                            },
                          ),
                        ),
                        Text(_requiredWeight.toStringAsFixed(1)),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Optional weight'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _optionalWeight,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: _optionalWeight.toStringAsFixed(1),
                            onChanged: (v) {
                              setState(() => _optionalWeight = v);
                              _persistSettings();
                            },
                          ),
                        ),
                        Text(_optionalWeight.toStringAsFixed(1)),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Only candidates I've matched"),
                      value: _onlyMyMatches,
                      onChanged: (v) {
                        setState(() => _onlyMyMatches = v);
                        _persistSettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: const Text('Find Matches'),
                        onPressed: _loading ? null : _findMatches,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                        onPressed: _exportCsv,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_matches.isNotEmpty) ...[
                ...(_matches.map((item) {
                  final percent = (item.score * 100).round();
                  final isMatch = item.score >= _threshold;
                  final requiredSkills = _requiredController.text
                      .split(',')
                      .map((s) => s.trim().toLowerCase())
                      .where((s) => s.isNotEmpty)
                      .toSet();
                  final optionalSkills = _optionalController.text
                      .split(',')
                      .map((s) => s.trim().toLowerCase())
                      .where((s) => s.isNotEmpty)
                      .toSet();
                  final candidateSkills = item.candidate.skills
                      .map((s) => s.trim().toLowerCase())
                      .where((s) => s.isNotEmpty)
                      .toSet();
                  final matchedReq =
                      requiredSkills.intersection(candidateSkills);
                  final missingReq = requiredSkills.difference(candidateSkills);
                  final matchedOpt =
                      optionalSkills.intersection(candidateSkills);
                  final missingOpt = optionalSkills.difference(candidateSkills);
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.candidate.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMatch
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isMatch
                                      ? 'Match ${percent}%'
                                      : 'Partial ${percent}%',
                                  style: TextStyle(
                                    color: isMatch
                                        ? Colors.green[800]
                                        : Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (item.candidate.jobTitle != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                item.candidate.jobTitle!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (matchedReq.isNotEmpty) ...[
                            Text('Matched required',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: matchedReq
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor: Colors.green[50],
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (missingReq.isNotEmpty) ...[
                            Text('Missing required',
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: missingReq
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor: Colors.red[50],
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (matchedOpt.isNotEmpty) ...[
                            Text('Matched optional',
                                style: TextStyle(
                                  color: Colors.teal[800],
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: matchedOpt
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor: Colors.teal[50],
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (missingOpt.isNotEmpty) ...[
                            Text('Missing optional',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: missingOpt
                                  .map((s) => Chip(
                                        label: Text(s),
                                        backgroundColor: Colors.orange[50],
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.person),
                                label: const Text('View Profile'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileViewPage(
                                        userId: item.candidate.id,
                                        userRole: 'candidate',
                                        matchName: item.candidate.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.message),
                                label: const Text('Message'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        matchName: item.candidate.name,
                                        matchUserId: item.candidate.id,
                                        matchUserRole: 'candidate',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList()),
              ] else
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No results yet. Enter skills and search.'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateMatch {
  final Candidate candidate;
  final double score;
  final double reqCover;
  final double optCover;
  _CandidateMatch({
    required this.candidate,
    required this.score,
    this.reqCover = 0,
    this.optCover = 0,
  });
}

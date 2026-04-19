import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_chenab_times/screens/leaderboard_screen.dart';
import 'package:the_chenab_times/screens/login_screen.dart';
import 'package:the_chenab_times/services/auth_service.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with WidgetsBindingObserver {
  static const _scrambleStreakKey = 'games_scramble_streak';
  static const _vocabScoreKey = 'games_vocab_score';
  static const _sentenceScoreKey = 'games_sentence_score';
  static const _spellingScoreKey = 'games_spelling_score';
  static const _crosswordScoreKey = 'games_crossword_score';
  static const _lastScrambleKey = 'games_last_scramble_index';
  static const _lastVocabKey = 'games_last_vocab_index';
  static const _lastSentenceKey = 'games_last_sentence_index';
  static const _lastSpellingKey = 'games_last_spelling_index';
  static const _lastCrosswordKey = 'games_last_crossword_index';
  static const _bestSyncedStreakKey = 'games_best_synced_streak';
  static const _bestLocalScrambleStreakKey = 'games_best_local_scramble_streak';

  final Random _random = Random();

  late _WordScramblePuzzle _scramblePuzzle;
  late _VocabQuestion _vocabQuestion;
  late _SentenceChallenge _sentenceChallenge;
  late _SpellingBeeQuestion _spellingBeeQuestion;
  late _CrosswordPuzzle _crosswordPuzzle;

  int _scrambleStreak = 0;
  int _vocabScore = 0;
  int _sentenceScore = 0;
  int _spellingScore = 0;
  int _crosswordScore = 0;
  int _lastScrambleIndex = -1;
  int _lastVocabIndex = -1;
  int _lastSentenceIndex = -1;
  int _lastSpellingIndex = -1;
  int _lastCrosswordIndex = -1;
  int _bestSyncedStreak = 0;
  int _bestLocalScrambleStreak = 0;
  int _sessionBestStreak = 0;
  bool _loading = true;
  bool _streakSyncPending = false;
  bool _syncingStreak = false;

  final TextEditingController _scrambleController = TextEditingController();
  final TextEditingController _crosswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProgress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushStreakSync();
    _scrambleController.dispose();
    _crosswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _flushStreakSync();
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _scrambleStreak = prefs.getInt(_scrambleStreakKey) ?? 0;
    _vocabScore = prefs.getInt(_vocabScoreKey) ?? 0;
    _sentenceScore = prefs.getInt(_sentenceScoreKey) ?? 0;
    _spellingScore = prefs.getInt(_spellingScoreKey) ?? 0;
    _crosswordScore = prefs.getInt(_crosswordScoreKey) ?? 0;
    _lastScrambleIndex = prefs.getInt(_lastScrambleKey) ?? -1;
    _lastVocabIndex = prefs.getInt(_lastVocabKey) ?? -1;
    _lastSentenceIndex = prefs.getInt(_lastSentenceKey) ?? -1;
    _lastSpellingIndex = prefs.getInt(_lastSpellingKey) ?? -1;
    _lastCrosswordIndex = prefs.getInt(_lastCrosswordKey) ?? -1;
    _bestSyncedStreak = prefs.getInt(_bestSyncedStreakKey) ?? 0;
    _bestLocalScrambleStreak = prefs.getInt(_bestLocalScrambleStreakKey) ?? 0;
    _sessionBestStreak = max(_scrambleStreak, _bestLocalScrambleStreak);

    _scramblePuzzle = _nextScramblePuzzle();
    _vocabQuestion = _nextVocabQuestion();
    _sentenceChallenge = _nextSentenceChallenge();
    _spellingBeeQuestion = _nextSpellingBeeQuestion();
    _crosswordPuzzle = _nextCrosswordPuzzle();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scrambleStreakKey, _scrambleStreak);
    await prefs.setInt(_vocabScoreKey, _vocabScore);
    await prefs.setInt(_sentenceScoreKey, _sentenceScore);
    await prefs.setInt(_spellingScoreKey, _spellingScore);
    await prefs.setInt(_crosswordScoreKey, _crosswordScore);
    await prefs.setInt(_lastScrambleKey, _lastScrambleIndex);
    await prefs.setInt(_lastVocabKey, _lastVocabIndex);
    await prefs.setInt(_lastSentenceKey, _lastSentenceIndex);
    await prefs.setInt(_lastSpellingKey, _lastSpellingIndex);
    await prefs.setInt(_lastCrosswordKey, _lastCrosswordIndex);
    await prefs.setInt(_bestSyncedStreakKey, _bestSyncedStreak);
    await prefs.setInt(_bestLocalScrambleStreakKey, _bestLocalScrambleStreak);
  }

  int _nextDifferentIndex(int length, int lastIndex) {
    if (length <= 1) return 0;
    var nextIndex = _random.nextInt(length);
    while (nextIndex == lastIndex) {
      nextIndex = _random.nextInt(length);
    }
    return nextIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F3EA), Color(0xFFF3E4CF)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 28),
                children: [
                  _buildHero(),
                  const SizedBox(height: 16),
                  _buildSectionTitle(
                    title: 'Word Scramble',
                    subtitle:
                        'Unscramble useful English words from real-world usage.',
                  ),
                  const SizedBox(height: 10),
                  _buildScrambleCard(),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    title: 'Meaning Match',
                    subtitle:
                        'Pick the closest meaning to grow vocabulary offline.',
                  ),
                  const SizedBox(height: 10),
                  _buildVocabCard(),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    title: 'Sentence Builder',
                    subtitle:
                        'Choose the best sentence to sound more natural in English.',
                  ),
                  const SizedBox(height: 10),
                  _buildSentenceCard(),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    title: 'Spelling Bee',
                    subtitle:
                        'Choose the correct spelling from similar-looking words.',
                  ),
                  const SizedBox(height: 10),
                  _buildSpellingBeeCard(),
                  const SizedBox(height: 18),
                  _buildSectionTitle(
                    title: 'Mini Crossword',
                    subtitle:
                        'Solve clue-based word puzzles with saved progress.',
                  ),
                  const SizedBox(height: 10),
                  _buildCrosswordCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildHero() {
    final authService = context.watch<AuthService>();
    final totalPoints =
        _scrambleStreak +
        _vocabScore +
        _sentenceScore +
        _spellingScore +
        _crosswordScore;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4CEB2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB22D1F), Color(0xFF7C1714)],
              ),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline English Games',
                  style: TextStyle(
                    color: Color(0xFF4A2017),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Practice vocabulary, spelling, crossword clues, and sentence sense without internet.',
                  style: TextStyle(
                    color: Color(0xFF7A6247),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Saved points: $totalPoints',
                  style: TextStyle(
                    color: Color(0xFF8C1D18),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.emoji_events_outlined),
                      label: const Text('Leaderboard'),
                    ),
                    if (!authService.isAuthenticated)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Log in to sync'),
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

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF3B2417),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF7A6247),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildScrambleCard() {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScorePill(label: 'Streak', value: '$_scrambleStreak'),
              const Spacer(),
              TextButton(
                onPressed: _resetScramble,
                child: const Text('New word'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _scramblePuzzle.hint,
            style: const TextStyle(
              color: Color(0xFF7A6247),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final scrambledLetters = (_scramblePuzzle.scrambled ?? '').split(
                '',
              );
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scrambledLetters
                    .map(
                      (letter) => Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF7EA), Color(0xFFF3DFC2)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE3CCAC)),
                        ),
                        child: Text(
                          letter.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF6D1715),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _scrambleController,
            decoration: InputDecoration(
              hintText: 'Type your answer',
              filled: true,
              fillColor: const Color(0xFFFFFBF5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE4CEB2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE4CEB2)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitScramble,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8C1D18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Check Answer'),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabCard() {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScorePill(label: 'Score', value: '$_vocabScore'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() => _vocabQuestion = _nextVocabQuestion());
                  _saveProgress();
                },
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Which option is closest in meaning to "${_vocabQuestion.word}"?',
            style: const TextStyle(
              color: Color(0xFF3B2417),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ..._vocabQuestion.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () => _submitVocab(option),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Color(0xFFE3CCAC)),
                  backgroundColor: const Color(0xFFFFFBF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Color(0xFF4A2017),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceCard() {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScorePill(label: 'Correct', value: '$_sentenceScore'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() => _sentenceChallenge = _nextSentenceChallenge());
                  _saveProgress();
                },
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _sentenceChallenge.prompt,
            style: const TextStyle(
              color: Color(0xFF3B2417),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ..._sentenceChallenge.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _submitSentence(option),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFBF5), Color(0xFFF5E7D1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE3CCAC)),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Color(0xFF4A2017),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpellingBeeCard() {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScorePill(label: 'Score', value: '$_spellingScore'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(
                    () => _spellingBeeQuestion = _nextSpellingBeeQuestion(),
                  );
                  _saveProgress();
                },
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _spellingBeeQuestion.prompt,
            style: const TextStyle(
              color: Color(0xFF3B2417),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ..._spellingBeeQuestion.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () => _submitSpellingBee(option),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: Color(0xFFE3CCAC)),
                  backgroundColor: const Color(0xFFFFFBF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: Color(0xFF4A2017),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrosswordCard() {
    return _GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScorePill(label: 'Solved', value: '$_crosswordScore'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _crosswordPuzzle = _nextCrosswordPuzzle();
                    _crosswordController.clear();
                  });
                  _saveProgress();
                },
                child: const Text('New clue'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _crosswordPuzzle.clue,
            style: const TextStyle(
              color: Color(0xFF3B2417),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Letters: ${_crosswordPuzzle.answer.length}',
            style: const TextStyle(
              color: Color(0xFF7A6247),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _crosswordController,
            decoration: InputDecoration(
              hintText: 'Type the answer',
              filled: true,
              fillColor: const Color(0xFFFFFBF5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE4CEB2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE4CEB2)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitCrossword,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8C1D18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Solve Clue'),
          ),
        ],
      ),
    );
  }

  void _resetScramble() {
    setState(() {
      _scramblePuzzle = _nextScramblePuzzle();
      _scrambleController.clear();
    });
    _saveProgress();
  }

  void _submitScramble() {
    final answer = _scrambleController.text.trim().toLowerCase();
    if (answer == _scramblePuzzle.answer.toLowerCase()) {
      setState(() {
        _scrambleStreak++;
        _sessionBestStreak = max(_sessionBestStreak, _scrambleStreak);
        _bestLocalScrambleStreak = max(
          _bestLocalScrambleStreak,
          _sessionBestStreak,
        );
        _streakSyncPending = _sessionBestStreak > _bestSyncedStreak;
        _scramblePuzzle = _nextScramblePuzzle();
        _scrambleController.clear();
      });
      _showFeedback('Correct! Great spelling.', isSuccess: true);
    } else {
      final sessionPeak = max(_sessionBestStreak, _scrambleStreak);
      setState(() => _scrambleStreak = 0);
      _sessionBestStreak = max(_sessionBestStreak, sessionPeak);
      _bestLocalScrambleStreak = max(
        _bestLocalScrambleStreak,
        _sessionBestStreak,
      );
      _streakSyncPending = _bestLocalScrambleStreak > _bestSyncedStreak;
      _showFeedback(
        'Try again. Hint: ${_scramblePuzzle.hint}',
        isSuccess: false,
      );
      _flushStreakSync();
    }
    _saveProgress();
  }

  void _submitVocab(String option) {
    final correct = option == _vocabQuestion.answer;
    if (correct) {
      setState(() => _vocabScore++);
      _showFeedback('Nice. "$option" is the closest meaning.', isSuccess: true);
    } else {
      _showFeedback(
        'Not quite. Correct answer: ${_vocabQuestion.answer}',
        isSuccess: false,
      );
    }
    setState(() => _vocabQuestion = _nextVocabQuestion());
    _saveProgress();
  }

  void _submitSentence(String option) {
    final correct = option == _sentenceChallenge.answer;
    if (correct) {
      setState(() => _sentenceScore++);
      _showFeedback('Correct. That sounds more natural.', isSuccess: true);
    } else {
      _showFeedback(
        'Better choice: ${_sentenceChallenge.answer}',
        isSuccess: false,
      );
    }
    setState(() => _sentenceChallenge = _nextSentenceChallenge());
    _saveProgress();
  }

  void _submitSpellingBee(String option) {
    final correct = option == _spellingBeeQuestion.answer;
    if (correct) {
      setState(() => _spellingScore++);
      _showFeedback('Correct spelling.', isSuccess: true);
    } else {
      _showFeedback(
        'Correct answer: ${_spellingBeeQuestion.answer}',
        isSuccess: false,
      );
    }
    setState(() => _spellingBeeQuestion = _nextSpellingBeeQuestion());
    _saveProgress();
  }

  void _submitCrossword() {
    final answer = _crosswordController.text.trim().toLowerCase();
    if (answer == _crosswordPuzzle.answer.toLowerCase()) {
      setState(() {
        _crosswordScore++;
        _crosswordPuzzle = _nextCrosswordPuzzle();
        _crosswordController.clear();
      });
      _showFeedback('Great solve.', isSuccess: true);
    } else {
      _showFeedback(
        'Try again. Hint: ${_crosswordPuzzle.clue}',
        isSuccess: false,
      );
    }
    _saveProgress();
  }

  void _showFeedback(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? const Color(0xFF2F6C52)
            : const Color(0xFF8C1D18),
      ),
    );
  }

  _WordScramblePuzzle _nextScramblePuzzle() {
    const puzzles = [
      _WordScramblePuzzle(
        answer: 'editorial',
        hint: 'A newspaper opinion piece',
      ),
      _WordScramblePuzzle(
        answer: 'headlines',
        hint: 'Big important news titles',
      ),
      _WordScramblePuzzle(
        answer: 'vocabulary',
        hint: 'A set of words you know',
      ),
      _WordScramblePuzzle(
        answer: 'grammar',
        hint: 'Rules for correct language',
      ),
      _WordScramblePuzzle(
        answer: 'journalist',
        hint: 'A person who reports news',
      ),
      _WordScramblePuzzle(answer: 'analysis', hint: 'Detailed examination'),
      _WordScramblePuzzle(answer: 'headline', hint: 'Main title of a story'),
      _WordScramblePuzzle(answer: 'accuracy', hint: 'Freedom from mistakes'),
      _WordScramblePuzzle(answer: 'culture', hint: 'Shared way of life'),
      _WordScramblePuzzle(answer: 'economy', hint: 'System of money and trade'),
      _WordScramblePuzzle(answer: 'context', hint: 'Background meaning'),
      _WordScramblePuzzle(
        answer: 'clarity',
        hint: 'Easy to understand quality',
      ),
      _WordScramblePuzzle(answer: 'feature', hint: 'A longer detailed story'),
      _WordScramblePuzzle(
        answer: 'forecast',
        hint: 'Prediction for the future',
      ),
      _WordScramblePuzzle(answer: 'digital', hint: 'Using computer technology'),
      _WordScramblePuzzle(answer: 'citizen', hint: 'A member of a country'),
      _WordScramblePuzzle(
        answer: 'regional',
        hint: 'Linked to a specific area',
      ),
      _WordScramblePuzzle(answer: 'resilient', hint: 'Able to recover quickly'),
      _WordScramblePuzzle(answer: 'diligent', hint: 'Showing careful effort'),
      _WordScramblePuzzle(answer: 'concise', hint: 'Brief but clear'),
    ];
    _lastScrambleIndex = _nextDifferentIndex(
      puzzles.length,
      _lastScrambleIndex,
    );
    final selected = puzzles[_lastScrambleIndex];
    return selected.scrambledVariant(_random);
  }

  _VocabQuestion _nextVocabQuestion() {
    const questions = [
      _VocabQuestion(
        word: 'accurate',
        answer: 'correct',
        options: ['correct', 'angry', 'silent', 'late'],
      ),
      _VocabQuestion(
        word: 'brief',
        answer: 'short',
        options: ['careful', 'short', 'bright', 'costly'],
      ),
      _VocabQuestion(
        word: 'improve',
        answer: 'make better',
        options: ['make smaller', 'make better', 'make older', 'make slower'],
      ),
      _VocabQuestion(
        word: 'confident',
        answer: 'self-assured',
        options: ['self-assured', 'sleepy', 'confused', 'distant'],
      ),
      _VocabQuestion(
        word: 'reliable',
        answer: 'dependable',
        options: ['dependable', 'careless', 'fragile', 'unknown'],
      ),
      _VocabQuestion(
        word: 'vibrant',
        answer: 'full of energy',
        options: ['silent', 'full of energy', 'very old', 'nearly empty'],
      ),
      _VocabQuestion(
        word: 'context',
        answer: 'background meaning',
        options: [
          'background meaning',
          'quick answer',
          'public anger',
          'final result',
        ],
      ),
      _VocabQuestion(
        word: 'insight',
        answer: 'deep understanding',
        options: [
          'deep understanding',
          'loud complaint',
          'public holiday',
          'written order',
        ],
      ),
      _VocabQuestion(
        word: 'timely',
        answer: 'at the right moment',
        options: [
          'at the right moment',
          'too expensive',
          'hard to read',
          'very distant',
        ],
      ),
      _VocabQuestion(
        word: 'inquiry',
        answer: 'question',
        options: ['question', 'celebration', 'accident', 'reward'],
      ),
    ];
    _lastVocabIndex = _nextDifferentIndex(questions.length, _lastVocabIndex);
    return questions[_lastVocabIndex];
  }

  _SentenceChallenge _nextSentenceChallenge() {
    const challenges = [
      _SentenceChallenge(
        prompt: 'Choose the more natural English sentence.',
        answer: 'I have been reading the article since morning.',
        options: [
          'I am reading the article since morning.',
          'I have been reading the article since morning.',
          'I reading the article from morning.',
        ],
      ),
      _SentenceChallenge(
        prompt: 'Pick the best sentence for polite everyday English.',
        answer: 'Could you please help me with this word?',
        options: [
          'Help me with this word.',
          'Could you please help me with this word?',
          'You help this word now.',
        ],
      ),
      _SentenceChallenge(
        prompt: 'Which sentence sounds clearer in standard English?',
        answer: 'She explained the news clearly to everyone.',
        options: [
          'She explained clearly the news to everyone.',
          'She explained the news clearly to everyone.',
          'She clear explained everyone the news.',
        ],
      ),
      _SentenceChallenge(
        prompt: 'Choose the best sentence for a formal update.',
        answer: 'I will share the report once the review is complete.',
        options: [
          'I share report once review complete.',
          'I will share the report once the review is complete.',
          'The report I will sharing after review complete.',
        ],
      ),
      _SentenceChallenge(
        prompt: 'Pick the most natural everyday sentence.',
        answer: 'We reached the office earlier than expected.',
        options: [
          'We reached earlier than expected the office.',
          'We reached the office earlier than expected.',
          'We was reaching office earlier expected.',
        ],
      ),
      _SentenceChallenge(
        prompt: 'Choose the clearer standard English sentence.',
        answer: 'The teacher encouraged the students to ask questions.',
        options: [
          'The teacher encouraged the students to ask questions.',
          'The teacher encouraged to students ask questions.',
          'Teacher encourage students for asking question.',
        ],
      ),
    ];
    _lastSentenceIndex = _nextDifferentIndex(
      challenges.length,
      _lastSentenceIndex,
    );
    return challenges[_lastSentenceIndex];
  }

  _SpellingBeeQuestion _nextSpellingBeeQuestion() {
    const questions = [
      _SpellingBeeQuestion(
        prompt: 'Choose the correct spelling.',
        answer: 'journalist',
        options: ['journalist', 'journelist', 'jornalist', 'journalisst'],
      ),
      _SpellingBeeQuestion(
        prompt: 'Choose the correct spelling.',
        answer: 'government',
        options: ['goverment', 'governmant', 'government', 'govarnment'],
      ),
      _SpellingBeeQuestion(
        prompt: 'Choose the correct spelling.',
        answer: 'language',
        options: ['langauge', 'language', 'langwage', 'languadge'],
      ),
      _SpellingBeeQuestion(
        prompt: 'Choose the correct spelling.',
        answer: 'independent',
        options: ['independant', 'independent', 'independet', 'indepandent'],
      ),
      _SpellingBeeQuestion(
        prompt: 'Choose the correct spelling.',
        answer: 'responsible',
        options: ['responsibel', 'responsible', 'responsable', 'responcible'],
      ),
      _SpellingBeeQuestion(
        prompt: 'Choose the correct spelling.',
        answer: 'education',
        options: ['educasion', 'educatoin', 'education', 'eduction'],
      ),
    ];
    _lastSpellingIndex = _nextDifferentIndex(
      questions.length,
      _lastSpellingIndex,
    );
    return questions[_lastSpellingIndex];
  }

  _CrosswordPuzzle _nextCrosswordPuzzle() {
    const puzzles = [
      _CrosswordPuzzle(clue: 'A newspaper opinion piece', answer: 'editorial'),
      _CrosswordPuzzle(
        clue: 'The main title of a news story',
        answer: 'headline',
      ),
      _CrosswordPuzzle(
        clue: 'Rules that help language make sense',
        answer: 'grammar',
      ),
      _CrosswordPuzzle(clue: 'A careful study of a topic', answer: 'analysis'),
      _CrosswordPuzzle(
        clue: 'A prediction of future conditions',
        answer: 'forecast',
      ),
      _CrosswordPuzzle(
        clue: 'A person who reports the news',
        answer: 'journalist',
      ),
    ];
    _lastCrosswordIndex = _nextDifferentIndex(
      puzzles.length,
      _lastCrosswordIndex,
    );
    return puzzles[_lastCrosswordIndex];
  }

  Future<void> _flushStreakSync() async {
    if (_syncingStreak || !_streakSyncPending) return;

    final authService = AuthService.instance;
    final streakToSync = [
      _bestLocalScrambleStreak,
      _sessionBestStreak,
      _scrambleStreak,
    ].reduce((a, b) => a > b ? a : b);
    if (!authService.isAuthenticated || streakToSync <= _bestSyncedStreak) {
      return;
    }

    _syncingStreak = true;
    try {
      await authService.syncStreak(streakToSync);
      _bestSyncedStreak = streakToSync;
      _streakSyncPending = false;
      await _saveProgress();
    } catch (_) {
      // Keep pending so the next app session can retry without interrupting play.
    } finally {
      _syncingStreak = false;
    }
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7EA), Color(0xFFF3DFC2)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3CCAC)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF6D1715),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WordScramblePuzzle {
  const _WordScramblePuzzle({
    required this.answer,
    required this.hint,
    this.scrambled,
  });

  final String answer;
  final String hint;
  final String? scrambled;

  _WordScramblePuzzle scrambledVariant(Random random) {
    final chars = answer.split('');
    chars.shuffle(random);
    var candidate = chars.join();
    if (candidate.toLowerCase() == answer.toLowerCase()) {
      chars.shuffle(random);
      candidate = chars.join();
    }
    return _WordScramblePuzzle(
      answer: answer,
      hint: hint,
      scrambled: candidate,
    );
  }
}

class _VocabQuestion {
  const _VocabQuestion({
    required this.word,
    required this.answer,
    required this.options,
  });

  final String word;
  final String answer;
  final List<String> options;
}

class _SentenceChallenge {
  const _SentenceChallenge({
    required this.prompt,
    required this.answer,
    required this.options,
  });

  final String prompt;
  final String answer;
  final List<String> options;
}

class _SpellingBeeQuestion {
  const _SpellingBeeQuestion({
    required this.prompt,
    required this.answer,
    required this.options,
  });

  final String prompt;
  final String answer;
  final List<String> options;
}

class _CrosswordPuzzle {
  const _CrosswordPuzzle({required this.clue, required this.answer});

  final String clue;
  final String answer;
}

// widgets/active_challenges_widget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:watermeter/controllers/gamification_controller.dart';
import 'package:watermeter/models/challenge.dart';
import 'package:watermeter/models/user_challenge.dart';

class ActiveChallengesWidget extends StatefulWidget {
  const ActiveChallengesWidget({Key? key}) : super(key: key);

  @override
  State<ActiveChallengesWidget> createState() => _ActiveChallengesWidgetState();
}

class _ActiveChallengesWidgetState extends State<ActiveChallengesWidget> {
  final GamificationController _controller = GamificationController();
  final Map<String, Timer> _activeTimers = {};
  final Map<String, int> _elapsedSeconds = {};
  String? _currentUserType;
  List<Challenge> _allChallenges = [];

  @override
  void initState() {
    super.initState();
    _loadUserTypeAndChallenges();
  }

  Future<void> _loadUserTypeAndChallenges() async {
    try {
      final userType = await _controller.getUserPersona();
      final challenges = _controller.getChallengesForPersona(userType);
      
      setState(() {
        _currentUserType = userType;
        _allChallenges = challenges;
      });
      
      print('👤 Loaded user type: $userType');
      print('📋 Available challenges: ${challenges.length}');
    } catch (e) {
      print('❌ Error loading user type: $e');
      setState(() {
        _currentUserType = 'casual';
        _allChallenges = _controller.getChallengesForPersona('casual');
      });
    }
  }

  @override
  void dispose() {
    _activeTimers.forEach((key, timer) => timer.cancel());
    super.dispose();
  }

  void _startChallengeTimer(UserChallenge userChallenge, Challenge challenge) {
    if (_activeTimers.containsKey(userChallenge.challengeId)) {
      return; // Timer already running
    }

    _elapsedSeconds[userChallenge.challengeId] = 0;

    _activeTimers[userChallenge.challengeId] = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;
        
        setState(() {
          _elapsedSeconds[userChallenge.challengeId] = 
              _elapsedSeconds[userChallenge.challengeId]! + 1;
        });

        // Check if time limit exceeded
        if (challenge.targetTime > 0 && 
            _elapsedSeconds[userChallenge.challengeId]! > challenge.targetTime) {
          _stopChallengeTimer(userChallenge, challenge, false);
        }
      },
    );
  }

  void _stopChallengeTimer(UserChallenge userChallenge, Challenge challenge, bool userStopped) async {
    final timer = _activeTimers[userChallenge.challengeId];
    if (timer != null) {
      timer.cancel();
      _activeTimers.remove(userChallenge.challengeId);
    }

    final elapsedTime = _elapsedSeconds[userChallenge.challengeId] ?? 0;
    _elapsedSeconds.remove(userChallenge.challengeId);

    // Calculate liters based on activity
    double litersUsed = _calculateLitersUsed(elapsedTime, challenge.activity);

    // Complete the challenge
    await _controller.completeChallenge(
      userChallenge.challengeId, 
      elapsedTime, 
      litersUsed
    );

    if (userStopped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Challenge "${challenge.title}" completed!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double _calculateLitersUsed(int elapsedTime, String activity) {
    final rates = {
      'Bathing': 10.0,   // 10L per minute
      'Cleaning': 5.0,   // 5L per minute  
      'Washing': 15.0,   // 15L per minute
      'Cooking': 2.0,    // 2L per minute
    };
    return (elapsedTime / 60) * (rates[activity] ?? 8.0);
  }

  bool _isTimerRunning(String challengeId) {
    return _activeTimers.containsKey(challengeId);
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<Challenge> _getChallengeById(String challengeId) async {
    try {
      // Use the pre-loaded challenges for the current user type
      final challenge = _allChallenges.firstWhere(
        (challenge) => challenge.id == challengeId,
        orElse: () => Challenge(
          id: challengeId,
          title: 'Active Challenge',
          description: 'Complete this challenge to earn points',
          points: 0,
          type: _currentUserType ?? 'casual',
          activity: '',
          targetTime: 0,
          targetLiters: 0,
          difficulty: 'easy',
        ),
      );
      return challenge;
    } catch (e) {
      print('❌ Error finding challenge $challengeId: $e');
      return Challenge(
        id: challengeId,
        title: 'Active Challenge',
        description: 'Complete this challenge to earn points',
        points: 0,
        type: _currentUserType ?? 'casual',
        activity: '',
        targetTime: 0,
        targetLiters: 0,
        difficulty: 'easy',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserType == null) {
      return _buildLoadingState();
    }

    return StreamBuilder<List<UserChallenge>>(
      stream: _controller.getActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading challenges: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return _buildEmptyState();
        }

        final activeChallenges = snapshot.data!;

        if (activeChallenges.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active ${_capitalize(_currentUserType!)} Challenges',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B47),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track and complete your ongoing challenges',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...activeChallenges.map((userChallenge) => 
              _buildActiveChallengeCard(userChallenge)
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveChallengeCard(UserChallenge userChallenge) {
    return FutureBuilder<Challenge>(
      future: _getChallengeById(userChallenge.challengeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChallengeCardLoading();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildChallengeCardError(userChallenge.challengeId);
        }

        final challenge = snapshot.data!;
        final isTimerRunning = _isTimerRunning(userChallenge.challengeId);
        final elapsedTime = _elapsedSeconds[userChallenge.challengeId] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isTimerRunning ? Colors.orange.shade300 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isTimerRunning ? Colors.orange.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isTimerRunning ? Icons.timer : Icons.flag,
                      color: isTimerRunning ? Colors.orange : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          challenge.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(challenge.difficulty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      challenge.difficulty.toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(challenge.difficulty),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Challenge requirements
              if (challenge.targetTime > 0)
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Complete within ${challenge.targetTime ~/ 60} minutes',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              
              if (challenge.targetLiters > 0)
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Use less than ${challenge.targetLiters}L',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Timer section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTimerRunning ? 'Time Elapsed' : 'Ready to Start',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(elapsedTime),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isTimerRunning ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (isTimerRunning) {
                              _stopChallengeTimer(userChallenge, challenge, true);
                            } else {
                              _startChallengeTimer(userChallenge, challenge);
                            }
                          },
                          icon: Icon(
                            isTimerRunning ? Icons.stop : Icons.play_arrow,
                            size: 18,
                          ),
                          label: Text(isTimerRunning ? 'STOP' : 'START'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTimerRunning ? Colors.red : const Color(0xFF2D7DD2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    
                    // Progress indicator for time-based challenges
                    if (challenge.targetTime > 0 && isTimerRunning)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: elapsedTime / challenge.targetTime,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              elapsedTime > challenge.targetTime ? Colors.red : Colors.orange,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Time Progress',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '${((elapsedTime / challenge.targetTime) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: elapsedTime > challenge.targetTime ? Colors.red : Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Loading challenges...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.flag, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 8),
          Text(
            'No Active ${_currentUserType != null ? _capitalize(_currentUserType!) : ''} Challenges',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start a challenge from the gamification section',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCardLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 12),
          Text('Loading challenge...'),
        ],
      ),
    );
  }

  Widget _buildChallengeCardError(String challengeId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Challenge not found: $challengeId',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
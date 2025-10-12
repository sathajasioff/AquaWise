import 'package:flutter/material.dart';
import 'package:watermeter/services/invite_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watermeter/widgets/create_challenge_dialog.dart';

class InviteFriendsWidget extends StatefulWidget {
  final VoidCallback? onInviteSent;
  final List<String> preselectedFriends;

  const InviteFriendsWidget({
    super.key, 
    this.onInviteSent,
    this.preselectedFriends = const []
  });

  @override
  State<InviteFriendsWidget> createState() => _InviteFriendsWidgetState();
}

class _InviteFriendsWidgetState extends State<InviteFriendsWidget> {
  String _referralCode = '';
  int _referralCount = 0;
  int _referralPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await InviteService.getReferralStats();
      setState(() {
        _referralCode = stats['referralCode'];
        _referralCount = stats['referralCount'];
        _referralPoints = stats['referralPoints'];
      });

      // Generate code if doesn't exist
      if (_referralCode.isEmpty) {
        final newCode = await InviteService.generateReferralCode();
        setState(() {
          _referralCode = newCode;
        });
      }
    } catch (e) {
      print('Error loading referral data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_referralCode.isNotEmpty) {
      // Use share as a cross-platform copy alternative
      await Share.share('My AquaCard referral code: $_referralCode');
      _showCopySuccess();
    }
  }

  void _showCopySuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code $_referralCode copied!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareInvitation() async {
    await InviteService.shareInvitation();
    widget.onInviteSent?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation shared successfully! 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _createChallengeWithFriends() {
    showDialog(
      context: context,
      builder: (context) => CreateChallengeDialog(
        preselectedFriends: widget.preselectedFriends,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite Friends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Earn rewards together',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Referral Code Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Referral Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _referralCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.content_copy_rounded, color: Colors.white),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Rewards Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRewardStat(
                  icon: Icons.people_alt_rounded,
                  value: _referralCount.toString(),
                  label: 'Friends Joined',
                ),
                _buildRewardStat(
                  icon: Icons.emoji_events_rounded,
                  value: '$_referralPoints',
                  label: 'Points Earned',
                ),
                _buildRewardStat(
                  icon: Icons.water_drop_rounded,
                  value: '${_referralCount * 100}L',
                  label: 'Water Saved',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Benefits List
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BenefitItem(
                icon: Icons.workspace_premium_rounded,
                text: '100 Points for each friend who joins',
              ),
              SizedBox(height: 8),
              _BenefitItem(
                icon: Icons.group_work_rounded,
                text: 'Unlock exclusive community challenges',
              ),
              SizedBox(height: 8),
              _BenefitItem(
                icon: Icons.leaderboard_rounded,
                text: 'Special badge on leaderboard',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons - Now with two options
          Row(
            children: [
              // Share Invitation Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _shareInvitation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text(
                    'Share Invitation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Create Challenge Button (only show if friends are preselected)
              if (widget.preselectedFriends.isNotEmpty) ...[
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _createChallengeWithFriends,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Quick Share Options
          if (widget.preselectedFriends.isEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickShareOption(
                  icon: Icons.message_rounded,
                  label: 'Message',
                  color: Colors.green,
                  onTap: () => InviteService.shareViaSMS(),
                ),
                _QuickShareOption(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  color: Colors.blue,
                  onTap: () => InviteService.shareViaEmail(),
                ),
                _QuickShareOption(
                  icon: Icons.link_rounded,
                  label: 'Copy Link',
                  color: Colors.orange,
                  onTap: () => InviteService.copyToClipboard(),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '${widget.preselectedFriends.length} friend${widget.preselectedFriends.length > 1 ? 's' : ''} selected for challenge',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.yellowAccent,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
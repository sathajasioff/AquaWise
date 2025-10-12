import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watermeter/services/firebase_challenge_service.dart';

class EditChallengeDialog extends StatefulWidget {
  final Challenge challenge;

  const EditChallengeDialog({super.key, required this.challenge});

  @override
  State<EditChallengeDialog> createState() => _EditChallengeDialogState();
}

class _EditChallengeDialogState extends State<EditChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  
  DateTime _endDate = DateTime.now();
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing challenge data
    _titleController.text = widget.challenge.title;
    _descriptionController.text = widget.challenge.description;
    _goalController.text = widget.challenge.goalLiters.toString();
    _rewardController.text = widget.challenge.reward;
    _endDate = widget.challenge.endDate;
    _isPublic = widget.challenge.isPublic;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _updateChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseChallengeService.updateChallenge(
        challengeId: widget.challenge.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        endDate: _endDate,
        goalLiters: int.parse(_goalController.text),
        reward: _rewardController.text.trim(),
        isPublic: _isPublic,
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Challenge updated successfully!')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating challenge: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Challenge',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Goal Liters
                TextFormField(
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Goal (Liters)',
                    border: const OutlineInputBorder(),
                    helperText: 'Current progress: ${widget.challenge.currentLiters}L',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a goal';
                    }
                    final liters = int.tryParse(value);
                    if (liters == null || liters <= 0) {
                      return 'Please enter a valid number';
                    }
                    if (liters < widget.challenge.currentLiters) {
                      return 'Goal cannot be less than current progress (${widget.challenge.currentLiters}L)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Reward
                TextFormField(
                  controller: _rewardController,
                  decoration: const InputDecoration(
                    labelText: 'Reward',
                    hintText: 'e.g., Community picnic, Garden upgrade',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a reward';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // End Date
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM d, yyyy').format(_endDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Privacy Settings
                Row(
                  children: [
                    Checkbox(
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value ?? true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Make challenge public (visible to all users)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Current Progress Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current progress: ${widget.challenge.currentLiters}L / ${widget.challenge.goalLiters}L (${(widget.challenge.progress * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateChallenge,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update'),
                      ),
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
}
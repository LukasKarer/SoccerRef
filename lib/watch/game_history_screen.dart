import 'package:flutter/material.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import 'package:line_icons/line_icons.dart';
import '../services/sync_service.dart';
import '../models/game_session.dart';
import 'referee_screen.dart';
import '../widgets/wear_back_button_handler.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  final SyncService _syncService = SyncService();
  final ScrollController _scrollController = ScrollController();
  List<GameSession> _gameHistory = [];
  bool _isLoading = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _syncService.initialize();
    _loadGameHistory();

    // Listen to connectivity changes
    _syncService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        // If we just came online, sync local data
        if (isOnline) {
          _syncLocalToRemote();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _syncService.dispose();
    super.dispose();
  }

  Future<void> _loadGameHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use sync service to get all sessions (local + remote if online)
      final history = await _syncService.getAllGameSessions();
      setState(() {
        _gameHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading game history: $e')),
        );
      }
    }
  }

  Future<void> _syncLocalToRemote() async {
    try {
      await _syncService.syncLocalToRemote();
      // Reload history after sync
      await _loadGameHistory();
    } catch (e) {
      print('Error syncing to remote: $e');
    }
  }

  void _loadGame(GameSession session) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RefereeScreen(gameSession: session),
      ),
    );
  }

  void _showDeleteConfirmation(GameSession session) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Delete Game',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to delete this game?\n\n${session.homeTeam} vs ${session.awayTeam}\n\nThis action cannot be undone.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteGame(session);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGame(GameSession session) async {
    try {
      await _syncService.deleteGameSession(session.id);
      // Refresh the history list
      await _loadGameHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGameHistoryItem(GameSession session) {
    final isFinished = !session.isActive && session.endTime != null;
    final isActive = session.isActive && session.isGameStarted;
    final statusColor = isFinished
        ? Colors.green
        : (isActive ? Colors.orange : Colors.grey);
    final statusText = isFinished
        ? 'Finished'
        : (isActive ? 'Active' : 'Setup');

    return GestureDetector(
      onDoubleTap: () => _loadGame(session),
      onLongPress: () => _showDeleteConfirmation(session),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team names
              Text(
                '${session.homeTeam}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'vs',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 2),
              Text(
                '${session.awayTeam}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Score: ${session.score}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Last changed: ${_formatLastChanged(session.lastDateChanged)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(
                    _isOnline ? Icons.cloud_done : Icons.cloud_off,
                    size: 12,
                    color: _isOnline ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastChanged(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WearBackButtonHandler(
      onBackPressed: () {
        // Go back to home screen
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        /* appBar: AppBar(
          title: const Text('Game History'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadGameHistory,
              tooltip: 'Refresh History',
            ),
          ],
        ), */
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _gameHistory.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LineIcons.history, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'No games played yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your first game to see it here!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : WearOsScrollView(
                controller: _scrollController,
                autoHide: true,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
                  itemCount: _gameHistory.length,
                  itemBuilder: (context, index) {
                    return _buildGameHistoryItem(_gameHistory[index]);
                  },
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import '../models/card_data.dart';
import '../widgets/card_widget.dart';
import 'connection_screen.dart';

class HandScreen extends StatefulWidget {
  const HandScreen({super.key});

  @override
  State<HandScreen> createState() => _HandScreenState();
}

class _HandScreenState extends State<HandScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<String> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _listenToMessages();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _listenToMessages() {
    final connectionService = context.read<ConnectionService>();
    connectionService.messages.listen((message) {
      if (message.type == 'chat') {
        final playerName = message.data['player_name'] as String;
        final text = message.data['message'] as String;
        setState(() {
          _chatMessages.add('$playerName: $text');
        });
        _scrollChatToBottom();
      }
    });
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final connectionService = context.read<ConnectionService>();
    connectionService.sendChatMessage(text);
    _chatController.clear();
  }

  void _playCard(CardData card) {
    final connectionService = context.read<ConnectionService>();
    connectionService.playCard(card);
  }

  void _disconnect() {
    final connectionService = context.read<ConnectionService>();
    connectionService.disconnect();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ConnectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ConnectionService>(
          builder: (context, connectionService, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connectionService.playerName ?? 'ECG Hand'),
                if (connectionService.gameCode != null)
                  Text(
                    'Game: ${connectionService.gameCode}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Disconnect',
          ),
        ],
      ),
      body: Consumer<ConnectionService>(
        builder: (context, connectionService, child) {
          if (connectionService.status != ConnectionStatus.connected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to game...'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Game status bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.green.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Connected • ${connectionService.hand.length} cards',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Hand display
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green.shade800, Colors.green.shade600],
                    ),
                  ),
                  child:
                      connectionService.hand.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.style,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No cards in hand',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Wait for the game to deal cards',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  connectionService.hand
                                      .map(
                                        (card) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: CardWidget(
                                            card: card,
                                            onTap: () => _playCard(card),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                ),
              ),

              // Chat section
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Chat header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text(
                          'Game Chat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Chat messages
                      Expanded(
                        child: ListView.builder(
                          controller: _chatScrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _chatMessages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _chatMessages[index],
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          },
                        ),
                      ),

                      // Chat input
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onSubmitted: (_) => _sendChatMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _sendChatMessage,
                              icon: const Icon(Icons.send),
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

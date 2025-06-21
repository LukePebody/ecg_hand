import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_service.dart';
import 'hand_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _connectToGame() async {
    final name = _nameController.text.trim();
    final code = _codeControllers.map((c) => c.text).join();

    if (name.isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    if (code.length != 6) {
      _showSnackBar('Please enter a 6-digit game code');
      return;
    }

    final connectionService = context.read<ConnectionService>();
    await connectionService.connectToGame(code, name);

    if (mounted && connectionService.status == ConnectionStatus.connected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HandScreen()),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<ConnectionService>(
              builder: (context, connectionService, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Title
                    const Icon(Icons.style, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'ECG Hand',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect to Every Card Game Table',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Name input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.all(20),
                        ),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Game code label
                    const Text(
                      'Enter 6-digit game code:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6-digit code input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 50,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged:
                                (value) => _onCodeDigitChanged(index, value),
                            onSubmitted: (_) {
                              if (index == 5) {
                                _connectToGame();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),

                    // Connect button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            connectionService.status ==
                                    ConnectionStatus.connecting
                                ? null
                                : _connectToGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child:
                            connectionService.status ==
                                    ConnectionStatus.connecting
                                ? const CircularProgressIndicator()
                                : const Text(
                                  'Connect to Game',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error message
                    if (connectionService.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                connectionService.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Instructions
                    Text(
                      'Ask the game host for their 6-digit code',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

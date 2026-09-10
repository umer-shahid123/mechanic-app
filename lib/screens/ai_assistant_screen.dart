import 'package:flutter/material.dart';
import 'package:mechanic_app/services/ai_service.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    final response = await AiService.getAiResponse(text);

    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppColors.textDark), 
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Assistant', 
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textDark, 
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
              ? _buildWelcomeView(isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return _buildChatBubble(msg['content']!, isUser, isDark);
                  },
                ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppColors.neonGreen : AppColors.primary),
                ),
              ),
            ),

          // Bottom Chat Input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC), 
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      ),
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Describe your car issue...', 
                          hintStyle: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? AppColors.glowShadow : [],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1), 
                  blurRadius: 30, 
                ),
              ],
            ),
            child: Icon(
              Icons.smart_toy_rounded, 
              size: 50, 
              color: isDark ? AppColors.neonGreen : AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Describe a problem or ask about car maintenance. I\'ll provide a quick diagnosis and PKR estimates.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkGrey : Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 32),
          _AiChip(
            text: 'White smoke from exhaust', 
            icon: Icons.cloud_outlined, 
            isDark: isDark,
            onTap: () {
              _controller.text = 'White smoke is coming from my exhaust. What could be the issue?';
              _sendMessage();
            },
          ),
          _AiChip(
            text: 'Brake squeaking sound', 
            icon: Icons.warning_amber_rounded, 
            isDark: isDark,
            onTap: () {
              _controller.text = 'My brakes are making a squeaking sound. Is it dangerous?';
              _sendMessage();
            },
          ),
          _AiChip(
            text: 'Engine overheating PKR estimate', 
            icon: Icons.thermostat_rounded, 
            isDark: isDark,
            onTap: () {
              _controller.text = 'How much does it cost to fix an overheating engine in Pakistan?';
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String content, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser 
            ? (isDark ? AppColors.neonGreen : AppColors.secondary)
            : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser 
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white : AppColors.textDark),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _AiChip({required this.text, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDark ? AppColors.neonGreen : AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text, 
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded, 
                size: 12, 
                color: isDark ? AppColors.darkGrey : AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

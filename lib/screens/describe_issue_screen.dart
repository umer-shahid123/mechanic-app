import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/indrive_request_screen.dart';
import 'package:mechanic_app/services/ai_service.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class DescribeIssueScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final String serviceType;

  const DescribeIssueScreen({super.key, required this.vehicleId, required this.vehicleName, required this.serviceType});

  @override
  State<DescribeIssueScreen> createState() => _DescribeIssueScreenState();
}

class _DescribeIssueScreenState extends State<DescribeIssueScreen> {
  final TextEditingController _descController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();

  List<String> _possibleCauses = [];
  String _criticalWarning = '';
  bool _isAnalyzing = false;
  bool _showResults = false;
  bool _isListening = false;
  File? _selectedImage;

  Future<void> _startListening() async {
    try {
      bool hasPermission = await Permission.microphone.request().isGranted;
      if (!hasPermission) {
        _showError('Microphone permission is required.');
        return;
      }

      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _descController.text = result.recognizedWords;
              if (result.finalResult) _isListening = false;
            });
          },
        );
      }
    } catch (e) {
      _showError('Voice recognition error: $e');
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _selectedImage = File(photo.path));
      }
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  void _analyzeIssue() async {
    final text = _descController.text.trim();
    if (text.isEmpty && _selectedImage == null) {
      _showError('Please provide a description or a photo.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResults = false;
      _possibleCauses = [];
      _criticalWarning = '';
    });

    try {
      final response = await AiService.getAiResponse(
        text.isEmpty ? "Analyze this vehicle issue." : text,
        imageFile: _selectedImage,
      );

      if (response.startsWith('ERROR:')) {
        setState(() {
          _isAnalyzing = false;
          _showResults = true;
          _possibleCauses = [response.replaceAll('ERROR:', '').trim()];
          _criticalWarning = 'Please check your connection and try again.';
        });
        return;
      }

      final lines = response.split('\n');
      setState(() {
        _isAnalyzing = false;
        _showResults = true;

        _possibleCauses = lines
            .where((l) => l.contains('•') || l.contains('-'))
            .map((l) => l.replaceAll(RegExp(r'[•\-*]'), '').trim())
            .take(3)
            .toList();

        if (_possibleCauses.isEmpty) {
          _possibleCauses = ['Check mechanical systems', 'Consult a nearby mechanic', 'Monitor performance'];
        }

        final criticalLine = lines.firstWhere(
          (l) => l.toLowerCase().contains('critical:'),
          orElse: () => 'Critical: Avoid driving if you notice smoke or high heat.',
        );
        _criticalWarning = criticalLine.replaceAll(RegExp('critical:', caseSensitive: false), '').trim();
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _showResults = true;
        _possibleCauses = ['Service unavailable'];
        _criticalWarning = 'Please try again later.';
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Smart Diagnosis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What\'s wrong with your vehicle?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1B4332))),
            const SizedBox(height: 12),
            Text('Describe the issue or use voice/photo to help our AI analyze the problem.', style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkGrey : Colors.black54, height: 1.5)),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    style: TextStyle(fontSize: 16, color: isDark ? Colors.white : const Color(0xFF1B4332), fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'e.g., engine overheating...',
                      hintStyle: TextStyle(color: isDark ? AppColors.darkGrey : Colors.black26),
                      border: InputBorder.none,
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover)),
                        Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => setState(() => _selectedImage = null), child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                      ],
                    ),
                  ],
                  const Divider(height: 32),
                  Row(
                    children: [
                      _buildIconButton(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, _isListening ? 'Stop' : 'Voice', isDark, _isListening ? Colors.red : null, _isListening ? _stopListening : _startListening),
                      const SizedBox(width: 20),
                      _buildIconButton(Icons.camera_alt_outlined, 'Photo', isDark, null, _pickImage),
                      const Spacer(),
                      SizedBox(
                        height: 50,
                        width: 120,
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzeIssue,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: _isAnalyzing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Analyze', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_showResults) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C0F0F) : const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24), const SizedBox(width: 12), Text('Possible Causes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1B4332)))]),
                    const SizedBox(height: 20),
                    ..._possibleCauses.map((cause) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [const Icon(Icons.circle, size: 6, color: Colors.redAccent), const SizedBox(width: 12), Text(cause, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87))]))),
                    const SizedBox(height: 20),
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent), const SizedBox(width: 8), Expanded(child: Text('Critical: $_criticalWarning', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent, height: 1.4)))])) ,
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => IndriveRequestScreen(vehicleId: widget.vehicleId, vehicleName: widget.vehicleName, serviceType: widget.serviceType, problemDescription: _descController.text)));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: const Text('Find Emergency Mechanic', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, bool isDark, Color? color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? (isDark ? AppColors.darkGrey : Colors.black54), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color ?? (isDark ? AppColors.darkGrey : Colors.black54))),
        ],
      ),
    );
  }
}

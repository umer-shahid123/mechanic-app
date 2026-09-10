import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/services/ai_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SmartDiagnosisScreen extends StatefulWidget {
  const SmartDiagnosisScreen({super.key});

  @override
  State<SmartDiagnosisScreen> createState() => _SmartDiagnosisScreenState();
}

class _SmartDiagnosisScreenState extends State<SmartDiagnosisScreen> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ImagePicker _picker = ImagePicker();
  
  bool _isAnalyzing = false;
  bool _isListening = false;
  String? _diagnosis;
  File? _selectedImage;

  Future<void> _startListening() async {
    try {
      bool hasPermission = await Permission.microphone.request().isGranted;
      if (!hasPermission) {
        _showError('Microphone permission is required for voice diagnosis.');
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
              if (result.finalResult) {
                _isListening = false;
              }
            });
          },
        );
      } else {
        _showError('Speech recognition is not available on this device.');
      }
    } catch (e) {
      _showError('Error initializing voice: $e');
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _pickImage() async {
    bool hasPermission = await Permission.camera.request().isGranted;
    if (!hasPermission) {
      _showError('Camera permission is required to take photos.');
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
      }
    } catch (e) {
      _showError('Could not open camera: $e');
    }
  }

  Future<void> _runAnalysis() async {
    if (_controller.text.isEmpty && _selectedImage == null) {
      _showError('Please provide a description or a photo.');
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _diagnosis = null;
    });

    try {
      final response = await AiService.getAiResponse(
        _controller.text.isEmpty ? "Please analyze this image for vehicle issues." : _controller.text,
        imageFile: _selectedImage,
      );
      if (mounted) {
        setState(() {
          _diagnosis = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diagnosis = "ERROR: Service temporarily unavailable. Please try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Smart Diagnosis', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s wrong with your vehicle?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Describe the issue or use voice/photo to help our AI analyze the problem.',
              style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                boxShadow: isDark ? [] : AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'e.g., Car is overheating, smoke from engine...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintStyle: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 14),
                    ),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      _ActionButton(
                        icon: _isListening ? Icons.mic_rounded : Icons.mic_none_rounded, 
                        label: _isListening ? 'Stop' : 'Voice', 
                        isDark: isDark,
                        color: _isListening ? Colors.red : null,
                        onTap: _isListening ? _stopListening : _startListening,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.camera_alt_outlined, 
                        label: 'Photo', 
                        isDark: isDark,
                        onTap: _pickImage,
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isAnalyzing ? null : _runAnalysis,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 40),
                          backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: _isAnalyzing 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Analyze', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_diagnosis != null) ...[
              const SizedBox(height: 32),
              _buildDiagnosisResult(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisResult(bool isDark) {
    bool isError = _diagnosis!.startsWith('ERROR:');
    
    // Parse the AI response
    List<String> bulletPoints = [];
    String criticalNote = '';
    
    if (!isError) {
      final lines = _diagnosis!.split('\n');
      for (var line in lines) {
        String trimmed = line.trim();
        if (trimmed.startsWith('•')) {
          bulletPoints.add(trimmed.substring(1).trim());
        } else if (trimmed.startsWith('Critical:')) {
          criticalNote = trimmed;
        } else if (trimmed.startsWith('-')) {
           bulletPoints.add(trimmed.substring(1).trim());
        }
      }
    }

    // Fallback if formatting is unexpected
    if (!isError && bulletPoints.isEmpty) {
      bulletPoints.add(_diagnosis!);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : (isError ? const Color(0xFFFFF5F5) : const Color(0xFFF0FFF4)),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (isError ? Colors.red : Colors.green).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, 
                color: isError ? Colors.red : Colors.green, 
                size: 24
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isError ? 'Diagnosis Error' : 'Possible Causes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isError)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _diagnosis!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _runAnalysis,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            ...bulletPoints.map((point) => _causeItem(point, isDark)),
            if (criticalNote.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⚠️ $criticalNote',
                  style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: isError ? Colors.grey : Colors.red),
              child: const Text('Find Emergency Mechanic', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _causeItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, 
    required this.label, 
    required this.isDark, 
    this.color, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color ?? (isDark ? AppColors.darkGrey : AppColors.grey), size: 20),
              const SizedBox(height: 4),
              Text(
                label, 
                style: TextStyle(
                  color: color ?? (isDark ? AppColors.darkGrey : AppColors.grey), 
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? ''; 
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> getAiResponse(String message, {File? imageFile}) async {
    try {
      if (_apiKey.isEmpty) {
        return 'ERROR: API key not configured.';
      }

      if (kDebugMode) {
        print('Initiating AI Request to OpenRouter (Multimodal)...');
      }

      List<Map<String, dynamic>> content = [
        {
          'type': 'text',
          'text': message,
        }
      ];

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        content.add({
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,$base64Image',
          },
        });
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json; charset=UTF-8',
          'HTTP-Referer': 'https://mechanic-app-v2.com',
          'X-OpenRouter-Title': 'MechanicAppV2',
        },
        body: jsonEncode({
          'model': 'openrouter/free', // Optimized for best available free vision models
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional car mechanic. Analyze the user\'s issue (text and optional image). \n\n'
                  'CRITICAL RULE: If the user\'s input is just a greeting or not related to a vehicle issue, respond with: "Analysis: • Please describe your car issue in detail • I can help with engine, brakes, AC, etc. • Mention sounds or smoke if any. Critical: I am ready to help once you provide details."\n\n'
                  'If it IS a valid car issue: Always start your response with "Analysis:" followed by 3 bullet points starting with "•". Then add a line starting with "Critical:" with a safety warning.'
            },
            {
              'role': 'user',
              'content': content,
            }
          ],
        }),
      ).timeout(const Duration(seconds: 45));

      if (kDebugMode) {
        print('AI Response Status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ?? 'ERROR: Empty response from AI';
        }
        return 'ERROR: No diagnosis available.';
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Server error';
        return 'ERROR: $errorMessage';
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI Service Error: $e');
      }
      return 'ERROR: Connection timeout or network issue.';
    }
  }
}

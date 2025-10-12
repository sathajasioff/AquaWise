import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiDebugService {
  static String? _apiKey;
  static bool _isInitialized = false;
  static String? _lastError;

  static Future<void> initialize() async {
    try {
      print('🔧 Starting Gemini Debug Service initialization...');
      
      // Load environment variables
      await dotenv.load(fileName: ".env");
      print('✅ Environment variables loaded');
      
      // Check if .env file has the key
      _apiKey = dotenv.env['GEMINI_API_KEY'];
      
      if (_apiKey == null) {
        _lastError = 'GEMINI_API_KEY is null in .env file';
        print('❌ $_lastError');
        _isInitialized = false;
        return;
      }
      
      if (_apiKey!.isEmpty) {
        _lastError = 'GEMINI_API_KEY is empty in .env file';
        print('❌ $_lastError');
        _isInitialized = false;
        return;
      }
      
      print('🔑 API Key found: ${_apiKey!.substring(0, 10)}...');
      
      // Test the API key with a simple request
      print('🔄 Testing Gemini API connection...');
      final testResult = await _testConnection();
      
      if (testResult) {
        _isInitialized = true;
        print('✅ Gemini HTTP Service initialized successfully');
      } else {
        _isInitialized = false;
        print('❌ Gemini HTTP Service initialization failed: $_lastError');
      }
    } catch (e) {
      _lastError = 'Initialization exception: $e';
      print('❌ Error initializing Gemini HTTP Service: $e');
      _isInitialized = false;
    }
  }

  static Future<bool> _testConnection() async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey';
      print('🌐 Testing URL: ${url.replaceAll(_apiKey!, '***')}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Say 'Connected' in one word"}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 15));

      print('📊 Test Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Connection test successful');
        return true;
      } else if (response.statusCode == 400) {
        _lastError = 'Bad Request (400) - Check API key format';
        print('❌ $_lastError');
        print('Response body: ${response.body}');
      } else if (response.statusCode == 403) {
        _lastError = 'Forbidden (403) - API key invalid or not enabled';
        print('❌ $_lastError');
      } else if (response.statusCode == 404) {
        _lastError = 'Not Found (404) - API endpoint not found';
        print('❌ $_lastError');
      } else {
        _lastError = 'HTTP ${response.statusCode} - ${response.body}';
        print('❌ $_lastError');
      }
      
      return false;
    } catch (e) {
      _lastError = 'Connection test exception: $e';
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  static Future<String?> generateText(String prompt) async {
    if (!_isInitialized || _apiKey == null) {
      print('❌ Gemini service not initialized. Last error: $_lastError');
      return null;
    }

    try {
      print('🔄 Sending request to Gemini API...');
      
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        try {
          if (data['candidates'] != null && 
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            
            final String generatedText = data['candidates'][0]['content']['parts'][0]['text'];
            print('✅ Gemini response received successfully');
            return generatedText;
          } else {
            print('❌ Invalid response format from Gemini API');
            return null;
          }
        } catch (e) {
          print('❌ Error parsing Gemini response: $e');
          return null;
        }
      } else {
        print('❌ Gemini API Error: ${response.statusCode}');
        print('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Gemini API Exception: $e');
      return null;
    }
  }

  static bool get isInitialized => _isInitialized;
  static String? get lastError => _lastError;
}
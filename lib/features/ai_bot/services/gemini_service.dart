import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// TODO: proxy Gemini calls through a Supabase Edge Function so the API key
// never ships in the compiled client app.

class GeminiService {
  GeminiService({
    HttpClient? client,
    String? apiKey,
    this.model = 'gemini-2.5-flash',
  })  : _client = client ?? HttpClient(),
        _apiKey = apiKey ?? (dotenv.env['GEMINI_API_KEY'] ?? '');

  final HttpClient _client;
  final String _apiKey;
  final String model;

  Future<String> generateReply({
    required String prompt,
    required List<Map<String, String>> history,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw StateError(
        'Gemini API key is not configured. Add GEMINI_API_KEY=your_key to the .env file at the project root (see .env.example for the expected format), then restart the app.',
      );
    }

    // TODO: Proxy this through a Supabase Edge Function so the API key never
    // ships in the compiled client app; keep direct calls only for now.
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
    );

    final contents = <Map<String, dynamic>>[
      ...history.map(
        (m) => {
          'role': m['role'],
          'parts': [
            {'text': m['text'] ?? ''}
          ],
        },
      ),
      {
        'role': 'user',
        'parts': [
          {'text': prompt}
        ],
      },
    ];

    final payload = jsonEncode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
    });

    try {
      final request = await _client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(payload));
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 400) {
        throw HttpException('Gemini API error ${response.statusCode}: $body');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      final first = candidates?.isNotEmpty == true
          ? candidates!.first as Map<String, dynamic>
          : null;
      final content = first?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts
          ?.map((e) => (e as Map<String, dynamic>)['text']?.toString() ?? '')
          .join()
          .trim();

      if (text == null || text.isEmpty) {
        throw StateError('Gemini returned an empty response.');
      }
      return text;
    } on SocketException catch (e) {
      debugPrint('Gemini network error: $e');
      rethrow;
    }
  }
}

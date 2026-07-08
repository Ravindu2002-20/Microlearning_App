import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// xAI Grok (OpenAI-compatible chat completions) service.
// TODO: Proxy this through a Supabase Edge Function so the API key never
// ships in the compiled client app; keep direct calls only for now.

class GeminiService {
  GeminiService({
    http.Client? client,
    String? apiKey,
    this.model = 'llama-3.3-70b-versatile',
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? (dotenv.env['XAI_API_KEY'] ?? '');

  final http.Client _client;
  final String _apiKey;
  final String model;

  Future<String> generateReply({
    required String prompt,
    required List<Map<String, String>> history,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw StateError(
        'xAI API key is not configured. Add XAI_API_KEY=your_key to the .env file at the project root, then restart the app.',
      );
    }

    // xAI Grok chat completions endpoint (OpenAI-compatible).
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final messages = <Map<String, String>>[
      ...history.map((m) => {
            'role': m['role'] ?? 'user',
            'content': m['text'] ?? '',
          }),
      {
        'role': 'user',
        'content': prompt,
      },
    ];

    final payload = jsonEncode({
      'model': model,
      'messages': messages,
    });

    try {
      final res = await _client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: payload,
          )
          .timeout(timeout);

      final body = res.body;
      if (res.statusCode >= 400) {
        throw StateError('xAI API error ${res.statusCode}: $body');
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      final first = choices?.isNotEmpty == true ? choices!.first : null;
      final message =
          first is Map<String, dynamic> ? first['message'] : null;
      final content =
          message is Map<String, dynamic> ? message['content'] : null;

      final text = content?.toString().trim() ?? '';
      if (text.isEmpty) {
        throw StateError('xAI returned an empty response.');
      }
      return text;
    } catch (e) {
      debugPrint('xAI network/gen error: $e');
      rethrow;
    }
  }
}


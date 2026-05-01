import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Configuration - Change this to your Ollama URL if it's not on the same machine
// Default: http://localhost:11434 (same machine)
// For remote Ollama: http://192.168.1.x:11434
String _ollamaUrl = 'http://localhost:11434';

void main() async {
  // Get the local IP address
  final ip = await getLocalIpAddress();
  final port = 8080;

  print('\n' + '=' * 60);
  print('VAWAR Ollama Server (Updated)');
  print('=' * 60);
  print('Server running at: http://$ip:$port');
  print('On your phone, use: http://$ip:$port');
  print('Supports: /api/generate, /api/chat, /api/tags');
  print('Ollama URL: $_ollamaUrl');
  print('=' * 60);
  print('\nTo change Ollama URL, edit the _ollamaUrl variable in server.dart');
  print('Make sure your phone is connected to the SAME WiFi!');
  print('Press Ctrl+C to stop the server\n');

  // Create HTTP server - bind to all interfaces for external access
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  await for (HttpRequest request in server) {
    // Enable CORS for cross-origin requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'POST, GET, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Content-Type',
    );

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      continue;
    }

    if (request.uri.path == '/api/generate' && request.method == 'POST') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = jsonDecode(body);

        final prompt = jsonBody['prompt'] ?? '';
        final model = jsonBody['model'] ?? 'phi3:mini';
        final stream = jsonBody['stream'] ?? false;

        print('\nGenerate Request - Model: $model');
        print(
          'Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...',
        );

        // Check if streaming is requested
        if (stream) {
          // Handle streaming response for /api/generate
          request.response.headers.add('Content-Type', 'text/event-stream');
          request.response.headers.add('Cache-Control', 'no-cache');
          request.response.headers.add('Connection', 'keep-alive');

          final client = http.Client();
          try {
            final ollamaResponse = await client.send(
              http.Request('POST', Uri.parse('$_ollamaUrl/api/generate'))
                ..headers['Content-Type'] = 'application/json'
                ..body = jsonEncode({
                  'model': model,
                  'prompt':
                      'Please provide a precise 4-line and proper and structured answer using bullet points for the following query: $prompt',
                  'stream': true,
                }),
            );

            await for (final chunk in ollamaResponse.stream.transform(
              utf8.decoder,
            )) {
              // Parse each chunk and extract response content
              final lines = chunk.split('\n').where((line) => line.isNotEmpty);
              for (final line in lines) {
                try {
                  final data = jsonDecode(line);
                  final content = data['response'] ?? '';
                  if (content.isNotEmpty) {
                    request.response.write(
                      'data: ${jsonEncode({'response': content})}\n\n',
                    );
                    await request.response.flush();
                  }
                  // Check if done
                  if (data['done'] == true) {
                    break;
                  }
                } catch (e) {
                  // Skip malformed JSON
                }
              }
            }
          } finally {
            client.close();
          }

          await request.response.close();
        } else {
          // Non-streaming response (original behavior)
          final ollamaResponse = await http
              .post(
                Uri.parse('$_ollamaUrl/api/generate'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'model': model,
                  'prompt':
                      'Please provide a precise 4-line and proper and structured answer using bullet points for the following query: $prompt',
                  'stream': false,
                }),
              )
              .timeout(const Duration(seconds: 120));

          if (ollamaResponse.statusCode == 200) {
            final data = jsonDecode(ollamaResponse.body);
            final response = data['response'] ?? 'No response';

            print('Response sent successfully');

            request.response.headers.add('Content-Type', 'application/json');
            request.response.write(jsonEncode({'response': response}));
          } else {
            print('Ollama error: ${ollamaResponse.statusCode}');
            request.response.statusCode = ollamaResponse.statusCode;
            request.response.write(
              jsonEncode({
                'error': 'Ollama error: ${ollamaResponse.statusCode}',
              }),
            );
          }
          await request.response.close();
        }
      } catch (e) {
        print('Error: $e');
        request.response.statusCode = 500;
        request.response.headers.add('Content-Type', 'application/json');
        request.response.write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      }
    } else if (request.uri.path == '/api/chat' && request.method == 'POST') {
      // New /api/chat endpoint for better conversation handling
      try {
        final body = await utf8.decoder.bind(request).join();
        final jsonBody = jsonDecode(body);

        final model = jsonBody['model'] ?? 'phi3:mini';
        final messages = jsonBody['messages'] ?? [];
        final stream = jsonBody['stream'] ?? false;

        // Extract the last user message for logging
        String lastPrompt = '';
        if (messages is List && messages.isNotEmpty) {
          for (var i = messages.length - 1; i >= 0; i--) {
            if (messages[i] is Map && messages[i]['role'] == 'user') {
              lastPrompt = messages[i]['content']?.toString() ?? '';
              break;
            }
          }
        }

        print('\nChat Request - Model: $model');
        print(
          'Last Message: ${lastPrompt.length > 50 ? lastPrompt.substring(0, 50) + '...' : lastPrompt}',
        );

        // Check if streaming is requested
        if (stream) {
          // Handle streaming response for /api/chat
          request.response.headers.add('Content-Type', 'text/event-stream');
          request.response.headers.add('Cache-Control', 'no-cache');
          request.response.headers.add('Connection', 'keep-alive');

          final client = http.Client();
          try {
            final ollamaResponse = await client.send(
              http.Request('POST', Uri.parse('$_ollamaUrl/api/chat'))
                ..headers['Content-Type'] = 'application/json'
                ..body = jsonEncode({
                  'model': model,
                  'messages': messages,
                  'stream': true,
                }),
            );

            await for (final chunk in ollamaResponse.stream.transform(
              utf8.decoder,
            )) {
              // Parse each chunk and extract message content
              final lines = chunk.split('\n').where((line) => line.isNotEmpty);
              for (final line in lines) {
                try {
                  final data = jsonDecode(line);
                  final message = data['message'] ?? {};
                  final content = message['content'] ?? '';
                  if (content.isNotEmpty) {
                    request.response.write(
                      'data: ${jsonEncode({'message': message})}\n\n',
                    );
                    await request.response.flush();
                  }
                  // Check if done
                  if (data['done'] == true) {
                    break;
                  }
                } catch (e) {
                  // Skip malformed JSON
                }
              }
            }
          } finally {
            client.close();
          }

          await request.response.close();
        } else {
          // Non-streaming chat response
          final ollamaResponse = await http
              .post(
                Uri.parse('$_ollamaUrl/api/chat'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'model': model,
                  'messages': messages,
                  'stream': false,
                }),
              )
              .timeout(const Duration(seconds: 120));

          if (ollamaResponse.statusCode == 200) {
            final data = jsonDecode(ollamaResponse.body);
            final message = data['message'] ?? {};
            final response = message['content'] ?? 'No response';

            print('Chat Response sent successfully');

            request.response.headers.add('Content-Type', 'application/json');
            request.response.write(
              jsonEncode({'message': message, 'done': data['done'] ?? true}),
            );
          } else {
            print('Ollama chat error: ${ollamaResponse.statusCode}');
            request.response.statusCode = ollamaResponse.statusCode;
            request.response.write(
              jsonEncode({
                'error': 'Ollama error: ${ollamaResponse.statusCode}',
              }),
            );
          }
          await request.response.close();
        }
      } catch (e) {
        print('Chat Error: $e');
        request.response.statusCode = 500;
        request.response.headers.add('Content-Type', 'application/json');
        request.response.write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      }
    } else if (request.uri.path == '/api/tags' && request.method == 'GET') {
      // New /api/tags endpoint to list available models
      try {
        final ollamaResponse = await http
            .get(
              Uri.parse('$_ollamaUrl/api/tags'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 30));

        if (ollamaResponse.statusCode == 200) {
          print('Model list sent successfully');
          request.response.headers.add('Content-Type', 'application/json');
          request.response.write(ollamaResponse.body);
        } else {
          print('Ollama tags error: ${ollamaResponse.statusCode}');
          request.response.statusCode = ollamaResponse.statusCode;
          request.response.write(
            jsonEncode({'error': 'Ollama error: ${ollamaResponse.statusCode}'}),
          );
        }
      } catch (e) {
        print('Tags Error: $e');
        request.response.statusCode = 500;
        request.response.headers.add('Content-Type', 'application/json');
        request.response.write(jsonEncode({'error': e.toString()}));
      }
      await request.response.close();
    } else if (request.uri.path == '/api/health' && request.method == 'GET') {
      // Health check endpoint to verify Ollama connectivity
      try {
        final ollamaResponse = await http
            .get(
              Uri.parse('$_ollamaUrl/api/tags'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        if (ollamaResponse.statusCode == 200) {
          print('Health check: Ollama is reachable');
          request.response.headers.add('Content-Type', 'application/json');
          request.response.write(
            jsonEncode({
              'status': 'healthy',
              'ollamaUrl': _ollamaUrl,
              'message': 'Ollama server is reachable',
            }),
          );
        } else {
          print(
            'Health check: Ollama returned status ${ollamaResponse.statusCode}',
          );
          request.response.headers.add('Content-Type', 'application/json');
          request.response.write(
            jsonEncode({
              'status': 'unhealthy',
              'ollamaUrl': _ollamaUrl,
              'message':
                  'Ollama server returned error: ${ollamaResponse.statusCode}',
            }),
          );
        }
      } catch (e) {
        print('Health check failed: $e');
        request.response.headers.add('Content-Type', 'application/json');
        request.response.write(
          jsonEncode({
            'status': 'unhealthy',
            'ollamaUrl': _ollamaUrl,
            'error': e.toString(),
            'message':
                'Cannot connect to Ollama. Check if Ollama is running and the URL is correct.',
          }),
        );
      }
      await request.response.close();
    } else if (request.uri.path == '/ip') {
      // Return server IP for easy access
      request.response.write(ip);
      await request.response.close();
    } else {
      request.response.write(
        'VAWAR Ollama Server - Use /api/generate or /api/chat endpoint',
      );
      await request.response.close();
    }
  }
}

Future<String> getLocalIpAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );

  for (var interface in interfaces) {
    for (var address in interface.addresses) {
      // Skip localhost and look for local network IP
      if (!address.isLoopback &&
          address.type == InternetAddressType.IPv4 &&
          !address.address.startsWith('169.')) {
        // Skip link-local
        return address.address;
      }
    }
  }

  // Fallback
  return '0.0.0.0';
}

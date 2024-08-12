import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ChatPdfpage extends StatefulWidget {
  @override
  _ChatPdfPageState createState() => _ChatPdfPageState();
}

class _ChatPdfPageState extends State<ChatPdfpage> {
  TextEditingController _textController = TextEditingController();
  File? _file;
  final List<Map<String, dynamic>> _messages = []; // List to store chat messages
  final String apiKey = 'AIzaSyCANHVScWu2aiETn9ChonqqPcCpMFWwl6g'; // Your API Key

  // Method to select a file (PDF) from the device storage
  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  void _removeFile() {
    setState(() {
      _file = null;
    });
  }

  Future<void> _sendRequest() async {
    if (_textController.text.isEmpty && _file == null) {
      return;
    }

    // Encode the selected file to base64
    String base64File = _file != null ? base64Encode(File(_file!.path).readAsBytesSync()) : '';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    // Create the request payload for the API call
    final requestPayload = {
      'contents': [
        {
          'parts': [
            {
              // Send either the user prompt or the default hidden prompt to the API
              'text': _textController.text.isEmpty
                  ? "Read this PDF and give a summary"
                  : _textController.text,
            },
            if (base64File.isNotEmpty)
              {
                'inlineData': {
                  'mimeType': 'application/pdf',
                  'data': base64File,
                },
              },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.9,
        'topK': 32,
        'topP': 0.95,
        'maxOutputTokens': 1024,
        'responseMimeType': 'text/plain',
      },
    };

    // Only add user prompt to chat if it's not empty
    if (_textController.text.isNotEmpty) {
      setState(() {
        _messages.add({
          'type': 'user',
          'content': _textController.text,
          'file': _file,
        });
      });
    } else if (_file != null) {
      setState(() {
        _messages.add({
          'type': 'user',
          'content': '[PDF]', // Placeholder text to indicate PDF sent by user
          'file': _file,
        });
      });
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Full response: $responseData'); // Keep this for debugging

        // Extract the text from the response
        final candidates = responseData['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'];
          if (parts != null && parts.isNotEmpty) {
            final modelResponse = parts[0]['text'];
            setState(() {
              _messages.add({
                'type': 'gemini',
                'content': modelResponse,
              });
            });
          } else {
            setState(() {
              _messages.add({
                'type': 'gemini',
                'content': 'No text found in response parts',
              });
            });
          }
        } else {
          setState(() {
            _messages.add({
              'type': 'gemini',
              'content': 'No candidates found in response',
            });
          });
        }

        _textController.clear();
        _removeFile();
      } else {
        print('Failed to get response from API: ${response.statusCode}');
        print('Error response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending request: $e');
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    bool isUser = message['type'] == 'user';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (isUser) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/user.jpg'), // Your user avatar image
            ),
          ),
        ],
        Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message['file'] != null) ...[
                        // Display a PDF placeholder or link (you need to implement this)
                        Text("[PDF File]"),
                        SizedBox(height: 10),
                      ],
                      Text(
                        message['content'],
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
            if (!isUser) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage:AssetImage('assets/pdf.png'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat With PDF'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter PDF/Prompt',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _selectFile,
                ),
                if (_file != null)
                  IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: _removeFile,
                  ),
              ],
            ),
          ),
          if (_file != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('[PDF Selected]'), // Placeholder, implement a PDF preview or link if needed
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _sendRequest,
              child: Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}

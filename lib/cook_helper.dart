import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CookPage extends StatefulWidget {
  @override
  _CookPageState createState() => _CookPageState();
}

class _CookPageState extends State<CookPage> {
  TextEditingController _textController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _messages = []; // List to store chat messages
  final String apiKey = 'AIzaSyCANHVScWu2aiETn9ChonqqPcCpMFWwl6g'; // Your API Key

  // Method to select an image from the gallery
  Future<void> _selectImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Method to capture an image using the camera
  Future<void> _captureImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> _sendRequest() async {
    if (_textController.text.isEmpty && _image == null) {
      return;
    }

    // Encode the selected image to base64
    String base64Image = _image != null ? base64Encode(File(_image!.path).readAsBytesSync()) : '';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    // Create the request payload for the API call
    final requestPayload = {
      'contents': [
        {
          'parts': [
            {
              // Send either the user prompt or the default hidden prompt to the API
              'text': _textController.text.isEmpty
                  ? "I have the ingredients above. Not sure what to cook for lunch. Show me a list of foods with the recipes."
                  : _textController.text,
            },
            if (base64Image.isNotEmpty)
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
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
          'image': _image,
        });
      });
    } else if (_image != null) {
      setState(() {
        _messages.add({
          'type': 'user',
          'content': '[Image]', // Placeholder text to indicate image sent by user
          'image': _image,
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
        _removeImage();
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
                    if (message['image'] != null) ...[
                      Image.file(message['image']),
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
              backgroundImage: AssetImage('assets/cook.png'),
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
        title: Text('Cook Helper'),
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
                      hintText: 'Enter Text/photo of ingredients you have',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _selectImage,
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _captureImage,
                ),
                if (_image != null)
                  IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: _removeImage,
                  ),
              ],
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.file(_image!),
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

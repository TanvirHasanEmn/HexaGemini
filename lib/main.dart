import 'package:flutter/material.dart';
import 'package:imgproject_one/sentiment_analysis.dart';
import 'chat_pdf.dart';
import 'cook_helper.dart';
import 'math_solver.dart';
import 'medical_care.dart';
import 'object_detection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HexaGemini'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Text("Developer: Tanvir Hasan"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/user.jpg',), // User avatar image
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(

          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          children: [

            _buildGridTile(
              context,
              'Object Detection',
              'assets/object.jpg',
              Colors.pinkAccent,
              ObjectPage(),
            ),
            _buildGridTile(
              context,
              'Medical Assistant',
              'assets/medical.png',
              Colors.orangeAccent,
              MedicalPage(),
            ),
            _buildGridTile(
              context,
              'Sentiment Analysis',
              'assets/sentiment.png',
              Colors.purpleAccent,
              SentimentPage(),
            ),
            _buildGridTile(
              context,
              'Math Solver',
              'assets/math.png',
              Colors.greenAccent,
              MathPage(),
            ),
            _buildGridTile(
              context,
              'Cook Helper',
              'assets/cook.png',
              Colors.blueAccent,
              CookPage(),
            ),
            _buildGridTile(
              context,
              'Chat PDF',
              'assets/pdf.png',
              Colors.redAccent,
              ChatPdfpage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTile(BuildContext context, String title, String imagePath, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: color,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 100,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

          ],
        ),

      ),
    );
  }
}

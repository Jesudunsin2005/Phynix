import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QuizPageState createState() => _QuizPageState();
}

// Quiz Page State
class _QuizPageState extends State<QuizPage> {
  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).primaryColor;
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quiz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppBar(
              backgroundColor: primaryColor,
              title: Text('Question 3/10'),
              centerTitle: true,
            ),
            Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 16.0, top: 30.0, bottom: 30.0),
                child: Text(
                  'Which soccer team won the FIFA World Cup for the first time?',
                  style: TextStyle(
                    fontSize: 25,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                )),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: 0.12,
              color: Colors.orange,
              backgroundColor: Colors.orange.shade100,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildOption(context, 'A', 'Uruguay', true),
                  _buildOption(context, 'B', 'Brazil', false),
                  _buildOption(context, 'C', 'Italy', false),
                  _buildOption(context, 'D', 'Germany', false),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHelpButton(context, Icons.skip_previous, 'Prev'),
                // _buildHelpButton(context, Icons.group, 'Audience'),
                _buildHelpButton(context, Icons.add, 'Add time'),
                _buildHelpButton(context, Icons.skip_next, 'Next'),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildOption(
      BuildContext context, String letter, String answer, bool selected) {
    Color primaryColor = Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? Colors.green.shade100 : Colors.white,
            // onPrimary: primaryColor,
            side: BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Colors.green : Colors.white,
                    border: Border.all(color: primaryColor),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: selected ? Colors.white : primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    answer,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Widget _buildHelpButton(BuildContext context, IconData icon, String label) {
    Color primaryColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: primaryColor,
          onPressed: () {},
        ),
        Text(
          label,
          style: TextStyle(color: primaryColor),
        ),
      ],
    );
  }
}

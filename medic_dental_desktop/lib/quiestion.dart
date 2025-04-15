import 'package:flutter/material.dart';

class QuestionScreen extends StatelessWidget {
  final List<Color> questionColors = [
    Colors.yellow,
    Colors.yellow,
    Colors.yellow,
    Colors.green,
    Colors.grey.shade300, // para sin responder
    Colors.green,
    Colors.green,
    Colors.green,
    Colors.green.shade900,
    Colors.green.shade900,
    Colors.black,
    Colors.cyan,
    Colors.lightBlue.shade100,
    Colors.lightBlue.shade100,
    Colors.lightBlue.shade100,
    Colors.lightBlue.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
    Colors.purple.shade100,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Kognition', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/profile.jpg'), // Imagen de perfil
                    radius: 16,
                  ),
                  SizedBox(width: 8),
                  Text('Claudia Sofía Abascal Amaya'),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),

            // Año lectivo
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Año Lectivo 2025 - 2026', style: TextStyle(color: Colors.white)),
            ),

            // Explicación
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Explicación\n\n"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            // Pregunta
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Pregunta 1", style: TextStyle(color: Colors.white, fontSize: 20)),
                    Spacer(),
                    Text(
                      'Me siento más cómodo/a siguiendo instrucciones detalladas.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                          onPressed: () {},
                          child: Text("Sí", style: TextStyle(color: Colors.black)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                          onPressed: () {},
                          child: Text("No", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // Footer con progreso
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 28,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: questionColors[index],
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${index + 1}')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

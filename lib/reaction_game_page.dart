import 'package:flutter/material.dart';
import 'screen_change_reaction_page.dart';
import 'dot_page.dart';
import 'dot_tracker_page.dart';
import 'anticipation_page.dart';


class ReactionGamePage extends StatelessWidget {
  const ReactionGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Text(
                'Reaction Game',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Click on a game to start playing that gamemode.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScreenChangeReaction()),
                  );
                },
                child: const Text('Screen Colour Change',
                  style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
                const SizedBox(height: 40),
                ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DotReactionGame()),
                  );
                },
                child: const Text('Random Dot',
                  style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              const SizedBox(height: 40),
                ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NeuroTrackerGame()),
                  );
                },
                child: const Text('Dot Tracker',
                  style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              const SizedBox(height: 40),
                ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 255, 255, 255)),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnticipationGame()),
                  );
                },
                child: const Text('Anticipation path',
                  style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
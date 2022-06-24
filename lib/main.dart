import 'package:audio_wave_form_demo/player_screen.dart';
import 'package:flutter/material.dart';

import './utils/audio_file_links.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio waveform demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) {
                    return const AudioPlayerScreen(
                      audioFileLink: audioWAV_27s,
                    );
                  },
                ));
              },
              child: const Text('Wav 27s'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) {
                    return const AudioPlayerScreen(
                      audioFileLink: audioWAV_03s,
                    );
                  },
                ));
              },
              child: const Text('Wav 03s'),
            ),
          ],
        ),
      ),
    );
  }
}

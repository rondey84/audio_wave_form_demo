import 'package:flutter/material.dart';
import 'package:audio_wave_form_demo/custom_waveform_screen.dart';
import 'package:flutter/rendering.dart';

import './utils/audio_file_links.dart';

void main() {
  // debugRepaintRainbowEnabled = true;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Custom Waveform WAV'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (ctx) {
                        return const AudioWaveformScreen(
                          audioFileLink: audioWAV_27s,
                        );
                      },
                    ));
                  },
                  child: const Text('Wav 27s'),
                ),
                const ElevatedButton(
                  onPressed: null,
                  child: Text('Wav 12s'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (ctx) {
                        return const AudioWaveformScreen(
                          audioFileLink: audioWAV_03s,
                        );
                      },
                    ));
                  },
                  child: const Text('Wav 03s'),
                ),
              ],
            ),
            const SizedBox(height: 80),
            const Text('Custom Waveform MP3'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (ctx) {
                        return const AudioWaveformScreen(
                          audioFileLink: audioMP3_27s,
                        );
                      },
                    ));
                  },
                  child: const Text('Mp3 27s'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (ctx) {
                        return const AudioWaveformScreen(
                          audioFileLink: audioMP3_12s,
                        );
                      },
                    ));
                  },
                  child: const Text('Mp3 12s'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (ctx) {
                        return const AudioWaveformScreen(
                          audioFileLink: audioMP3_03s,
                        );
                      },
                    ));
                  },
                  child: const Text('Mp3 03s'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

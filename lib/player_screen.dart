import 'dart:async';
import 'dart:io';
import 'package:audio_wave_form_demo/utils/audio_data_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:http/http.dart' as http;
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioFileLink;
  const AudioPlayerScreen({
    Key? key,
    required this.audioFileLink,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  String get url => widget.audioFileLink;
  AudioPlayer player = AudioPlayer();
  var maxDuration = const Duration(seconds: 1);
  var elapsedDuration = Duration.zero;

  late File audioFile;
  late File waveFile;

  List<double> samples = [];
  var totalSamples = 150;

  Stopwatch stopwatch1 = Stopwatch();
  @override
  void initState() {
    super.initState();
    player.onDurationChanged.listen((duration) {
      setState(() => maxDuration = duration);
    });

    player.onPositionChanged.listen((newPosition) {
      setState(() => elapsedDuration = newPosition);
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Player')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 12),
            waveform,
            const SizedBox(height: 30),
            answerGrids(Colors.red.shade300),
            const SizedBox(height: 16),
            replayButton,
            const SizedBox(height: 24),
            answerGrids(Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  late final Future? waveFormFuture = getAndCacheAudioFile().then((_) {
    loadWaveform().then((data) async {
      await parseJsonData(data);
      await loadAudio();
    });
  });

  Widget get waveform {
    return SizedBox(
      height: 250,
      width: MediaQuery.of(context).size.width - 32,
      child: FutureBuilder(
        future: waveFormFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // print(audioFile.path);
            // print(waveFile.path);
            // print(samples.length);

            return soundCloudWave;
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget get soundCloudWave {
    player.play(DeviceFileSource(audioFile.path));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RectangleWaveform(
          maxDuration: maxDuration,
          elapsedDuration: elapsedDuration,
          samples: samples,
          height: 100,
          width: MediaQuery.of(context).size.width - 32,
          absolute: true,
          borderWidth: 1,
          // inactiveBorderColor: Colors.amber,
          activeBorderColor: Colors.red,
          inactiveColor: Colors.grey,
        ),
        const SizedBox(height: 3),
        RectangleWaveform(
          maxDuration: maxDuration,
          elapsedDuration: elapsedDuration,
          samples: samples,
          height: 40,
          width: MediaQuery.of(context).size.width - 32,
          absolute: true,
          borderWidth: 0.5,
          // inactiveBorderColor: Colors.amber,
          activeBorderColor: Colors.red,
          inactiveColor: Colors.grey,
          invert: true,
        ),
      ],
    );
  }

  Future<void> parseJsonData(List<int> intSampleData) async {
    Map<String, dynamic> audioDataMap = {
      "rawSamples": intSampleData,
      "totalSamples": totalSamples,
    };
    final samplesData = await compute(loadparseJson, audioDataMap);
    setState(() {
      samples = samplesData['samples'];
    });
    stopwatch1.stop();
    print('Loading Waveform: ${stopwatch1.elapsed}');
  }

  Future<void> loadAudio() async {
    await player.setSourceDeviceFile(audioFile.path);
  }

  Future<List<int>> loadWaveform() async {
    waveFile = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'waveform.wave',
      ),
    );

    final c = Completer<List<int>>();
    StreamSubscription<WaveformProgress> progressStreamListner;
    progressStreamListner = JustWaveform.extract(
      audioInFile: audioFile,
      waveOutFile: waveFile,
    ).listen(null);

    progressStreamListner.onData((waveformProgress) {
      if (waveformProgress.waveform != null) {
        c.complete(waveformProgress.waveform!.data);
        progressStreamListner.cancel();
      }
    });

    return c.future;
  }

  Future<void> getAndCacheAudioFile() async {
    stopwatch1.start();
    final response = await http.get(Uri.parse(url));
    var buffer = response.bodyBytes.buffer;
    ByteData byteData = ByteData.view(buffer);
    File file = await File(
      p.join(
        (await getTemporaryDirectory()).path,
        'audioFile.wav',
      ),
    ).writeAsBytes(buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    ));
    // TODO: Write Temp caching logic
    audioFile = file;
    print('Fetching Audio File: ${stopwatch1.elapsed}');
  }

  Widget get replayButton {
    return CircleAvatar(
      child: IconButton(
        onPressed: () async {
          await player.seek(Duration.zero);
        },
        icon: const Icon(Icons.replay),
      ),
    );
  }

  Widget answerGrids(Color color) {
    return Container(
      height: color == Colors.deepPurple ? 120 : 80,
      width: MediaQuery.of(context).size.width - 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// Dart and Flutter Imports
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

// Packages Imports
import 'package:path/path.dart' as p show join;
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http show get;
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';

// Utils and Widget Imports
import 'package:audio_wave_form_demo/utils/audio_data_parser.dart';
import 'package:audio_wave_form_demo/widgets/custom_waveform.dart';

final stopwatch = Stopwatch();

class AudioWaveformScreen extends StatefulWidget {
  final String audioFileLink;
  const AudioWaveformScreen({
    Key? key,
    required this.audioFileLink,
  }) : super(key: key);

  @override
  State<AudioWaveformScreen> createState() => _AudioWaveformScreenState();
}

class _AudioWaveformScreenState extends State<AudioWaveformScreen> {
  String get url => widget.audioFileLink;
  AudioPlayer player = AudioPlayer();
  var maxDuration = const Duration(seconds: 1);
  var elapsedDuration = Duration.zero;

  late File audioFile;
  List<double> samples = [];
  var totalSamples = 70;

  @override
  void initState() {
    super.initState();

    player.onPositionChanged.listen((newPosition) {
      setState(() => elapsedDuration = newPosition);
    });

    // TODO: UPDATE page one last time or update the waveform widget once after player gets completed
    // Currently animation is getting stuck at 0.95 due to the above problem
    player.onPlayerComplete.listen((event) {
      // The bottom solution solves the above to-do, however a new issues arises
      // Issues: Setting state is replaying the audio from start
      // setState(() => elapsedDuration = maxDuration);
    });
  }

  @override
  void dispose() {
    // player.release();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Waveform')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 12),
            waveformWidget,
            const SizedBox(height: 30),
            answerGrids(Colors.red.shade300),
            const SizedBox(height: 16),
            controllButtons(),
            const SizedBox(height: 24),
            answerGrids(Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  late final Future? waveformFuture = getAndCacheAudioFile().then((file) {
    audioFile = file;
    print('Audio File: ${stopwatch.elapsed}');
    loadWaveform().then((waveform) {
      print('Waveform Samples: ${stopwatch.elapsed}');
      maxDuration = waveform.duration;
      parseJsonData(waveform.data, totalSamples).then((sample) async {
        samples = sample;
        await loadAudio();
      });
    });
  });

  // TODO: Write caching logic and implement reading file from cache
  Future<File> getAndCacheAudioFile() async {
    stopwatch.start();
    final response = await http.get(Uri.parse(url));
    var buffer = response.bodyBytes.buffer;
    ByteData byteData = ByteData.view(buffer);
    File file = await File(
      p.join((await getTemporaryDirectory()).path, 'audioFile.wav'),
    ).writeAsBytes(buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    ));
    return file;
  }

  Future<Waveform> loadWaveform() async {
    var waveFile = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'waveform.wave',
      ),
    );

    final c = Completer<Waveform>();
    StreamSubscription<WaveformProgress> progressStreamListner;
    progressStreamListner = JustWaveform.extract(
      audioInFile: audioFile,
      waveOutFile: waveFile,
    ).listen(null);

    progressStreamListner.onData((waveformProgress) {
      if (waveformProgress.waveform != null) {
        c.complete(waveformProgress.waveform);
        progressStreamListner.cancel();
      }
    });

    return c.future;
  }

  Future<void> loadAudio() async {
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSourceDeviceFile(audioFile.path);
  }

  Widget get waveformWidget {
    double height = 150;
    double gapVertical = 25;
    double gapHorizontal = 16;
    return Container(
      margin: EdgeInsets.symmetric(vertical: gapVertical),
      height: height - gapVertical,
      child: FutureBuilder(
        future: waveformFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox(
              height: height,
              child: _CustomWaveformWidget(
                audioPlayer: player,
                audioFilePath: audioFile.path,
                samples: samples,
                height: height - gapVertical,
                padding: gapHorizontal,
                maxDuration: maxDuration,
                elapsedDuration: elapsedDuration,
                majorActiveColor: const Color.fromARGB(255, 255, 135, 36),
                majorInactiveColor: const Color(0xFFE1DFDF),
                minorActiveColor: const Color(0xFFffbf99),
                minorInactiveColor: const Color(0xFFE1DFDF),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget controllButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleAvatar(
          child: IconButton(
            onPressed: () async {
              await player.pause();
            },
            icon: const Icon(Icons.pause_rounded),
          ),
        ),
        CircleAvatar(
          child: IconButton(
            onPressed: () async {
              await player.resume();
            },
            icon: const Icon(Icons.play_arrow_rounded),
          ),
        ),
        CircleAvatar(
          child: IconButton(
            onPressed: () async {
              await player.seek(Duration.zero);
            },
            icon: const Icon(Icons.replay_rounded),
          ),
        ),
      ],
    );
  }

  Widget answerGrids(Color color) {
    return Container(
      height: color == Colors.deepPurple ? 120 : 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _CustomWaveformWidget extends StatelessWidget {
  final List<double> samples;
  final double height;
  final double minorMajorGap;
  final double padding;
  final Color? majorActiveColor;
  final Color? majorInactiveColor;
  final Color? minorActiveColor;
  final Color? minorInactiveColor;
  final Duration maxDuration;
  Duration elapsedDuration;
  final AudioPlayer audioPlayer;
  final String audioFilePath;
  _CustomWaveformWidget({
    Key? key,
    required this.samples,
    required this.height,
    // ignore: unused_element
    this.minorMajorGap = 2.0,
    this.padding = 16.0,
    this.majorActiveColor,
    this.majorInactiveColor,
    this.minorActiveColor,
    this.minorInactiveColor,
    required this.maxDuration,
    required this.elapsedDuration,
    required this.audioPlayer,
    required this.audioFilePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    audioPlayer.play(DeviceFileSource(audioFilePath));
    final newheight = height - minorMajorGap;
    final width = MediaQuery.of(context).size.width - (padding * 2);
    return Column(
      children: [
        // Major Waveform
        CustomAudioWaveformWidget(
          samples: samples,
          height: newheight / 1.4,
          width: width,
          activeColor: majorActiveColor,
          inactiveColor: majorInactiveColor,
          absolute: true,
          maxDuration: maxDuration,
          elapsedDuration: elapsedDuration,
        ),
        SizedBox(height: minorMajorGap),
        // Minor Waveform
        CustomAudioWaveformWidget(
          samples: samples,
          height: newheight - (newheight / 1.4),
          width: width,
          activeColor: minorActiveColor,
          inactiveColor: minorInactiveColor,
          absolute: true,
          invert: true,
          maxDuration: maxDuration,
          elapsedDuration: elapsedDuration,
        ),
      ],
    );
  }
}

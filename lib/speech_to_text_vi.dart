library speech_to_text_vi;

import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class MicSheet extends StatefulWidget {
  final BuildContext context;
  final String title;
  final ValueSetter<String> resultSpeech;
  final double sheetHeight;
  MicSheet(
      {required this.context,
      required this.resultSpeech,
      this.sheetHeight = 250,
      this.title = 'Vui lòng chạm vào mic để nói'});
  @override
  _MicSheetState createState() => _MicSheetState();
}

class _MicSheetState extends State<MicSheet> {
  late SpeechToText _speech;
  bool _hasSpeech = false;
  String _currentLocaleId = 'vi_VN';
  double level = 0.0;
  double _minSoundLevel = 50000;
  double _maxSoundLevel = -50000;

  bool _animation = false;
  String _textResult = '';
  Timer? _timer;
  int _start = 59;

  final StreamController<String> _textResultStreamController =
      StreamController<String>();

  final StreamController<int> _timeCountStreamController =
      StreamController<int>();

  @override
  void initState() {
    _speech = SpeechToText();

    SchedulerBinding.instance!.addPostFrameCallback((_) async {
      await initSpeechState();
    });

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _textResultStreamController.close();
    _timeCountStreamController.close();
    _timer!.cancel();
    _timer = null;
    _speech.stop();
    widget.resultSpeech.call(_textResult);
    _textResult = '';
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        height: widget.sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 18, color: Colors.blue),
            ),
            AvatarGlow(
                animate: _animation,
                endRadius: 60,
                repeat: true,
                showTwoGlows: true,
                duration: Duration(milliseconds: 2000),
                glowColor: Colors.blue,
                repeatPauseDuration: Duration(milliseconds: 100),
                child: GestureDetector(
                  onTap: () {
                    initSpeechState();
                  },
                  child: Material(
                    // Replace this child with your own
                    elevation: 8.0,
                    shape: CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: !_animation ? Colors.red : Colors.blue,
                      child: Icon(
                        _animation
                            ? Icons.keyboard_voice
                            : Icons.keyboard_voice_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                      radius: 40.0,
                    ),
                  ),
                  // Container(
                  //   height: 80,
                  //   width: 80,
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     color: (_animation == false) ? Colors.red : Colors.blue,
                  //   ),
                  //   child: Icon(
                  //     _animation
                  //         ? Icons.keyboard_voice
                  //         : Icons.keyboard_voice_outlined,
                  //     color: Colors.white,
                  //     size: 40,
                  //   ),
                  // ),
                )),
            StreamBuilder(
                stream: _timeCountStreamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('00:${_start.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.red));
                  } else {
                    return Text('00:${_start.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.red));
                  }
                }),
            Padding(
              padding: const EdgeInsets.all(10),
              child: StreamBuilder(
                  stream: _textResultStreamController.stream,
                  builder: (context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.hasData) {
                      _textResult = snapshot.data!;
                      return Text(
                        _textResult,
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initSpeechState() async {
    if (!_animation) {
      bool hasSpeech = await _speech.initialize(
          finalTimeout: Duration(seconds: 5),
          onStatus: (status) => _statusListener(status),
          onError: (errorNotification) => _errorListener(errorNotification),
          debugLogging: true);
      if (hasSpeech) {
        _hasSpeech = hasSpeech;
        startListening();
        setState(() {
          _animation = true;
        });
      }
    } else {
      setState(() {
        _start = 59;
        if (mounted) _timeCountStreamController.sink.add(_start);
        _animation = !_animation;
        _timer!.cancel();
      });
    }
  }

  void _errorListener(SpeechRecognitionError error) {
    print("Received error status: $error, listening: ${_speech.isListening}");
  }

  void _statusListener(String status) {
    Future.delayed(Duration(seconds: 5)).then((value) {
      if (_speech.isNotListening && status == 'notListening') {
        Navigator.pop(widget.context);
      }
    });

    print(
        'Received listener status: $status, listening: ${_speech.isListening}');
  }

  void startListening() {
    _timer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        if (_start == 0) {
          setState(() {
            _animation = false;
            _speech.stop();
            timer.cancel();
          });
          _start = 59;
          if (mounted) _timeCountStreamController.sink.add(_start);
        } else {
          _start--;
          if (mounted) _timeCountStreamController.sink.add(_start);
        }
      },
    );

    _speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 59),
        pauseFor: Duration(seconds: 10),
        sampleRate: 44100,
        partialResults: true,
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
  }

  void resultListener(SpeechRecognitionResult result) {
    _textResultStreamController.sink.add(result.recognizedWords);
    _textResult = result.recognizedWords;
    print(_textResult);
  }

  void soundLevelListener(double level) {
    // minSoundLevel = min(minSoundLevel, level);
    // maxSoundLevel = max(maxSoundLevel, level);
    // print("sound level $level: $minSoundLevel - $maxSoundLevel ");
    // setState(() {
    //   this.level = level;
    // });
  }
}

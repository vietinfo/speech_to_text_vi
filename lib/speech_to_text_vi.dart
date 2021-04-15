library speech_to_text_vi;

import 'package:flutter/material.dart';
import 'package:speech_to_text_vi/mic_sheet.dart';

void showMicSheet(
    {String? title,
    required BuildContext homeContext,
    required ValueSetter<String> resultSpeech,
    double? sheetHeight}) {
  showModalBottomSheet(
    useRootNavigator: true,
    context: homeContext,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    builder: (context) {
      return MicSheet(
        context: context,
        resultSpeech: resultSpeech,
      );
    },
  );
}

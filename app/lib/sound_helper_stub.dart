import 'package:flutter/services.dart';

void playOrderChime({String orderCode = '', String customerName = '', String total = ''}) {
  try {
    SystemSound.play(SystemSoundType.alert);
  } catch (_) {}
}


import 'dart:math';

class MessageBank {
  MessageBank({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const List<String> _routineCompletedMessages = [
    'Rotina concluída!',
    'Mandou bem hoje!',
    'Você chegou lá!',
    'Missão cumprida!',
    'Ótimo trabalho!',
  ];

  String routineCompletedMessage() {
    return _routineCompletedMessages[
        _random.nextInt(_routineCompletedMessages.length)];
  }
}

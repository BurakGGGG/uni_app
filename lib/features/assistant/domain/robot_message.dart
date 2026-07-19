import 'robot_mood.dart';

/// Mesajın önerdiği eylem — rotaya eşlemeyi UI yapar (domain go_router
/// import etmez).
enum RobotAction { none, openWizard, addRank, openScoreCalculator, openLists }

/// Üni'nin tek bir konuşması. [id] şablon kimliğidir: analitik, tekrar
/// önleme (RobotMemory) ve testler bunun üzerinden çalışır.
class RobotMessage {
  final String id;
  final String text;
  final RobotMood mood;
  final RobotAction action;

  const RobotMessage(
    this.id,
    this.text,
    this.mood, {
    this.action = RobotAction.none,
  });
}

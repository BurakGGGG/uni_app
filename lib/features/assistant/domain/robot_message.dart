import 'robot_mood.dart';

/// Mesajın önerdiği eylem — rotaya eşlemeyi UI yapar (domain go_router
/// import etmez).
enum RobotAction {
  none,
  openWizard,
  addRank,
  openScoreCalculator,
  openLists,
  openBestPrograms,
}

/// Üni'nin tek bir konuşması. [id] şablon kimliğidir: analitik, tekrar
/// önleme (RobotMemory) ve testler bunun üzerinden çalışır.
class RobotMessage {
  final String id;
  final String text;
  final RobotMood mood;
  final RobotAction action;

  /// Eyleme veri taşıyan serbest parametre (ör. openBestPrograms için bölüm
  /// adı). Rotaya çevirmeyi yine UI yapar.
  final String? actionArg;

  const RobotMessage(
    this.id,
    this.text,
    this.mood, {
    this.action = RobotAction.none,
    this.actionArg,
  });
}

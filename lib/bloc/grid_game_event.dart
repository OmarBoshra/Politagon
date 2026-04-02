import '../models/position.dart';

abstract class GridGameEvent {}

class UserMoveEvent extends GridGameEvent {
  final String playerId;
  final Position pos;
  UserMoveEvent(this.playerId, this.pos);
}

class AiMoveEvent extends GridGameEvent {
  final String playerId;
  AiMoveEvent(this.playerId);
}

class RestartGameEvent extends GridGameEvent {}

class WithdrawEvent extends GridGameEvent {
  final String playerId;
  WithdrawEvent(this.playerId);
}

class ChangeSpectatorTargetEvent extends GridGameEvent {
  final bool next;
  ChangeSpectatorTargetEvent({this.next = true});
}

class ToggleStepByStepModeEvent extends GridGameEvent {}

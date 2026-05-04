import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:social_code/models/challenge.dart';
import 'package:social_code/services/challenge_service.dart';

// ============================================================
// EVENTS
// ============================================================
abstract class ChallengesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadChallenges extends ChallengesEvent {}

class CreateChallenge extends ChallengesEvent {
  final Challenge challenge;
  CreateChallenge(this.challenge);
  @override
  List<Object?> get props => [challenge];
}

class JoinChallenge extends ChallengesEvent {
  final String challengeId;
  final String userId;
  JoinChallenge(this.challengeId, this.userId);
  @override
  List<Object?> get props => [challengeId, userId];
}

// ============================================================
// STATES
// ============================================================
abstract class ChallengesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChallengesInitial extends ChallengesState {}
class ChallengesLoading extends ChallengesState {}

class ChallengesLoaded extends ChallengesState {
  final List<Challenge> challenges;
  ChallengesLoaded(this.challenges);
  @override
  List<Object?> get props => [challenges];
}

class ChallengesError extends ChallengesState {
  final String message;
  ChallengesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ============================================================
// BLOC
// ============================================================
class ChallengesBloc extends Bloc<ChallengesEvent, ChallengesState> {
  final ChallengeService _challengeService;

  ChallengesBloc(this._challengeService) : super(ChallengesInitial()) {
    on<LoadChallenges>(_onLoad);
    on<CreateChallenge>(_onCreate);
    on<JoinChallenge>(_onJoin);
  }

  Future<void> _onLoad(LoadChallenges event, Emitter<ChallengesState> emit) async {
    emit(ChallengesLoading());
    try {
      final challenges = await _challengeService.getChallenges();
      emit(ChallengesLoaded(challenges));
    } catch (e) {
      emit(ChallengesError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateChallenge event, Emitter<ChallengesState> emit) async {
    try {
      await _challengeService.createChallenge(event.challenge);
      add(LoadChallenges());
    } catch (e) {
      emit(ChallengesError(e.toString()));
    }
  }

  Future<void> _onJoin(JoinChallenge event, Emitter<ChallengesState> emit) async {
    try {
      await _challengeService.joinChallenge(event.challengeId, event.userId);
    } catch (e) {
      // silently fail join - UX will reflect it
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social_code/models/event.dart';
import 'package:social_code/services/event_service.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class EventsEvent extends Equatable {
  const EventsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPublishedEvents extends EventsEvent {}

class LoadAllEvents extends EventsEvent {}  // admin

class CreateEventRequested extends EventsEvent {
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final int totalSlots;
  final List<PriceTier> priceTiers;
  final String? bannerUrl;
  final EventStatus status;
  final String createdBy;

  const CreateEventRequested({
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.totalSlots,
    required this.priceTiers,
    this.bannerUrl,
    required this.status,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [title, eventDate, totalSlots];
}

class DeleteEventRequested extends EventsEvent {
  final String eventId;
  const DeleteEventRequested(this.eventId);
  @override
  List<Object?> get props => [eventId];
}

class UpdateEventRequested extends EventsEvent {
  final String eventId;
  final Map<String, dynamic> updates;
  const UpdateEventRequested(this.eventId, this.updates);
  @override
  List<Object?> get props => [eventId];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class EventsState extends Equatable {
  const EventsState();
  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<Event> events;
  const EventsLoaded(this.events);
  @override
  List<Object?> get props => [events];
}

class EventsError extends EventsState {
  final String message;
  const EventsError(this.message);
  @override
  List<Object?> get props => [message];
}

class EventCreating extends EventsState {}

class EventCreated extends EventsState {
  final Event event;
  const EventCreated(this.event);
  @override
  List<Object?> get props => [event.id];
}

class EventOperationError extends EventsState {
  final String message;
  const EventOperationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventService _service;

  EventsBloc(this._service) : super(EventsInitial()) {
    on<LoadPublishedEvents>(_onLoadPublished);
    on<LoadAllEvents>(_onLoadAll);
    on<CreateEventRequested>(_onCreate);
    on<DeleteEventRequested>(_onDelete);
    on<UpdateEventRequested>(_onUpdate);
  }

  Future<void> _onLoadPublished(
    LoadPublishedEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoading());
    try {
      final events = await _service.getPublishedEvents();
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onLoadAll(
    LoadAllEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventsLoading());
    try {
      final events = await _service.getAllEvents();
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateEventRequested event,
    Emitter<EventsState> emit,
  ) async {
    emit(EventCreating());
    try {
      final created = await _service.createEvent(
        title: event.title,
        description: event.description,
        location: event.location,
        eventDate: event.eventDate,
        totalSlots: event.totalSlots,
        priceTiers: event.priceTiers,
        bannerUrl: event.bannerUrl,
        status: event.status,
        createdBy: event.createdBy,
      );
      emit(EventCreated(created));
    } catch (e) {
      emit(EventOperationError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteEventRequested event,
    Emitter<EventsState> emit,
  ) async {
    try {
      await _service.deleteEvent(event.eventId);
      add(LoadAllEvents());
    } catch (e) {
      emit(EventOperationError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateEventRequested event,
    Emitter<EventsState> emit,
  ) async {
    try {
      await _service.updateEvent(event.eventId, event.updates);
      add(LoadAllEvents());
    } catch (e) {
      emit(EventOperationError(e.toString()));
    }
  }
}

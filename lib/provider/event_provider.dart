import 'package:flutter/cupertino.dart';
import 'package:indulge/data/models/sexual_event.dart';
import 'package:indulge/domain/repositories/sexual_event_repository.dart';
import 'package:indulge/data/repositories/sexual_event_repository_impl.dart';
import 'package:indulge/provider/event_state.dart';

class EventsProvider extends ChangeNotifier {
  EventState _state = EventState();
  late SexualEventRepository _repository;
  late final Future<String> _ready;

  EventsProvider() {
    _ready = _initProvider();
  }

  Future<String> _initProvider() async {
    _repository = await SexualEventRepositoryImpl.create();
    final counts = await _repository.getDailyEventCount();
    _state = _state.copyWith(dailyEventCount: counts);
    return "ready!";
  }

  Future<String> get ready => _ready;

  EventState get state => _state;

  void selectDate(DateTime date) {
    _state = _state.copyWith(selectedDate: date);
    _loadEventsForDate(date);
    notifyListeners();
  }

  void selectEvent(SexualEvent event) {
    _state = _state.copyWith(selectedEvent: event);
    _loadEventsForDate(_state.selectedDate);
    notifyListeners();
  }

  void removeActivityFromEdit(int id) async {
    _removeActivityFromEdit(id);
    _loadEventsForDate(_state.selectedDate);
    notifyListeners();
  }

  Future<void> _removeActivityFromEdit(int id) async {
    if (_state.selectedEvent == null) return;

    _repository.removeActivity(id);
    _state = _state.copyWith(
        selectedEvent:
            await _repository.getById(_state.selectedEvent!.baseEventId));
    notifyListeners();
  }

  Future<void> _loadEventsForDate(DateTime? date) async {
    if (date == null) {
      return;
    }

    _state = _state.copyWith(
      currentEvents: await _repository.getByDate(date),
    );
    notifyListeners();
  }
}

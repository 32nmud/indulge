class DBInterface {
  Future<Event> getEvent(String eventId) async {
    print("waiting...");
    return Future.delayed(const Duration(seconds: 4), () => Event.basic());
  }
}

class Event {
  final String id;
  final String? eventType;

  Event({required this.id, this.eventType});

  factory Event.basic() {
    return Event(id: "testid", eventType: "testeventtype");
  }
}

void main() async {
  DBInterface db = DBInterface();

  Event event = await db.getEvent("testId");
  print(event.eventType);
}

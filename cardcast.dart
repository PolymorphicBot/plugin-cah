part of cahbot;

class Deck {
  final String name;
  final List<String> questions;
  final List<String> responses;

  Deck(this.name, this.questions, this.responses);
}

Future<Deck> getDeck(String deckCode) {
  Completer<Deck> completer = new Completer<Deck>();

  http.get('https://api.cardcastgame.com/v1/decks/${deckCode}').then((res) {
    if (res.statusCode != 200)
      throw new StateError("Card deck ${deckCode} was not found. Perhaps make sure it is a valid code?");
    var json = JSON.decode(res.body);
    var name = json["name"];

    if (storage.getMap("q").containsKey(deckCode) || storage.getMap("r").containsKey(deckCode)) {
      var q = storage.getMap("q")[deckCode];
      var r = storage.getMap("q")[deckCode];

      completer.complete(new Deck(name, q, r));
      return;
    }

    http.get('https://api.cardcastgame.com/v1/decks/${deckCode}/cards').then((res) {
      var json = JSON.decode(res.body);

      var q = [];
      var r = [];

      json["calls"].forEach((c) { q.add(c["text"].join("_____")); });
      json["responses"].forEach((c) => r.add(c["text"][0]));

      storage.putInMap("q", deckCode, q);
      storage.putInMap("r", deckCode, r);

      storage.save();
      completer.complete(new Deck(name, q, r));
    });
  });

  return completer.future;
}

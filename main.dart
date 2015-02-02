library cahbot;

import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:polymorphic_bot/api.dart';
import "package:irc/client.dart" show Color;

part 'command.dart';
part 'cardcast.dart';
part 'game.dart';

var games = <CAHChannel, CAHGame> {};

@BotInstance()
BotConnector bot;

@PluginInstance()
Plugin plugin;

Storage storage;

void main(List<String> args, port) {
  polymorphic(args, port);
}

@Start()
void start() {
  storage = plugin.getStorage("storage", group: "CAH", saveOnChange: false);
  storage.load();

  if(!storage.entries.containsKey("q"))
    storage.setMap("q", new Map());
  if(!storage.entries.containsKey("r"))
    storage.setMap("r", new Map());
  storage.save();

  print("[CAH] Loading Plugin");
}

@CAHCommand("play", const [CAHCommandState.NOGAME, CAHCommandState.PREGAME])
void commandPlay(event) {
  if(event.state == CAHCommandState.PREGAME) {
    var game = games[event.channel];

    game.start();
    game.send("Game has now started! Please do not change nicknames or leave the channel (for now).");

    return;
  }

  var game = new CAHGame(event.channel);
  games[event.channel] = game;

  bot.getPrefix(event.channel.network, event.channel.name).then((prefix) {
    prefix = prefix + "cah";

    game.sendBlock('''Game is in set up mode! Once you're finished, type "${prefix} play" again.;
    Players can join with "${prefix} join".;
    A time limit can be set with "${prefix} until [score]".;
    Cardcast decks can be added with "${prefix} deck [deckCode]".''');
  });
}

@CAHCommand("join", const [CAHCommandState.PREGAME])
void commandJoin(event) {
  var game = games[event.channel];

  if(game.players.any((player) => player.name == event.user)) {
    event.reply("You are already in the player list!");
    return;
  }

  game.players.add(new Player(event.user));
  game.send("${event.user} joined the game.");
}

@CAHCommand("until", const [CAHCommandState.PREGAME])
void commandUntil(event) {
  var game = games[event.channel];

  try {
    game.until = int.parse(event.args[0]);
    game.send("Score limit has been changed to ${game.until}.");
  } catch(e) {
    print(e);
    game.send("${event.user}: ${event.args[1]} is not a number!");
  }
}

@CAHCommand("deck", const [CAHCommandState.PREGAME])
void commandDeck(event) {
  var game = games[event.channel];

  event.args.forEach((deckCode) {
    getDeck(deckCode)
      .then((deck) {
        game.questions.addAll(deck.questions);
        game.responses.addAll(deck.responses);
        game.send("Added pack '${deck.name}' with ${deck.questions.length} questions and ${deck.responses.length} responses.");
      })
      .catchError((error) {
        event.reply(error.toString());
      });
  });
}

part of cahbot;

class Player {
  String name;
  int score;

  Player(this.name);
}

class CAHGame {
  final CAHChannel channel;

  bool _started = false;

  List<Player> players = [];
  List<String> questions = [];
  List<String> responses = [];
  int until = 20;
  Player czar;

  bool get started => _started;

  CAHGame(this.channel);

  start() {
    _started = true;
    czar = players[new Random().nextInt(players.length)];
    send("${czar.name} is the Card Czar!");
  }

  send(String msg) => bot.sendMessage(this.channel.network, this.channel.name, "[${Color.BLUE}CAH${Color.RESET}] " + msg);

  sendBlock(String msg) => msg.split("\n").join("").split(';').forEach((line) => send(line.trim()));
}

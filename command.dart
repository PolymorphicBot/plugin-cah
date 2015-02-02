part of cahbot;

class CAHChannel {
  final String network;
  final String name;

  CAHChannel(this.network, this.name);

  int get hashCode => network.hashCode + name.hashCode;

  operator ==(CAHChannel other) => this.network == other.network && this.name == other.name;
}

class CAHCommand {
  final String name;
  final List<int> states;

  const CAHCommand(this.name, this.states);
}

class CAHCommandState {
  static const int NOGAME = 1;
  static const int PREGAME = 2;
  static const int GAME = 3;
}

class CAHCommandEvent {
  final CAHChannel channel;
  final String user;
  final List<String> args;
  final int state;

  CAHCommandEvent(this.channel, this.user, this.args, this.state);

  factory CAHCommandEvent.fromCommandEvent(CommandEvent event, int state) =>
    new CAHCommandEvent(new CAHChannel(event.network, event.channel), event.user, event.args.sublist(1), state);

  reply(String msg) => bot.sendMessage(this.channel.network, this.channel.name, "[${Color.BLUE}CAH${Color.RESET}] ${user}:" + msg);
}

@Command("cah")
void handleMessage(CommandEvent event) {
  if(event.args.length == 0)
    return;
  findFunctionAnnotations(CAHCommand).forEach((anno) {
    if(anno.metadata.name != event.args[0])
      return;

    var states = anno.metadata.states;
    int state = CAHCommandState.NOGAME;

    var channel = new CAHChannel(event.network, event.channel);
    if(games.containsKey(channel))
      state = games[channel].started ? CAHCommandState.GAME : CAHCommandState.PREGAME;

    var cahEvent = new CAHCommandEvent.fromCommandEvent(event, state);

    if(states.indexOf(state) < 0) {
      if(state == CAHCommandState.NOGAME) {
        bot.getPrefix(event.network, event.channel).then((prefix) {
          prefix = prefix + "cah";
          cahEvent.reply("A game hasn't been set up yet! Type '${prefix} play' to set up a game.");
        });
      }

      if(state == CAHCommandState.PREGAME) {
        bot.getPrefix(event.network, event.channel).then((prefix) {
          prefix = prefix + "cah";
          cahEvent.reply("The game is still being set up! Type '${prefix} play' to play.");
        });
      }

      if(state == CAHCommandState.GAME) {
        cahEvent.reply("Game has already started!");
      }
      return;
    }

    anno.invoke([cahEvent]);
  });
}

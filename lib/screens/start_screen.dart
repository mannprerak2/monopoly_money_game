import 'package:flutter/material.dart';
import 'package:monopoly_money/providers/players.dart';
import 'package:monopoly_money/providers/user.dart';
import 'package:monopoly_money/providers/world.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    //else below code

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              //edit the userNickName onTap
              var t = TextEditingController();
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Set NickName"),
                      content: TextField(
                        controller: t,
                        decoration: InputDecoration(hintText: "Nick Name"),
                      ),
                      actions: <Widget>[
                        RaisedButton(
                          child: Text(
                            "Set",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            if (t.text.trim().isNotEmpty) {
                              Provider.of<User>(context).nickName =
                                  t.text.trim();
                              Navigator.pop(context);
                            }
                          },
                        )
                      ],
                    );
                  });
            },
            child: Consumer<User>(
              builder: (context, user, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    user.nickName,
                    style: TextStyle(fontSize: 20),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text("HOST"),
                onPressed: onPressHost,
              ),
              RaisedButton(
                child: Text("JOIN"),
                onPressed: onPressJoin,
              )
            ],
          ),
        ],
      ),
    );
  }

  void onPressHost() async {
    setState(() {
      isLoading = true;
    });
    BuildContext context = World.context;
    try {
      await Nearby().startAdvertising(
          Provider.of<User>(context).nickName, Strategy.P2P_STAR,
          onConnectionInitiated: (endpointId, connectionInfo) async {
        try {
          await Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, payload) {},
          );
          //will only add if successful
          Provider.of<Players>(context)
              .addPlayer(Player(connectionInfo.endpointName, endpointId));
        } catch (exception) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(exception.toString()),
          ));
        }
      }, onConnectionResult: (endpointId, status) {
        if (status != Status.CONNECTED) {
          Provider.of<Players>(context).removePlayer(endpointId);
        }
      }, onDisconnected: (endpointId) {
        Provider.of<Players>(context).removePlayer(endpointId);
      });

      Provider.of<User>(context).isHost = true;
      // add your own name to list of players
      Provider.of<Players>(context)
          .addPlayer(Player(Provider.of<User>(context).nickName, null));
      // change state if advertising is started successfully
      Provider.of<World>(context).currentScreen = ScreenState.LobbyScreen;
    } catch (exception) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(exception.toString()),
      ));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onPressJoin() async {
    setState(() {
      isLoading = true;
    });

    BuildContext context = World.context;
    try {
      await Nearby().startDiscovery(
          Provider.of<User>(context).nickName, Strategy.P2P_STAR,
          onEndpointFound: (endpointId, endpointName, serviceId) async {
        try {
          await Nearby().requestConnection(
              Provider.of<User>(context).nickName, endpointId,
              onConnectionInitiated: (endpointId, connectionInfo) async {
            try {
              await Nearby().acceptConnection(
                endpointId,
                onPayLoadRecieved: (endpointId, payload) {},
              );
              //will only add if successful
              Provider.of<Players>(context)
                  .addPlayer(Player(connectionInfo.endpointName, endpointId));
            } catch (exception) {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(exception.toString()),
              ));
            }
          }, onConnectionResult: (endpointId, status) {
            if (status != Status.CONNECTED) {
              Provider.of<Players>(context).removePlayer(endpointId);
            } else {
              Provider.of<World>(context).currentScreen =
                  ScreenState.LobbyScreen;
            }
          }, onDisconnected: (endpointId) {
            Provider.of<Players>(context).removePlayer(endpointId);
          });
        } catch (exception) {
          print(exception.toString());
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text(exception.toString()),
          ));
        }
      }, onEndpointLost: (endpointId) {});

      Provider.of<User>(context).isHost = false;
      //add own name before start
      Provider.of<Players>(context)
          .addPlayer(Player(Provider.of<User>(context).nickName, null));
      // change state if discovery is started successfully

      Provider.of<World>(context).currentScreen = ScreenState.ConnectScreen;
    } catch (exception) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(exception.toString()),
      ));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

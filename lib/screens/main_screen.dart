/*
  Copyright (C) 2020 Naval Alcalá

  This file is part of Noesys.

  Noesys is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Noesys is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Noesys.  If not, see <https://www.gnu.org/licenses/>.
*/
import 'dart:async';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:noesys/models/server.dart';
import 'package:noesys/screens/about_screen.dart';
import 'package:noesys/screens/detail_screen.dart';
import 'package:noesys/screens/status_codes.dart';
import 'package:noesys/utils/crawler.dart' as util;
import 'package:noesys/utils/crawler.dart';

import 'package:noesys/screens/new_screen.dart';
import 'package:noesys/utils/sharedPref.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:synchronized/synchronized.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({required Key key, required this.title}) : super(key: key);

  final String title;

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Timer _timer;
  int _refreshTime = 5;
  List<Server>? _servers;
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final _lock = new Lock();

  SharedPref sharedPref = SharedPref();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void checkNotifications(List<Server> serverList) {
    serverList.forEach((server) {
      if (server.notify && server.notifyOn != null) {
        if (server.notifyOn!["4xx"] &&
            server.statusCode >= 400 &&
            server.statusCode < 500) {
          print(server.statusCode.toString() + ":" + server.url);
          showNotification(server.nameRaw, "4xx",
              server.statusCode.toString() + " detected in: " + server.name);
        } else if (server.notifyOn!["5xx"] &&
            server.statusCode >= 500 &&
            server.statusCode < 600) {
          print(server.statusCode.toString() + ":" + server.url);
          showNotification(server.nameRaw, "5xx",
              server.statusCode.toString() + " detected in: " + server.name);
        } else if (server.notifyOn!["0"] && server.statusCode == 0) {
          print("TIMEOUT" + ":" + server.url);
          showNotification(
              server.nameRaw, "Timeout", "Timeout detected in: " + server.name);
        } else if (server.notifyOn!["OK"] &&
            server.statusCode >= 200 &&
            server.statusCode <= 300) {
          server.notifyOn!["OK"] = false;
          showNotification(
              server.nameRaw, "Online", "Server online again: " + server.name);
        } else {
          print("UP: " + server.url);
        }
      }
    });
  }

  Future<bool> _onBackPressed() async {
    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Close monitor?'),
            content: Text(
                'If you close the application, the status of the servers cannot be checked and you will not receive notifications.'),
            actions: <Widget>[
              TextButton(
                child: Text('NO'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('YES'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        });
  }

  void _showBatteryInfo() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Battery optimization detected'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This app does not works well with'),
                Text('battery optimization, please consider'),
                Text('disable it.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                await DisableBatteryOptimization
                    .showDisableBatteryOptimizationSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSettings() async {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Refresh time"),
            content: StatefulBuilder(builder: (context, SBsetState) {
              return NumberPicker(
                  selectedTextStyle: TextStyle(color: Colors.red),
                  value: _refreshTime,
                  minValue: 1,
                  maxValue: 300,
                  onChanged: (value) {
                    SBsetState(() =>
                        _refreshTime = value); //* to change on dialog state
                  });
            }),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  setState(() {
                    sharedPref.save("refreshTime", _refreshTime.toString());

                    _timer.cancel();

                    Duration xSeconds = Duration(seconds: _refreshTime);
                    _timer = Timer.periodic(
                      xSeconds,
                      (Timer t) => _refresh(),
                    );

                    _refresh();
                  });

                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  Future<void> checkBatteryOpt() async {
    bool? isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;

    setState(() {
      if (isBatteryOptimizationDisabled != null &&
          isBatteryOptimizationDisabled) {
        // Igonring Battery Optimization
      } else {
        _showBatteryInfo();
      }
    });
  }

  Future<void> startNotifications() async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('noesys');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
  }

  @override
  void initState() {
    super.initState();
    startNotifications();
    loadServerList();
    loadData();

    sharedPref.read("refreshTime").then((result) {
      if (result == null) {
        sharedPref.save("refreshTime", _refreshTime.toString());
      } else {
        _refreshTime = int.parse(result);
      }

      Duration xSeconds = Duration(seconds: _refreshTime);
      _timer = Timer.periodic(
        xSeconds,
        (Timer t) => _refresh(),
      );

      setState(() {});
    });

    checkBatteryOpt();

    _servers = <Server>[];

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
  }

  Future<void> onSelectNotification(String? payload) async {
    if (_servers != null && payload != null) {
      var serverFiltered =
          _servers!.where((server) => server.nameRaw.contains(payload));
      if (serverFiltered.length > 0) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DetailScreen(server: serverFiltered.first)));
      }
    }
  }

  Future _refresh() {
    return _lock.synchronized(() async {
      return _fetchData().then((serversResult) {
        setState(() => _servers = serversResult);
      });
    });
  }

  Future<List<Server>> _fetchData() async {
    List<Server> serverList = await util.refreshDataServers();

    if (serverList.isNotEmpty) {
      checkNotifications(serverList);
    }

    return serverList;
  }

  void showAboutScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AboutScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topAppBar = AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      title: Text("Noesys"),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddScreen()))
                .then((value) {
              setState(() {
                _refresh();
              });
            });
          },
        ),
        HoldDetector(
          onHold: showAboutScreen,
          holdTimeout: Duration(milliseconds: 200),
          enableHapticFeedback: true,
          child: IconButton(
            icon: Icon(
              Icons.flip_camera_android_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              _showSettings();
            },
          ),
        ),
      ],
    );

    ListTile makeListTile(Server server) => ListTile(
          key: Key('ListTileServers'),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(width: 1.0, color: Colors.white24),
              ),
            ),
            child: server.getStatusIcon(),
          ),
          title: Text(
            server.name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Container(
                  child: LinearProgressIndicator(
                    backgroundColor: Color.fromRGBO(209, 224, 224, 0.2),
                    value: server.getUptime(),
                    valueColor: AlwaysStoppedAnimation(server.getStatusColor()),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Text("${server.country} ${server.url}",
                      style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
          trailing: Column(
            children: <Widget>[
              Text(server.statusCode.toString(),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(server.getStatusCode(),
                  style: TextStyle(color: server.getStatusColor())),
            ],
          ),
          onTap: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DetailScreen(server: server)))
                .then((value) {
              setState(() {
                _refresh();
              });
            });
          },
        );

    Card makeCard(Server server) => Card(
          elevation: 8.0,
          margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromRGBO(16, 10, 6, .9)),
            child: makeListTile(server),
          ),
        );

    final makeBody = Container(
        child: (_servers != null && _servers!.isNotEmpty)
            ? ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: _servers!.length,
                itemBuilder: (BuildContext context, int index) {
                  return makeCard(_servers![index]);
                },
              )
            : Center(
                child: Text("EMPTY SERVER LIST"),
              ));

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: topAppBar,
      body: WillPopScope(
        onWillPop: _onBackPressed,
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refresh,
          child: SafeArea(child: makeBody),
        ),
      ),
    );
  }

  showNotification(String nameRaw, String channel, String message) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('problem', 'Server status',
            channelDescription: 'Notify about server status responses',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Noesys notification');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(0, channel, message, notificationDetails, payload: nameRaw);
  }
}

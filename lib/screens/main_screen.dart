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
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:holding_gesture/holding_gesture.dart';
import 'package:noesys/models/server.dart';
import 'package:noesys/screens/about_screen.dart';
import 'package:noesys/screens/detail_screen.dart';
import 'package:noesys/utils/crawler.dart' as util;

import 'package:noesys/screens/manage_screen.dart';
import 'package:noesys/utils/sharedPref.dart';
import 'package:numberpicker/numberpicker.dart';

import '../utils/notify.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(UptimeHandler());
}

class UptimeHandler extends TaskHandler {
  SendPort? _sendPort;
  int _eventCount = 0;

  Future<List<Server>> _fetchData() async {
    var savedList = await SharedPref.reloadServerList();
    List<Server> checkedList = await util.refreshDataServers(savedList);

    return checkedList;
  }

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    await SharedPref.init();
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    await _fetchData().then((serversResult) {
      var servers = jsonEncode(serversResult);
      sendPort?.send(servers);
    });

    // Send data to the main isolate.
    sendPort?.send(_eventCount);
    _eventCount++;
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('onDestroy');
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed >> $id');
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() {
    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp("/resume-route");
    _sendPort?.send('onNotificationPressed');
  }
}

class ListScreen extends StatefulWidget {
  const ListScreen({required Key key, required this.title}) : super(key: key);

  final String title;

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Timer _timer;
  int _refreshTime = 10;
  List<Server> _servers = [];
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  ReceivePort? _receivePort;

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.drawable,
          resPrefix: ResourcePrefix.ic,
          name: 'noesys',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: _refreshTime * 1000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _requestPermissionForAndroid() async {
    if (!Platform.isAndroid) {
      return;
    }

    // Android 12 or higher, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<bool> _stopForegroundTask() {
    return FlutterForegroundTask.stopService();
  }

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    //await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    // Register the receivePort before starting the service.
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      print('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Noesys monitoring service',
        notificationText: 'Monitoring service is running',
        callback: startCallback,
      );
    }
  }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((data) {
      if (data is int) {
        print('eventCount: $data');
      } else if (data is String) {
        if (data == 'onNotificationPressed') {
          Navigator.of(context).pushNamed('/resume-route');
        } else {
          Iterable l = json.decode(data);

          List<Server> itemsList =
              List<Server>.from(l.map((i) => Server.fromJson(i)));
          setState(() {
            _servers = itemsList;
          });
        }
      } else if (data is DateTime) {
        print('timestamp: ${data.toString()}');
      }
    });

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  Future<bool> _onBackPressed() async {
    print(await FlutterForegroundTask.isRunningService);

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
                  _stopForegroundTask();
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
            backgroundColor: Colors.black12,
            title: Text("Monitoring interval (s)"),
            content: StatefulBuilder(builder: (context, SBsetState) {
              return NumberPicker(
                  selectedTextStyle: TextStyle(color: Colors.red),
                  value: _refreshTime,
                  minValue: 10,
                  maxValue: 300,
                  onChanged: (value) {
                    SBsetState(() =>
                        _refreshTime = value); //* to change on dialog state
                  });
            }),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () async {
                  await SharedPref.save("refreshTime", _refreshTime.toString());

                  FlutterForegroundTask.updateService(
                    foregroundTaskOptions: ForegroundTaskOptions(
                      interval: _refreshTime * 1000,
                      isOnceEvent: false,
                      autoRunOnBoot: true,
                      allowWakeLock: true,
                      allowWifiLock: true,
                    ),
                  );

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

  @override
  void initState() {
    super.initState();

    Future<void> onSelectNotification(String? payload) async {
      if (payload != null) {
        var server = SharedPref.getServer(payload);

        if (server != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailScreen(server: server)));
        }

        print(payload);
      }
    }

    startNotifications(onSelectNotification);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissionForAndroid();
      _initForegroundTask();
      _startForegroundTask();

      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });

    var refresh = SharedPref.read("refreshTime");
    if (refresh == null) {
      SharedPref.save("refreshTime", _refreshTime.toString());
    } else {
      _refreshTime = int.parse(refresh);
    }

    //checkBatteryOpt();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _refreshIndicatorKey.currentState?.show());
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
                    MaterialPageRoute(builder: (context) => ManageScreen()))
                .then((addedNewServer) {
              setState(() {
                if (addedNewServer == true) {
                  var serverList = SharedPref.loadServerList();
                  _servers = serverList;
                }
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
              Icons.track_changes,
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
                  child: Text("${server.url}",
                      style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
          trailing: Column(
            children: <Widget>[
              if (server.statusCode == -1 && server.enabled)
                Icon(Icons.hourglass_bottom_rounded, color: Colors.grey)
              else
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
                .then((returnStatus) async {
              setState(() {
                switch (returnStatus) {
                  case Status.DELETED:
                    _servers.removeWhere(
                        (element) => element.name == server.nameRaw);
                    break;
                  case Status.CHANGED:
                    var xServer = SharedPref.getServer(server.nameRaw);
                    if (xServer != null) {
                      _servers[_servers.indexWhere(
                              (element) => element.nameRaw == server.nameRaw)] =
                          xServer;
                    }
                    break;
                  default:
                }
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
        child: (_servers.isNotEmpty)
            ? ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: _servers.length,
                itemBuilder: (BuildContext context, int index) {
                  return makeCard(_servers[index]);
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
            onRefresh: () async {
              setState(() {
                _servers = SharedPref.loadServerList();
              });

              var savedList = await SharedPref.reloadServerList();
              List<Server> checkedList =
                  await util.refreshDataServers(savedList);

              setState(() {
                _servers = checkedList;
              });
            },
            child: SafeArea(child: makeBody),
          ),
        ));
  }
}

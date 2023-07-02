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
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:noesys/models/server.dart';
import 'package:noesys/utils/crawler.dart' as util;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../utils/sharedPref.dart';
import 'manage_screen.dart';

enum Status { DELETED, CHANGED, BACK }

Future<void> _deleteDialog(BuildContext context, Server server) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete server'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Do you want to delete this server?'),
              Text('This action is irrevocable'),
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
            child: Text('Delete'),
            onPressed: () async {
              await SharedPref.deleteServer(server.nameRaw);
              Navigator.of(context).pop();
              Navigator.pop(context, Status.DELETED);
            },
          ),
        ],
      );
    },
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({required this.server});

  final Server server;

  @override
  _DetailScreen createState() => _DetailScreen(server: server);
}

class _DetailScreen extends State<DetailScreen> {
  _DetailScreen({required this.server});

  Server server;
  late Timer _timerDetail;
  List<double> _data = [];
  bool _alarm = false;


  @override
  void initState() {
    _data = [server.responseTime + 0.0, server.responseTime + 0.1];
    if (server.notifiedOn != null && server.acknowledgedOn == null) {
      _alarm = true;
    } else {
      _alarm = false;
    }
    super.initState();

    const refreshDelay = const Duration(seconds: 1);

    _timerDetail = Timer.periodic(
      refreshDelay,
      (Timer t) => _refresh(),
    );
  }

  @override
  void dispose() {
    _timerDetail.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    var _server = await _fetchData();
    final List<double> dataResult = List.from(_data)
      ..add(_server.responseTime + 0.0);

    if (this.mounted) {
      server = _server;
      setState(() => _data = dataResult);
    }
  }

  void ackOnPressed() {
    server.acknowledgedOn = DateTime.now();
    server.notifiedOn = null;

    SharedPref.updateServer(server.nameRaw, server);
    setState(() => _alarm = false);
  }


  Future<Server> _fetchData() async {
    return util.refreshDataServer(server);
  }

  @override
  Widget build(BuildContext context) {
    final topAppBar = AppBar(
      //elevation: 0.1,
      backgroundColor: Theme.of(context).primaryColor,
      title: Text(server.nameRaw),

      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.edit,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ManageScreen(server: server)))
                .then((value) {
                  if (value == true){
                    Navigator.pop(context, Status.CHANGED);
                  }
                  else{
                    Navigator.pop(context, Status.BACK);
                  }

            });
            // do something
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: Colors.white,
          ),
          onPressed: () {
            _deleteDialog(context, server);
            // do something
          },
        )
      ],
    );
    final levelIndicator = Container(
      child: Container(
        child: LinearProgressIndicator(
            backgroundColor: Color.fromRGBO(209, 224, 224, 0.2),
            value: server.getUptime(),
            valueColor: AlwaysStoppedAnimation(server.getStatusColor())),
      ),
    );

    final topContentText = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          server.name,
          style: TextStyle(color: Colors.white, fontSize: 40.0),
        ),
        Container(
          width: 156.0,
          child: Divider(color: Colors.white),
        ),
        InkWell(
          child: Text(server.url,
              style: TextStyle(color: Colors.white70, fontSize: 25.0)),
          onTap: () => url_launcher.launchUrl(Uri.parse(server.url)),
        ),
        SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 1, child: levelIndicator),
            Expanded(
                flex: 6,
                child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(server.getStatusCode(),
                        style: TextStyle(color: server.getStatusColor())))),
            Expanded(flex: 1, child: server.getStatusIcon())
          ],
        ),
      ],
    );

    final topContent = Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(40.0),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Color.fromRGBO(0, 0, 0, .9)),
          child: Center(
            child: topContentText,
          ),
        ),
      ],
    );

    final bottomContentText = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            server.responseTime.toString(),
            style: TextStyle(fontSize: 54.0, color: Colors.white),
          ),
          Text(
            "milliseconds",
            style: TextStyle(fontSize: 14.0, color: Colors.white),
          )
        ]);

    final alarmButton = Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: ElevatedButton(
          onPressed: ackOnPressed, //() => {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(232, 53, 83, 1.0),
          ),
          child:
              Text("Acknowledgement", style: TextStyle(color: Colors.white)),
        ));

    final sparklineContent = Sparkline(
      data: _data,
      lineGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xffc93664), Color(0xffbe3d38)],
      ),
      fillMode: FillMode.none,
      pointsMode: PointsMode.all,
      pointSize: 5.0,
      pointColor: Colors.white,
    );

    List<Widget> showBottomContent() {
      switch (_alarm) {
        case true:
          return <Widget>[
            SizedBox(height: 10.0),
            bottomContentText,
            alarmButton,
            Text(
              'Until you acknowledge last alert no further notifications will be issued in relation to this server.',
              textAlign: TextAlign.center,
            ),
          ];
        case false:
        default:
          return <Widget>[
            sparklineContent,
            SizedBox(height: 10.0),
            bottomContentText,
          ];
      }
    }

    final bottomContent = Container(
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
      child: Center(
        child: Column(
          children: showBottomContent(),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: topAppBar,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[topContent, bottomContent],
            ),
          );
        },
      ),
    );
  }
}

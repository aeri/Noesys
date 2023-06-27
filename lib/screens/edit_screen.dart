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
import 'package:flutter/material.dart';
import 'package:noesys/utils/crawler.dart';
import 'package:string_validator/string_validator.dart';
import 'package:noesys/models/server.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({required this.server});

  final Server server;

  @override
  _EditScreen createState() => _EditScreen(server: server);
}

class _EditScreen extends State<EditScreen> {
  _EditScreen({required this.server});

  Server server;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final serverController = TextEditingController();
  final topicController = TextEditingController();
  bool notify = true;
  Map? notifyOn;

  @override
  void initState() {
    super.initState();
    notify = server.notify;
    notifyOn = server.notifyOn;
    nameController.text = server.name;
    serverController.text = server.url;
    topicController.text = server.country;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Update server')),
        body: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Builder(
              builder: (context) => Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      enabled: false,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                      controller: nameController,
                      decoration: InputDecoration(
                          icon: Icon(Icons.flag),
                          focusColor: Colors.grey,
                          hoverColor: Colors.grey,
                          labelText: 'Server name'),
                    ),
                    TextFormField(
                      keyboardType: TextInputType.url,
                      controller: serverController,
                      decoration: InputDecoration(
                          icon: Icon(Icons.link), labelText: 'Server URL/IP'),
                      validator: (value) {
                        if (value == null ||
                            (!isIP(value) &&
                                !isURL(value, {
                                  'require_protocol': true,
                                  'protocols': ['http', 'https']
                                }))) {
                          return 'Plase enter a valid URL/IP';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: topicController,
                      decoration: InputDecoration(
                          icon: Icon(Icons.topic), labelText: 'Topic'),
                      validator: (value) {
                        if (value == null) {
                          return 'Please enter a valid topic';
                        }
                        return null;
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 50, 0, 20),
                      child: Text('Notifications'),
                    ),
                    SwitchListTile(
                      activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                      title: const Text('Allow notifications'),
                      secondary: const Icon(Icons.lightbulb_outline),
                      value: notify,
                      onChanged: (bool val) => setState(() {
                        notify = val;
                        final notifyOn = this.notifyOn;
                        if (notifyOn != null) {
                          notifyOn.forEach((k, v) => notifyOn[k] = val);
                        }
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                      child: Text('Notify on'),
                    ),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('4xx'),
                        value: notifyOn != null ? notifyOn!["4xx"] : -1,
                        onChanged: (bool? val) => setState(() {
                              if (notifyOn != null) {
                                notifyOn!["4xx"] = val;
                                if ((val != null && val) ||
                                    notifyOn!.containsValue(true)) {
                                  notify = true;
                                } else {
                                  notify = false;
                                }
                              }
                            })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('5xx'),
                        value: notifyOn != null ? notifyOn!["5xx"] : -1,
                        onChanged: (bool? val) => setState(() {
                              if (notifyOn != null) {
                                notifyOn!["5xx"] = val;
                                if ((val != null && val) ||
                                    notifyOn!.containsValue(true)) {
                                  notify = true;
                                } else {
                                  notify = false;
                                }
                              }
                            })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('Timeout'),
                        value: notifyOn != null ? notifyOn!["0"] : -1,
                        onChanged: (bool? val) => setState(() {
                              if (notifyOn != null) {
                                notifyOn!["0"] = val;
                                if ((val != null && val) ||
                                    notifyOn!.containsValue(true)) {
                                  notify = true;
                                } else {
                                  notify = false;
                                }
                              }
                            })),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(232, 53, 83, 1.0),
                            ),
                            onPressed: () {
                              final form = _formKey.currentState;
                              if (form != null && form.validate()) {
                                form.save();

                                String serverAccess = serverController.text;

                                if (isIP(serverAccess)) {
                                  serverAccess = "http://" + serverAccess;
                                }

                                Server newServer = new Server(
                                    server.name,
                                    server.nameRaw,
                                    serverAccess,
                                    topicController.text,
                                    0,
                                    0,
                                    notify,
                                    notifyOn);

                                updateServer(server.nameRaw, newServer);

                                Navigator.pop(context, true);
                                Navigator.pop(context, true);
                              }
                            },
                            child: Text("Save",
                                style: TextStyle(color: Colors.white)))),
                  ],
                ),
              ),
            )));
  }
}

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
import 'package:string_validator/string_validator.dart';
import 'package:noesys/models/server.dart';

import '../utils/sharedPref.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({this.server});

  final Server? server;

  @override
  _ManageScreen createState() => _ManageScreen(server);
}

class _ManageScreen extends State<ManageScreen> {
  _ManageScreen(this.existingServer);

  final Server? existingServer;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final serverController = TextEditingController();
  final topicController = TextEditingController();
  bool enabled = true;
  bool notify = true;
  Map notifyOn = {
    "OK": false,
    "4xx": true,
    "5xx": true,
    "0": true,
  };

  @override
  void initState() {
    super.initState();

    if (existingServer != null) {
      notify = existingServer!.notify;
      enabled = existingServer!.enabled;
      notifyOn = existingServer!.notifyIn!;
      nameController.text = existingServer!.name;
      serverController.text = existingServer!.url;
      topicController.text = existingServer!.topic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title:
                Text(existingServer == null ? 'Add server' : 'Update server')),
        body: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Builder(
              builder: (context) => Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      enabled: existingServer == null,
                      controller: nameController,
                      decoration: InputDecoration(
                          icon: Icon(Icons.flag), labelText: 'Server name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a server name';
                        } else if (SharedPref.existServer(
                                value.toLowerCase()) &&
                            existingServer == null) {
                          return 'The server already exists';
                        } else {
                          return null;
                        }
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.url,
                      controller: serverController,
                      decoration: InputDecoration(
                          helperText: 'with protocol',
                          icon: Icon(Icons.link),
                          labelText: 'Server URL/IP'),
                      validator: (value) {
                        if (value == null ||
                            (!isIP(value) &&
                                !isURL(value, {
                                  'require_protocol': true,
                                  'protocols': ['http', 'https']
                                }))) {
                          return 'Please enter a valid URL/IP';
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
                      child: Text('General'),
                    ),
                    SwitchListTile(
                      activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                      title: const Text('Enabled'),
                      secondary: const Icon(Icons.power_settings_new_sharp),
                      value: enabled,
                      onChanged: (bool val) => setState(() {
                        enabled = val;
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 50, 0, 20),
                      child: Text('Notifications'),
                    ),
                    SwitchListTile(
                      activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                      title: const Text('Allow notifications'),
                      secondary: const Icon(Icons.notification_important),
                      value: notify,
                      onChanged: (bool val) => setState(() {
                        notify = val;
                        notifyOn.forEach((k, v) => notifyOn[k] = val);
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                      child: Text('Notify on'),
                    ),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('OK (200)'),
                        value: notifyOn["OK"],
                        onChanged: (bool? val) => setState(() {
                          notifyOn["OK"] = val;
                          if ((val != null && val) ||
                              notifyOn.containsValue(true)) {
                            notify = true;
                          } else {
                            notify = false;
                          }
                        })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('4xx'),
                        value: notifyOn["4xx"],
                        onChanged: (bool? val) => setState(() {
                              notifyOn["4xx"] = val;
                              if ((val != null && val) ||
                                  notifyOn.containsValue(true)) {
                                notify = true;
                              } else {
                                notify = false;
                              }
                            })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('5xx'),
                        value: notifyOn["5xx"],
                        onChanged: (bool? val) => setState(() {
                              notifyOn["5xx"] = val;
                              if ((val != null && val) ||
                                  notifyOn.containsValue(true)) {
                                notify = true;
                              } else {
                                notify = false;
                              }
                            })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('Timeout'),
                        value: notifyOn["0"],
                        onChanged: (bool? val) => setState(() {
                              notifyOn["0"] = val;
                              if ((val != null && val) ||
                                  notifyOn.containsValue(true)) {
                                notify = true;
                              } else {
                                notify = false;
                              }
                            })),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromRGBO(232, 53, 83, 1.0),
                            ),
                            onPressed: () async {
                              final form = _formKey.currentState;
                              if (form != null && form.validate()) {
                                form.save();

                                String serverAccess = serverController.text;

                                if (isIP(serverAccess)) {
                                  serverAccess = "http://" + serverAccess;
                                }

                                Server newServer = new Server(
                                    nameController.text,
                                    nameController.text.toLowerCase(),
                                    serverAccess,
                                    topicController.text,
                                    -1,
                                    0,
                                    notify,
                                    notifyOn,
                                    enabled);

                                if (existingServer != null) {
                                  await SharedPref.updateServer(
                                      newServer.nameRaw, newServer);
                                } else {
                                  await SharedPref.addServer(newServer);
                                }

                                Navigator.pop(context, true);
                              } else {
                                const snackBar = SnackBar(
                                  content: Text(
                                    'Error validating form',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.yellow,
                                );

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
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

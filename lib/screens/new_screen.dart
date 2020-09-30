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

class AddScreen extends StatefulWidget {
  @override
  _AddScreen createState() => _AddScreen();
}

class _AddScreen extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final serverController = TextEditingController();
  final topicController = TextEditingController();
  bool notify = true;
  Map notifyOn = {
    "OK": false,
    "4xx": true,
    "5xx": true,
    "0": true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Add server')),
        body: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Builder(
              builder: (context) => Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                          icon: Icon(Icons.flag), labelText: 'Server name'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a server name';
                        } else {
                          if (existServer(value.toLowerCase())) {
                            return 'The server already exists';
                          }
                        }
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.url,
                      controller: serverController,
                      decoration: InputDecoration(
                          helperText: 'with the protocol',

                          icon: Icon(Icons.link), labelText: 'Server URL/IP'),
                      validator: (value) {
                        if (value.isEmpty ||
                            (!isIP(value) &&
                                !isURL(value, {
                                  'require_protocol': true,
                                  'protocols': ['http', 'https']
                                }))) {
                          return 'Plase enter a valid URL/IP';
                        }
                      },
                    ),
                    TextFormField(
                      controller: topicController,
                      decoration: InputDecoration(
                          icon: Icon(Icons.cake), labelText: 'Topic'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a valid topic';
                        }
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
                        notifyOn.forEach((k, v) => notifyOn[k] = val);
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                      child: Text('Notify on'),
                    ),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('4xx'),
                        value: notifyOn["4xx"],
                        onChanged: (bool val) => setState(() {
                              notifyOn["4xx"] = val;
                              if (val || notifyOn.containsValue(true)) {
                                notify = true;
                              } else {
                                notify = false;
                              }
                            })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('5xx'),
                        value: notifyOn["5xx"],
                        onChanged: (bool val) => setState(() {
                              notifyOn["5xx"] = val;
                              if (val || notifyOn.containsValue(true)) {
                                notify = true;
                              } else {
                                notify = false;
                              }
                            })),
                    CheckboxListTile(
                        activeColor: Color.fromRGBO(232, 53, 83, 1.0),
                        title: const Text('Timeout'),
                        value: notifyOn["0"],
                        onChanged: (bool val) => setState(() {
                              notifyOn["0"] = val;
                              if (val || notifyOn.containsValue(true)) {
                                notify = true;
                              } else {
                                notify = false;
                              }
                            })),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: RaisedButton(
                            color: Color.fromRGBO(232, 53, 83, 1.0),
                            onPressed: () {
                              final form = _formKey.currentState;
                              if (form.validate()) {
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
                                    0,
                                    0,
                                    notify,
                                    notifyOn);

                                writeServer(newServer);

                                Navigator.pop(context, true);

                                //_showDialog(context);
                              }
                            },
                            child: Text("Save",
                                style: TextStyle(color: Colors.white)))),
                  ],
                ),
              ),
            )));
  }

  _showDialog(BuildContext context) {
    print(_formKey.currentState.toString);
    Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Submitting form')));
  }
}

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
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final makeBody = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(30),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Column(children: [
              SizedBox(width: 30),
              Text(
                'Noesys',
                style: TextStyle(color: Colors.white, fontSize: 40),
              ),
              Padding(
                padding: EdgeInsets.all(20),
              ),
              SizedBox(width: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(width: 10),
                  Text(
                    'Licensed under GPL-3.0 License.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(width: 10),
                  InkWell(
                    child: Text('https://github.com/aeri/noesys',
                        style:
                            TextStyle(color: Color.fromRGBO(232, 53, 83, 1.0))),
                    onTap: () =>
                        url_launcher.launchUrl(Uri.parse('https://github.com/aeri/noesys')),
                  ),
                ],
              ),
            ]),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("About"),
        backgroundColor: Colors.black,
      ),
      body: makeBody,
    );
  }
}

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

import 'dart:ui' show Color;
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:flutter/widgets.dart' show Icon;
import 'package:noesys/screens/status_codes.dart';

class Server {
  Server(this.name, this.nameRaw, this.url, this.country,
      [this.statusCode = 0, this.responseTime = 0, this.notify, this.notifyOn]);

  String name;
  String nameRaw;
  String url;
  String country;

  int up;
  int down;

  int statusCode;
  int responseTime;
  bool notify = true;
  Map notifyOn = {
    "OK": false,
    "4xx": true,
    "5xx": true,
    "0": true,
  };

  Server.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        nameRaw = json['nameRaw'],
        url = json['url'],
        country = json['country'],
        notify = json['notify'],
        notifyOn = json['notifyOn'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'nameRaw': nameRaw,
        'url': url,
        'country': country,
        'notify': notify,
        'notifyOn': notifyOn
      };

  Icon getStatusIcon() {
    return (statusCode == 0 || statusCode >= 400 && statusCode < 600)
        ? Icon(Icons.cancel, color: Color.fromRGBO(232, 53, 83, 1.0))
        : Icon(Icons.check_circle, color: Colors.green[400]);
  }

  int getResponseTime() {
    return responseTime;
  }

  double getUptime() {
    return 1.0;
  }

  String getStatusCode() {
    return getPhrase(statusCode);
  }

  String getUrl() {
    return url;
  }

  Color getStatusColor() {
    if (statusCode <= 0)
      return Colors.grey[400];
    else if (statusCode >= 400 && statusCode < 500)
      return Colors.amberAccent;
    else if (statusCode >= 500 && statusCode < 600)
      return Color.fromRGBO(232, 53, 83, 1.0); // #E83553
    else if (statusCode >= 200 && statusCode < 300)
      return Colors.green;
    else
      return Colors.cyan;
  }

  @override
  String toString() {
    return "$name: ${statusCode.toString()}";
  }
}

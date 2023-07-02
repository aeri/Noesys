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
import 'package:json_annotation/json_annotation.dart';

part 'server.g.dart';

@JsonSerializable()
class Server {
  Server(this.name, this.nameRaw, this.url, this.topic,
      [this.statusCode = 0,
      this.responseTime = 0,
      this.notify = true,
      this.notifyIn,
      this.enabled = true]);

  String name;
  String nameRaw;
  String url;
  String topic;

  int up = -1;
  int down = -1;

  DateTime? acknowledgedOn;
  DateTime? notifiedOn;

  int statusCode = -1;
  int responseTime = 0;
  bool notify;
  bool enabled = true;
  Map? notifyIn = {
    "OK": false,
    "4xx": true,
    "5xx": true,
    "0": true,
  };

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$ServerToJson(this);

  Icon getStatusIcon() {
    if (enabled) {
      if (statusCode == -1) {
        return Icon(Icons.timelapse, color: Colors.grey);
      }
      if (statusCode == 0) {
        return Icon(Icons.timer_off, color: Colors.red);
      } else if (statusCode >= 500 && statusCode < 600) {
        return Icon(Icons.cancel, color: Color.fromRGBO(232, 53, 83, 1.0));
      } else if (statusCode >= 400 && statusCode < 500) {
        return Icon(Icons.cancel, color: Colors.amberAccent);
      } else {
        return Icon(Icons.check_circle, color: Colors.green[400]);
      }
    } else {
      return Icon(Icons.stop_circle, color: Colors.grey[400]);
    }
  }

  int getResponseTime() {
    return responseTime;
  }

  double? getUptime() {
    if (this.enabled) {
      return null;
    } else {
      return 0.0;
    }
  }

  String getStatusCode() {
    return getPhrase(statusCode, enabled);
  }

  String getUrl() {
    return url;
  }

  Color? getStatusColor() {
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

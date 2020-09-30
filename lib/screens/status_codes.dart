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

import 'dart:convert';
import 'package:flutter/services.dart';

String statusCodes;

class Codes {
  String code;
  String phrase;

  Codes(this.code, this.phrase);

  factory Codes.fromJson(dynamic json) {
    return Codes(json['code'] as String, json['phrase'] as String);
  }

  @override
  String toString() {
    return '{ ${this.code}, ${this.phrase} }';
  }
}

void loadData() async {
  statusCodes = await rootBundle.loadString('assets/status-codes.json');
}

String getPhrase(int code) {
  if (code == 0) {
    return "TIMEOUT";
  } else {
    var codeList = jsonDecode(statusCodes) as List;
    List<Codes> codes =
        codeList.map((tagJson) => Codes.fromJson(tagJson)).toList();

    Codes findCodeName(String id) =>
        codes.firstWhere((book) => book.code == id);

    Codes codeName = findCodeName(code.toString());

    return codeName.phrase;
  }
}

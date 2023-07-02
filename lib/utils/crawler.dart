import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:dio/io.dart';
import 'package:noesys/models/server.dart';
import 'package:dio/dio.dart';
import 'package:noesys/utils/sharedPref.dart';

import 'notify.dart';

bool shouldNotify(Server server) {
  if (server.notify && server.notifyIn != null) {
    if (server.notifiedOn == null) {
      return true;
    } else {
      /*
      if (server.notifiedOn!
          .add(const Duration(minutes: 1))
          .isBefore(DateTime.now())) {
        return true;
      } else {
        return false;
      }

       */
      return false;
    }
  } else {
    return false;
  }
}

Future<bool> checkNotifications(Server server, int code) async {
  if (shouldNotify(server)) {
    if (server.notifyIn!["4xx"] && code >= 400 && code < 500) {
      await showNotification(server.nameRaw, "4xx", "${server.name} is DOWN!",
          "$code detected in ${server.name}");
      return true;
    } else if (server.notifyIn!["5xx"] && code >= 500 && code < 600) {
      server.notifiedOn = DateTime.now();
      server.acknowledgedOn = null;
      await showNotification(server.nameRaw, "5xx", "${server.name} is DOWN",
          "$code detected in ${server.name}");
      return true;
    } else if (server.notifyIn!["0"] && code == 0) {
      print("TIMEOUT" + ":" + server.url);
      server.notifiedOn = DateTime.now();
      server.acknowledgedOn = null;
      await showNotification(server.nameRaw, "Timeout",
          "${server.name} is down!", "Timeout detected in: " + server.name);
      return true;
    } else if (server.notifyIn!["OK"] && code >= 200 && code <= 300) {
      server.notifiedOn = DateTime.now();
      server.acknowledgedOn = null;
      await showNotification(server.nameRaw, "Online",
          "${server.name} is operational", "Server ${server.name} is UP");
      return true;
    } else {
      print("UP: " + server.url);
      return false;
    }
  }
  return false;
}

Future<Server> refreshDataServer(Server server) async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    return server;
  }

  return await _checkServer(server);
}

Future<List<Server>> refreshDataServers(List<Server> servers) async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    return servers;
  }

  List<Server> teasedList =
      await Future.wait(servers.map((server) => _checkServer(server)));

  return teasedList;
}

Future<Server> _checkServer(Server server) async {
  if (server.enabled) {
    print("TEASING: " + server.url);

    int code, time;

    var dio = Dio();
    dio.options.connectTimeout = Duration(milliseconds: 8000);
    dio.options.receiveTimeout = Duration(milliseconds: 8000);

    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    //dio.options.maxRedirects = 10;
    final stopwatch = Stopwatch()..start();

    try {
      //404
      Response response = await dio.get(server.url);
      Stopwatch()..stop();

      code = response.statusCode ?? 0;
      //up = up + 1;

      time = stopwatch.elapsedMilliseconds;
    } on DioError catch (e) {
      Stopwatch()..stop();

      //down = down + 1;

      time = stopwatch.elapsedMilliseconds;

      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        code = e.response!.statusCode ?? 0;
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        code = 0;
        time = 0;
      }
    }

    var notified = await checkNotifications(server, code);

    if (notified) {
      server.notifiedOn = DateTime.now();
      server.acknowledgedOn = null;
      SharedPref.updateServer(server.nameRaw, server);
    }

    server.statusCode = code;
    server.responseTime = time;
  }
  return server;
}

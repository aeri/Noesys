import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:dio/io.dart';
import 'package:noesys/models/server.dart';
import 'package:dio/dio.dart';
import 'package:noesys/utils/sharedPref.dart';
import 'dart:convert';

List<Server> _servers = <Server>[];
SharedPref sharedPref = SharedPref();

bool existServer(String nameRaw) {
  bool exists = _servers.any((server) => server.nameRaw.contains(nameRaw));
  return exists;
}

void updateServer(String nameRaw, Server updateServer) {
  _servers[_servers.indexWhere((server) => server.nameRaw == nameRaw)] =
      updateServer;

  writeServers(_servers);
}

List<Server> getServers() {
  return _servers;
}

void loadServerList() async {
  try {
    Iterable l = json.decode(await sharedPref.read("servers"));

    List<Server> itemsList =
        List<Server>.from(l.map((i) => Server.fromJson(i)));

    _servers = itemsList;
  } catch (exception) {
    print("NO DATA");
  }
}

void writeServer(Server newServer) {
  _servers.add(newServer);

  sharedPref.save("servers", jsonEncode(_servers));
}

void writeServers(List<Server> serverList) {
  sharedPref.save("servers", jsonEncode(serverList));
}

void deleteServer(String oldServer) {
  _servers.removeWhere((item) => item.nameRaw == oldServer);
  sharedPref.save("servers", jsonEncode(_servers));
}

Future<Server> refreshDataServer(String nameRaw) async {
  var serverFiltered =
      _servers.where((server) => server.nameRaw.contains(nameRaw));
  if (serverFiltered.length > 0) {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return serverFiltered.first;
    }

    return await _refreshServer(serverFiltered.first);
  } else {
    throw new Exception("Server name not found");
  }
}

Future<List<Server>> refreshDataServers() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none) {
    return _servers;
  }

  List<Server> servers =
      await Future.wait(_servers.map((server) => _refreshServer(server)));

  return servers;
}

Future<Server> _refreshServer(Server server) async {
  print("CHECK: " + server.url);

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

  return Server(server.name, server.nameRaw, server.url, server.country, code,
      time, server.notify, server.notifyOn);
}

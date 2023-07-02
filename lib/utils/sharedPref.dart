import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/server.dart';

class SharedPref {
  static late final SharedPreferences instance;

  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  static String? read(String key) {
    //instance.reload();
    return instance.getString(key);
  }

  static Future<String?> reload(String key) async {
    await instance.reload();
    return instance.getString(key);
  }

  static Future<void> save(String key, String value) async {
    await instance.setString(key, value);
  }

  static Future<void> _remove(String key) async {
    await instance.remove(key);
  }

  static Future<List<Server>> reloadServerList()  async {
    try {
      var serverList = await reload("servers");

      print("loadServerList: $serverList");

      if (serverList != null) {
        Iterable l = json.decode(serverList);
        List<Server> itemsList =
        List<Server>.from(l.map((i) => Server.fromJson(i)));

        return itemsList;
      } else {
        return [];
      }
    } catch (exception) {
      print("NO DATA");
      return [];
    }
  }

  static List<Server> loadServerList()  {
    try {
      var serverList = read("servers");

      print("loadServerList: $serverList");

      if (serverList != null) {
        Iterable l = json.decode(serverList);
        List<Server> itemsList =
            List<Server>.from(l.map((i) => Server.fromJson(i)));

        return itemsList;
      } else {
        return [];
      }
    } catch (exception) {
      print("NO DATA");
      return [];
    }
  }

  static bool existServer(String nameRaw) {
    print("existServer: $nameRaw");
    var _servers = loadServerList();
    bool exists = _servers.any((server) => server.nameRaw.contains(nameRaw));
    return exists;
  }

  static Server? getServer(String nameRaw) {
    print("getServer: $nameRaw");
    var _servers = loadServerList();
    return _servers.where((server) => server.nameRaw.contains(nameRaw)).first;
  }

  static Future<void> updateServer(String nameRaw, Server updateServer) async {
    print("updateServer: $nameRaw");
    var _servers = loadServerList();

    _servers[_servers.indexWhere((server) => server.nameRaw == nameRaw)] =
        updateServer;

    await writeServers(_servers);
  }

  static Future<void> addServer(Server newServer) async {
    print("addServer: ${newServer.name}");
    var _servers = loadServerList();

    _servers.add(newServer);

    await save("servers", jsonEncode(_servers));
  }

  static Future<void> writeServers(List<Server> serverList) async {
    print("writeServers: $serverList");
    await save("servers", jsonEncode(serverList));
  }

  static Future<void> deleteServer(String oldServer) async {
    print("deleteServer: $oldServer");
    var _servers = loadServerList();
    _servers.removeWhere((item) => item.nameRaw == oldServer);
    await save("servers", jsonEncode(_servers));
  }
}

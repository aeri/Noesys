
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> startNotifications(Future<void> Function(String? payload) onSelectNotification) async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_noesys');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }


  showNotification(String nameRaw, String channel, String title, String message) async {
    AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(channel, 'Server status',
        channelDescription: 'Notify about server status responses',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Noesys notification');
    NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(0, title, message, notificationDetails, payload: nameRaw);
  }


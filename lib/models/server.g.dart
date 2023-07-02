// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Server _$ServerFromJson(Map<String, dynamic> json) => Server(
      json['name'] as String,
      json['nameRaw'] as String,
      json['url'] as String,
      json['topic'] as String,
      json['statusCode'] as int? ?? 0,
      json['responseTime'] as int? ?? 0,
      json['notify'] as bool? ?? true,
      json['notifyIn'] as Map<String, dynamic>?,
      json['enabled'] as bool? ?? true,
    )
      ..up = json['up'] as int
      ..down = json['down'] as int
      ..acknowledgedOn = json['acknowledgedOn'] == null
          ? null
          : DateTime.parse(json['acknowledgedOn'] as String)
      ..notifiedOn = json['notifiedOn'] == null
          ? null
          : DateTime.parse(json['notifiedOn'] as String);

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
      'name': instance.name,
      'nameRaw': instance.nameRaw,
      'url': instance.url,
      'topic': instance.topic,
      'up': instance.up,
      'down': instance.down,
      'acknowledgedOn': instance.acknowledgedOn?.toIso8601String(),
      'notifiedOn': instance.notifiedOn?.toIso8601String(),
      'statusCode': instance.statusCode,
      'responseTime': instance.responseTime,
      'notify': instance.notify,
      'enabled': instance.enabled,
      'notifyIn': instance.notifyIn,
    };

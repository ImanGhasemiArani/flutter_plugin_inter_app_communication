import 'dart:async';

import 'package:uuid/uuid.dart';

import 'inter_app_communication_platform_interface.dart';

class InterAppCommunication {
  static final InterAppCommunication _instance =
      InterAppCommunication._internal();

  InterAppCommunication._internal() {
    _onDataReceived;
  }

  factory InterAppCommunication() => _instance;

  final InterAppCommunicationPlatform _platform =
      InterAppCommunicationPlatform.instance;

  final _streamController =
      StreamController<InterAppCommunicationEvent>.broadcast();

  Stream<InterAppCommunicationEvent> get onDataReceived =>
      _streamController.stream;

  StreamSubscription<InterAppCommunicationEvent?> get _onDataReceived =>
      _platform.onDataReceived.map(_parseEvent).listen((event) {
        if (event != null) {
          _streamController.add(event);
        }
      });

  Future<dynamic> sendDataToApp(InterAppCommunicationEvent event) async {
    send() => _platform.sendDataToApp(
          event.packageId,
          event.senderPackageId,
          event.type.name,
          event.id,
          event.data,
        );

    if (event is InterAppCommunicationRequestEvent) {
      final res = send();
      if (event.isResponseRequired) {
        return _waitForResponse(event.id)
            .timeout(Duration(milliseconds: event.timeout));
      }
      return res;
    }
    return send();
  }

  Future<InterAppCommunicationResponseEvent?> _waitForResponse(
      String? id) async {
    await for (final event in onDataReceived) {
      if (event is InterAppCommunicationResponseEvent && event.id == id) {
        return event;
      }
    }
    return null;
  }
}

sealed class InterAppCommunicationEvent {
  final String packageId;
  final String? senderPackageId;
  final EventType type;
  final String? id;
  final Map<String, dynamic> data;

  InterAppCommunicationEvent({
    required this.packageId,
    this.senderPackageId,
    required this.type,
    required this.id,
    required this.data,
  });

  @override
  String toString() =>
      '$runtimeType = packageId: $packageId, senderPackageId: $senderPackageId, type: $type, id: $id, data: $data';
}

class InterAppCommunicationRequestEvent extends InterAppCommunicationEvent {
  final bool isResponseRequired;
  final int timeout;

  InterAppCommunicationRequestEvent({
    required super.packageId,
    super.senderPackageId,
    required super.data,
    String? id,
    this.isResponseRequired = true,
    this.timeout = 15000,
  }) : super(
          type: EventType.request,
          id: id ?? const Uuid().v4(),
        );

  @override
  String toString() =>
      '${super.toString()}, isResponseRequired: $isResponseRequired, timeout: $timeout';
}

class InterAppCommunicationResponseEvent extends InterAppCommunicationEvent {
  InterAppCommunicationResponseEvent({
    required super.packageId,
    super.senderPackageId,
    super.id,
    required super.data,
  }) : super(type: EventType.response);
}

enum EventType {
  request,
  response,
  custom;

  static EventType fromName(String name) => values
      .firstWhere((element) => element.name == name, orElse: () => custom);
}

InterAppCommunicationEvent? _parseEvent(dynamic event) {
  if (event is Map) {
    final map = event.map((key, value) {
      if (key is String) {
        return MapEntry(key, value);
      }
      return MapEntry(key.toString(), value);
    });

    final packageId = map['packageId'] as String;
    final sPackageId = map['senderPackageId'] as String;
    final type = EventType.fromName(map['type'] as String);
    final id = map['id'] as String;
    final data = (map['data'] as Map<Object?, Object?>).map((key, value) =>
        MapEntry(key.toString(), value) as MapEntry<String, dynamic>);

    if (type == EventType.request) {
      return InterAppCommunicationRequestEvent(
        packageId: packageId,
        senderPackageId: sPackageId,
        id: id,
        data: data,
      );
    }

    return InterAppCommunicationResponseEvent(
      packageId: packageId,
      senderPackageId: sPackageId,
      id: id,
      data: data,
    );
  }

  return null;
}

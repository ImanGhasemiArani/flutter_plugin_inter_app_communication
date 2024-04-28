import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'inter_app_communication_platform_interface.dart';

/// An implementation of [InterAppCommunicationPlatform] that uses method channels.
class MethodChannelInterAppCommunication extends InterAppCommunicationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('inter_app_communication');

  /// The event channel used to receive data from the native platform.
  @visibleForTesting
  final eventChannel = const EventChannel('inter_app_communication.event');

  @override
  Stream<dynamic> get onDataReceived => eventChannel.receiveBroadcastStream();

  @override
  Future<dynamic> sendDataToApp(
    String packageId,
    String? senderPackageId,
    String type,
    String? id,
    Map<String, dynamic> data,
  ) async =>
      methodChannel.invokeMethod('sendDataToApp', {
        'packageId': packageId,
        'senderPackageId': senderPackageId,
        'type': type,
        'id': id,
        'data': data,
      });
}

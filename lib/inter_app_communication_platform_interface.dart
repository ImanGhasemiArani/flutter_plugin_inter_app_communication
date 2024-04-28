import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'inter_app_communication_method_channel.dart';

abstract class InterAppCommunicationPlatform extends PlatformInterface {
  /// Constructs a InterAppCommunicationPlatform.
  InterAppCommunicationPlatform() : super(token: _token);

  static final Object _token = Object();

  static InterAppCommunicationPlatform _instance =
      MethodChannelInterAppCommunication();

  /// The default instance of [InterAppCommunicationPlatform] to use.
  ///
  /// Defaults to [MethodChannelInterAppCommunication].
  static InterAppCommunicationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InterAppCommunicationPlatform] when
  /// they register themselves.
  static set instance(InterAppCommunicationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<dynamic> get onDataReceived;

  Future<dynamic> sendDataToApp(
    String packageId,
    String? senderPackageId,
    String type,
    String? id,
    Map<String, dynamic> data,
  ) {
    throw UnimplementedError('sendDataToApp() has not been implemented.');
  }
}

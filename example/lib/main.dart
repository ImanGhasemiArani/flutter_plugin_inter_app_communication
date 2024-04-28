import 'package:flutter/material.dart';

import 'package:inter_app_communication/inter_app_communication.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    InterAppCommunication().onDataReceived.listen((event) {
      // print('#' * 10);
      // print('Received event in example: $event');
      if (event is InterAppCommunicationRequestEvent) {
        InterAppCommunication().sendDataToApp(
          InterAppCommunicationResponseEvent(
            packageId: event.senderPackageId!,
            id: event.id,
            data: {
              'response':
                  'Received request successfully from ${event.packageId}',
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final response = await InterAppCommunication().sendDataToApp(
                InterAppCommunicationRequestEvent(
                  packageId: 'com.example.test_inter_com',
                  data: {
                    'name': 'ImanGhasemiArani',
                  },
                ),
              );
              print(
                  'ghasemiarani.iman.inter_app_communication_example response = $response');
            },
            child: const Text('Send data to other app'),
          ),
        ),
      ),
    );
  }
}

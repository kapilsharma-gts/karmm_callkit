// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:karmm_callkit/karmm_callkit.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_intent/receive_intent.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initCallPushListeners();
  _isAndroidPermissionGranted();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {

@override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: ElevatedButton(
                        onPressed: startService, child: Text("Start Service"))),
                SizedBox(
                  width: 10,
                ),
                Center(
                    child: ElevatedButton(
                        onPressed: stopService, child: Text("Stop Service"))),
                SizedBox(
                  width: 10,
                ),
                Center(
                    child: ElevatedButton(
                        onPressed: callInitiate, child: Text("init call")))
              ],
            )
          ],
        ),
      ),
    );
  }

  void callInitiate() {
    checkFullScreenIntentPermission();
    showToast("Call initiated");
    Future.delayed(Duration(seconds: 3), () {
      initCallPush();
    });
  }
}

void startService() async {
  await initializeService();
}

void stopService() {
  service.invoke("stopService");
}

void initCallPushListeners() {
  ConnectycubeFlutterCallKit.setOnLockScreenVisibility(isVisible: true);
  ConnectycubeFlutterCallKit.onCallMuted = onCallMuted;
  ConnectycubeFlutterCallKit.instance.init(
    onCallAccepted: _onCallAccepted,
    onCallRejected: _onCallRejected,
    onCallIncoming: _onCallIncoming,
  );
}

// https://github.com/flutter/flutter/blob/master/docs/platforms/android/Upgrading-pre-1.12-Android-projects.md

void initCallPush() {
  ConnectycubeFlutterCallKit.getLastCallId().then((value) {
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: value);
  });

  var sessionId = DateTime.now().microsecondsSinceEpoch.toString();
  CallEvent callEvent = CallEvent(
      sessionId: sessionId,
      callType: 0,
      callerId: randomIds(),
      callerName: randomString(5),
      opponentsIds: {randomIds(), randomIds()},
      callPhoto: 'https://i.imgur.com/KwrDil8b.jpg',
      userInfo: {'user_id': '${randomIds()}'});
  ConnectycubeFlutterCallKit.showCallNotification(callEvent);
}

Future<void> _onCallAccepted(CallEvent callEvent) async {
  // the call was accepted
  showToast("Call accepted");
  print("Call accepted");
  ConnectycubeFlutterCallKit.reportCallAccepted(sessionId: callEvent.sessionId);
}

Future<void> _onCallRejected(CallEvent callEvent) async {
  // the call was rejected
  print("Call rejected");
  showToast("Call rejected");
  ConnectycubeFlutterCallKit.reportCallEnded(sessionId: callEvent.sessionId);
}

Future<void> _onCallIncoming(CallEvent callEvent) async {
  // the Incoming call screen/notification was shown for user
  showToast("Incoming call");
  print("Incoming call");
}

Future<void> onCallMuted(bool mute, String uuid) async {
  // [mute] - `true` - the call was muted on the CallKit screen, `false` - the call was unmuted
  // [uuid] - the id of the muted/unmuted call
  showToast("Call muted: $mute");
  print("Call muted: $mute");
  ConnectycubeFlutterCallKit.reportCallEnded(sessionId: uuid);
}

void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);
}

int randomIds() {
  var rng = new Random();
  var randomNumber = rng.nextInt(100000) + 1;
  return randomNumber;
}

// genrate randomstring function
String randomString(int length) {
  var rng = new Random();
  var codeUnits =
      List.generate(length, (index) => rng.nextInt(33) + 89); // 33 to 122
  return String.fromCharCodes(codeUnits);
}

void checkFullScreenIntentPermission() async {
  var canUseFullScreenIntent =
      await ConnectycubeFlutterCallKit.canUseFullScreenIntent();
  print("boolValue: $canUseFullScreenIntent");
  if (canUseFullScreenIntent == false) {
    ConnectycubeFlutterCallKit.provideFullScreenIntentAccess();
  }
}

// this will be used as notification channel id
const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;
final service = FlutterBackgroundService();
Future<void> initializeService() async {
  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  /// OPTIONAL when use custom notification

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Future<void> _onCallAccepted(CallEvent callEvent) async {
    // the call was accepted
    showToast("Call accepted");
    print("Call accepted");
    flutterLocalNotificationsPlugin.show(
        1002,
        "Call Push",
        "Call Accepted",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'my_foreground',
            'PUSH CALL',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ));
    ConnectycubeFlutterCallKit.reportCallAccepted(
        sessionId: callEvent.sessionId);
  }

  Future<void> _onCallRejected(CallEvent callEvent) async {
    // the call was rejected
    flutterLocalNotificationsPlugin.show(
        1002,
        "Call Push",
        "Call Rejected",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'my_foreground',
            'PUSH CALL',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ));
    print("Call rejected");
    showToast("Call rejected");
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: callEvent.sessionId);
  }

  Future<void> _onCallIncoming(CallEvent callEvent) async {
    // the Incoming call screen/notification was shown for user
    showToast("Incoming call");
    print("Incoming call");
  }

  Future<void> onCallMuted(bool mute, String uuid) async {
    // [mute] - `true` - the call was muted on the CallKit screen, `false` - the call was unmuted
    // [uuid] - the id of the muted/unmuted call
    showToast("Call muted: $mute");
    print("Call muted: $mute");
    ConnectycubeFlutterCallKit.reportCallEnded(sessionId: uuid);
  }

  ConnectycubeFlutterCallKit.setOnLockScreenVisibility(isVisible: true);
  ConnectycubeFlutterCallKit.onCallMuted = onCallMuted;
  ConnectycubeFlutterCallKit.instance.init(
    onCallAccepted: _onCallAccepted,
    onCallRejected: _onCallRejected,
    onCallIncoming: _onCallIncoming,
  );

  // bring to foreground
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure() method.
        initCallPush();
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome ${DateTime.now()}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        // if you don't using custom notification, uncomment this
        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    /// you can see this log in logcat
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    // test using external plugin
    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

Future<void> _isAndroidPermissionGranted() async {
  bool canUseFullScreenIntent =  await ConnectycubeFlutterCallKit.canUseFullScreenIntent();
  if(canUseFullScreenIntent == false){
    ConnectycubeFlutterCallKit.provideFullScreenIntentAccess();
  } else{
    bool canDisplayOverOtherApps =  await ConnectycubeFlutterCallKit.canDisplayOverOtherApps();
    if (canDisplayOverOtherApps == false){
      ConnectycubeFlutterCallKit.provideDisplayOverOtherApps();
    }
  }
}


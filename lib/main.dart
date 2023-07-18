import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:background_fetch/background_fetch.dart';
import 'flog.dart';

// for alarm manager
import 'dart:math';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

const String isolateName = 'isolate';
/// A port used to communicate from a background isolate to the UI isolate.
ReceivePort port = ReceivePort();
int runno = 0;
SendPort? uiSendPort;

lg(msg){
print(msg);
flog.lg(msg);
}


@pragma('vm:entry-point')
Future<void> serveAlarm() async {

// final int isolateId = Isolate.current.hashCode;
// print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");

  runno += 1;
  lg("[AlarmManager] serveAlarm (( Fired )) @" + DateTime.now().toIso8601String());
  uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
  uiSendPort?.send(null);
// await flog.lg("~ FAlarm Fired ~ Time: $now ~ IsolateID: test");
}

// [Android-only] This "Headless Task" is run when the Android app is terminated with `enableHeadless: true`
// Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
lg("[BackgroundFetch] Headless event received @" + DateTime.now().toIso8601String());
  schedule_4269_oneshot();

  BackgroundFetch.finish(taskId);
}

Future<void> _runOneShot(int secs) async{
  lg("[AlarmManager] Run One Shot (( Called )) @" + DateTime.now().toIso8601String());
  await AndroidAlarmManager.oneShot(
    // Duration(milliseconds:millis_to_42_or_69 ),
    Duration(seconds:secs ),
    Random().nextInt(pow(2,8) as int),
    serveAlarm,
    alarmClock: true,
    allowWhileIdle: true,
    exact: true,
    wakeup: true,
  );
}

schedule_4269_oneshot(){
  var now = DateTime.now();
  lg("[BackgroundFetch] Scheduling task from Background @ " + now.toIso8601String());
  var now_minutes = now.minute;

  /// 42 - 15 = 27 so 27 < t < 42 calc millis
  /// 69 - 15 = 54 so 54 < t < 9 calc millis
  ///  9 < t < 27 wait for next run
  ///  42 < t < 54 wait for next run
  var secs_to_42_or_69 = 0;

  if (now_minutes > 27 && now_minutes < 42){
    print("calcing millis to 42");
    int mins_to_42 = 42 - now_minutes;
    secs_to_42_or_69 = mins_to_42 * 60 ;
  }
  if (now_minutes > 54){
    print("calcing millis to 69");
    int mins_to_69 = 9 + (60 - now_minutes);
    secs_to_42_or_69 = mins_to_69 * 60 ;
  }
  if (now_minutes < 9){
    print("calcing millis to 69");
    int mins_to_69 = 9 - now_minutes;
    secs_to_42_or_69 = mins_to_69 * 60 ;
  }

  if (secs_to_42_or_69 != 0) {
    print("millis 42 or 69 set task");
    _runOneShot(secs_to_42_or_69);

  }
  else{
    print("skipping 4269 task set @ " + now.toIso8601String());
  }

}

FileOutput flog = FileOutput();
void main() {
  // Enable integration testing with the Flutter Driver extension.
  // See https://flutter.io/testing/ for more info.
  WidgetsFlutterBinding.ensureInitialized();


  runApp(new MyApp());

  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero,()async
    { await   flog.init();
      await initPlatformState();
    });

  }





  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await IsolateNameServer.registerPortWithName(
      port.sendPort,
      isolateName,
    );
    await AndroidAlarmManager.initialize();
    Future<void> _runOneShotCallback() async{
      lg("[AlarmManager] run one shot callback (( Fired )) @" + DateTime.now().toIso8601String());
    }
    port.listen((_) async => await _runOneShotCallback());

    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async {  // <-- Event handler
      // This is the fetch-event callback.
lg("[BackgroundFetch] fetch-event callback ((ran)) @ " + DateTime.now().toIso8601String());
      setState(() {
        _events.insert(0, new DateTime.now());
      });

schedule_4269_oneshot();

      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      lg("[BackgroundFetch] finish task call  @" + DateTime.now().toIso8601String());
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {  // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      flog.lg("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    // Test one shot
    // Future<void> _runOneShot() async{
    //   print("[AlarmManager] Run One Shot (( Called ))");
    //   flog.lg("[AlarmManager] Run One Shot (( Called ))");
    //   await AndroidAlarmManager.oneShot(
    //     // Duration(milliseconds:millis_to_42_or_69 ),
    //     Duration(seconds:12 ),
    //     Random().nextInt(pow(2,8) as int),
    //     serveAlarm,
    //     alarmClock: true,
    //     allowWhileIdle: true,
    //     exact: true,
    //     wakeup: false,
    //   );
    // }
    //
    //
    // _runOneShot();

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
  }
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
            title: const Text('BackgroundFetch Example', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.amberAccent,
            brightness: Brightness.light,
            actions: <Widget>[
              Switch(value: _enabled, onChanged: _onClickEnable),
            ]
        ),
        body: Container(
          color: Colors.black,
          child: new ListView.builder(
              itemCount: _events.length,
              itemBuilder: (BuildContext context, int index) {
                DateTime timestamp = _events[index];
                return InputDecorator(
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 10.0, top: 10.0, bottom: 0.0),
                        labelStyle: TextStyle(color: Colors.amberAccent, fontSize: 20.0),
                        labelText: "[background fetch event]"
                    ),
                    child: new Text(timestamp.toString(), style: TextStyle(color: Colors.white, fontSize: 16.0))
                );
              }
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Row(
                children: <Widget>[
                  ElevatedButton(onPressed: _onClickStatus, child: Text('Status')),
                  Container(child: Text("$_status"), margin: EdgeInsets.only(left: 20.0))
                ]
            )
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

String _timeLeft = '';
int oldNotificationId = 0;
final FlutterLocalNotificationsPlugin flutterNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> _showNotification(String typeMsg) async {
  flutterNotificationsPlugin.cancel(oldNotificationId);
  oldNotificationId = oldNotificationId  + 1;
  const AndroidNotificationDetails notificationDetails =
    AndroidNotificationDetails('pomodoro1', 'pomodoro',
    channelDescription: 'Display time left',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    color: Colors.blue);
  const NotificationDetails details = NotificationDetails(android: notificationDetails);
  await flutterNotificationsPlugin.show (
    oldNotificationId,
    'Pomodoro',
    typeMsg,
    details,
  );
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidInitializationSettings
    );

  await flutterNotificationsPlugin.initialize(initializationSettings);
  runApp(const MyApp());

}

/*@override
Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
  // If user resumed to this app, check permission
  print('changed');
  if(state == AppLifecycleState.paused) {
    //await FlutterOverlayApps.showOverlay(height: 300, width: 400, alignment: OverlayAlignment.center);
  }
}*/

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _running = false;
  Color backColor = Colors.white;
  Color textColor = Colors.black;
  final Queue<Process> _queue = Queue<Process>();
  int _duration = 0;
  int type = 0;
  String speakMsg = '';
  String workMsg = 'Work for 25 minutes';
  String restMsg = 'Rest for 5 minutes';
  String longRestMsg = 'Rest for 30 minutes';
  final oneSec = const Duration(seconds: 1);
  late Timer _timer;
  final FlutterTts tts = FlutterTts();

  _MyHomePageState(){
    tts.setLanguage('en');
    tts.setSpeechRate(0.4);
  }
  Future<void> _updateTimer() async{
    _timer = Timer.periodic(oneSec, (Timer timer) async {
      if(_duration < 0){
        setState(() {
          timer.cancel();
          _continueTimer();
        });
      }else{
        setState(() {
          _timeLeft = Duration(seconds: _duration--).toString().substring(2, 7);
        });
      }
    });
  }

  Future<void> _startTimer() async{

    if(_queue.isEmpty) {
      getQueueItems(_queue);
    }
    Process next = _queue.removeFirst();
    _duration = next.duration;
    type = next.type;
    setMessage();
    _setColours(next.type);
    await _showNotification(setNotificationMsg(type));
    tts.speak(speakMsg);
    await _updateTimer();
  }

  void setMessage() {
    if(type == 1){
      speakMsg = workMsg;
    }else if(type == 2){
      speakMsg = restMsg;
    }else{
      speakMsg = longRestMsg;
    }
  }

  Future<void> _continueTimer() async {
    if(_queue.isNotEmpty) {
      Process next = _queue.removeFirst();
      _duration = next.duration;
      type = next.type;
      setMessage();
      _setColours(next.type);
      tts.speak(speakMsg);
      await _showNotification(setNotificationMsg(type));

      await _updateTimer();
    }else {
      setState(() {
        _timeLeft = "That is it for today!!";
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: backColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Time left : ',
              style: TextStyle(fontSize: 32, color: textColor),
            ),
            Text(
              _timeLeft,
              style: TextStyle(fontSize: 42, color: textColor),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          await _startTimer();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  void _setColours(int type) {
    if (type == 1) {
      textColor = Colors.black;
      backColor = Colors.white;
    } else if (type == 2) {
      textColor = Colors.white;
      backColor = Colors.green;
    } else {
      textColor = Colors.white;
      backColor = Colors.red;
    }
  }

  String setNotificationMsg(int type) {
    if(type == 1){
      return 'Work';
    }else if(type == 2){
      return 'Rest';
    }else{
      return 'Long Rest';
    }
  }
}

class Process{
  int duration;
  int type;
  /*
  Type values
  1 = Work
  2 = Rest
  3 = Long Rest
   */
  Process(this.duration, this.type);
}

Queue<Process> getQueueItems(Queue<Process> processes) {
  const int _restDuration = 5 * 60;
  const int _longRestDuration = 5 * 60;
  const int _workDuration = 25 * 60;
  Process work = Process(_workDuration, 1);
  Process rest = Process(_restDuration, 2);
  Process longRest = Process(_longRestDuration, 3);
  processes.addAll([work, rest, work, rest, work, longRest]);
  return processes;
}

/*
@pragma('vm:entry-point')
void showOverlay(){
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(child: Text("My overlay"))
  ));
}
*/



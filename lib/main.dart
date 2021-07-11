import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'main.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'next.dart';



import 'package:flutter/material.dart';

Timer timer;


class DaterAdapter extends TypeAdapter<Dater> {
  @override
  final typeId = 0;

  @override
  Dater read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dater(
      longg: fields[0] as String,
      latt: fields[1] as String,
      altt: fields[2] as String,
      indexer: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Dater obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.longg)
      ..writeByte(1)
      ..write(obj.latt)
      ..writeByte(2)
      ..write(obj.altt)
      ..writeByte(3)
      ..write(obj.indexer);
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Gathering Data',
    home: TutorialHome(),
  ));
}
class TutorialHome extends StatefulWidget{

  TutorialHomeX createState()=> TutorialHomeX();
}


class TutorialHomeX extends State<TutorialHome> {

  int _integ=0;
  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(Duration(seconds: 1), (Timer t)
    async {
      if (_integ == 0) {
        WidgetsFlutterBinding.ensureInitialized();
        final appDocumentDir = await getApplicationDocumentsDirectory();
        print(appDocumentDir.path);
        Hive
          ..init(appDocumentDir.path)
          ..registerAdapter(DaterAdapter());
        setState(() {
          _integ = _integ + 1;
        });
      }
      else
        {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          print(position.latitude);
          print(position.longitude);

          await updatetable(position.latitude.toString(),position.longitude.toString(),"123",_integ);
          setState(() {
          _integ = _integ + 1;
            });
          print("Done!!");
    }
    }
    );



    // Timer(Duration(microseconds: 1), (){
    //   // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>
    //   //     TutorialHome()));
    //   print("Hi");
    // });

  }
  @override
  void dispose() {
      print("Ok...");
      timer?.cancel();

      super.dispose();

  }


  @override
  Widget build(BuildContext context) {

    // Scaffold is a layout for
    // the major Material Components.

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          tooltip: 'Navigation menu',
          onPressed: null,
        ),
        title: Text('Data Collection'),
        actions: <Widget>[
          // IconButton(
          //   icon: Icon(Icons.search),
          //   tooltip: 'Search',
          //   onPressed: null,
          // ),
        ],
      ),
      // body is the majority of the screen.


      //.............................................................................................................
      // body: Center(
      //   child: RaisedButton(
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      //     child: Text('Test'),
      //     onPressed: () async {
      //       // Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      //       // print(position.latitude);
      //       // print(position.longitude);
      //
      //
      //       // WidgetsFlutterBinding.ensureInitialized();
      //       // final appDocumentDir = await getApplicationDocumentsDirectory();
      //       // print(appDocumentDir.path);
      //       // Hive
      //       //   ..init(appDocumentDir.path)
      //       //   ..registerAdapter(CityWeatherAdapter());
      //     },
      //     elevation: 20.0,
      //   )
      // ),
      //................................................................................
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add', // used by assistive technologies
        child: Icon(Icons.next_plan_outlined),
        onPressed: () async
        {
          Navigator.push(context,MaterialPageRoute(builder: (context)
          {
            return MainForm();
          }
          ));

          // var box = await Hive.openBox('cityNames');
          // for (var i = 0; i < 10; i++) {
          //   CityWeather cityWeather = CityWeather(isFav: 1, cityName: 'SomeName${i}');
          //   box.put('current${i}', cityWeather);
          // }
          // var name = box.get('current2');
          //
          // print('Name: ${name.cityName}');
        },
      ),
    );
  }
}

Future<void> updatetable(String s,String t,String u,int i)
async {
  var box = await Hive.openBox('gpsdat');
  Dater dater = Dater(longg: s, latt: t,altt: u, indexer: i);
  await box.put('gpsdatt${i}', dater);
  print('gpsdat${i}:Done!!!!!!!!!!!!!!!!!!!!!!!!');
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:ext_storage/ext_storage.dart';
import 'dart:convert';
import 'main.g.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as S1;
import 'package:http/http.dart' as http;



class MainForm extends StatefulWidget
{

  @override
  State<StatefulWidget> createState() {
    return _MainFormState();
  }

}


class _MainFormState extends State<MainForm> {


  data_upload(path) async {
    // var bytes=path.readAsBytesSync();
    // var postUri = Uri.http('http://13.229.160.192:5000', '/file-upload');

    var postUri = Uri.parse('http://52.74.221.135:5000/beacon_data');

    http.MultipartRequest request = new http.MultipartRequest("POST", postUri);

    http.MultipartFile multipartFile =
    await http.MultipartFile.fromPath('beaconcsv', path);

    request.files.add(multipartFile);

    http.StreamedResponse response = await request.send();

    print(
        '********************************************************************************************');
    print('Status Code: ');
    print(response.statusCode);
    print(
        '********************************************************************************************');
  }




  void getPermission() async {
    print("getPermission");
    Map<PermissionGroup, PermissionStatus> permissions =
    await PermissionHandler().requestPermissions([PermissionGroup.storage]);
  }

  @override
  void initState() {
    getPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return new WillPopScope(
        onWillPop: () async => false,

        child:Scaffold(
          resizeToAvoidBottomInset: false,
          appBar:AppBar(
            automaticallyImplyLeading: false,
            title:Text('Post Data Collection'),
            actions: [
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.transit_enterexit),
                        title: Text('Convert to CSV'),
                      ),
                      value: "/convertcsv"
                  ),

                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.upload_file),
                        title: Text('Manual Data Upload'),
                      ),
                      value: "/dataupload"
                  ),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.auto_awesome),
                        title: Text('Schedule Upload'),
                      ),
                      value: "/sched"
                  ),
                  const PopupMenuItem(
                      child: ListTile(
                        leading: Icon(Icons.list_alt),
                        title: Text('Get List of Keys'),
                      ),
                      value: "/getty"
                  ),

                ],
                onSelected: (value) async{
                  if (value=='/convertcsv') {
                    var box = await Hive.openBox('gpsdat');
                    var inventoryList = box.keys.toList();
                    print(inventoryList.length);

                    for (var i = 0; i < inventoryList.length; i++) {
                      var name = await box.get(inventoryList[i]);
                      print(
                          "****************************************************");
                      print('Index: ${name.indexer}');
                      print('Longitude: ${name.longg}');
                      print('Latitude: ${name.latt}');
                      print('Altitude: ${name.altt}');

                      final second=await aesencryptor(name.longg.toString());
                      final third=await aesencryptor(name.latt.toString());
                      final fourth=await aesencryptor(name.altt.toString());

                      await csvgenerator(name.indexer, second, third, fourth);
                      print("gpsdat${i}: Done!..........................");
                      print("****************************************************");
                    }
                  }
                  else if(value=='/dataupload')
                    {
                      String path = await ExtStorage
                          .getExternalStoragePublicDirectory(
                          ExtStorage.DIRECTORY_DOWNLOADS);
                      String fullPath = "$path/gps_data9.csv";
                      print("Path:");
                      print(fullPath);
                      data_upload(fullPath);
                    }
                  else if(value=='/getty')
                  {

                    var box = await Hive.openBox('cityNames');
                    var inventoryList = box.keys.toList();
                    print(inventoryList.length);
                  }
                },

              ),
            ],

          ),
          body:Container(
              margin:EdgeInsets.only(left: 5) ,
              child:Column(
                children: <Widget>[


                ],
              )
          ),
        ));
  }
}

Future<int> _readIndicator() async {
  String text;
  int indicator;
  try {
    String path = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
    String fullPath = "$path/gps_data9.csv";
    final File file = File(fullPath);
    text = await file.readAsString();
    // debugPrint("A file has been read at ${directory.path}");
    indicator=1;
  } catch (e) {
    debugPrint("Couldn't read file");
    indicator=0;

  }
  return indicator;
}
void csvgenerator(int first, String second, String third, String fourth) async{
  String dir = await ExtStorage.getExternalStoragePublicDirectory(
      ExtStorage.DIRECTORY_DOWNLOADS);
  print("dir $dir");
  String file = "$dir";


  var f = await File(file + "/gps_data9.csv");
  int dd=await _readIndicator();
  if (dd==1)
  {
    print("**********************************************************");
    print("There is file!");
    print("**********************************************************");
    final csvFile = new File(file + "/gps_data9.csv")
        .openRead();
    var dat = await csvFile
        .transform(utf8.decoder)
        .transform(
      CsvToListConverter(),
    )
        .toList();

    List<List<dynamic>> rows = [];

    List<dynamic> row = [];
    for (int i = 0; i < dat.length; i++) {
      List<dynamic> row = [];
      row.add(dat[i][0]);
      row.add(dat[i][1]);
      row.add(dat[i][2]);
      row.add(dat[i][3]);

      rows.add(row);
    }

    row.add(first.toString());
    row.add(second);
    row.add(third);
    row.add(fourth);

    rows.add(row);


    String csver = const ListToCsvConverter().convert(rows);
    f.writeAsString(csver);
  }
  else {
    List<List<dynamic>> rows = [];

    List<dynamic> row = [];
    row.add("index");
    row.add("longitude");
    row.add("latitude");
    row.add("altitude");


    rows.add(row);
    String csv = const ListToCsvConverter().convert(rows);
    f.writeAsString(csv);
  }
}


Future<String> aesencryptor(String data)
async {
  final key = S1.Key.fromUtf8('my 32 length key................');
  final iv = S1.IV.fromLength(16);
  final encrypter = S1.Encrypter(S1.AES(key));
  final encrypted = encrypter.encrypt(data, iv: iv);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);

  String result=encrypted.base64;
  print(decrypted);
  print(encrypted.base64);
  return result;
}
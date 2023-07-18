import 'dart:io';
import 'package:path_provider/path_provider.dart';


String filePath = "/flog.txt";
class FileOutput  {
  File? file;

  @override
  init() async {
    final directory = await getApplicationDocumentsDirectory();
    print("gadd ~ " + directory.path);
    file = File(directory.path + filePath);
    if (file == null){
      File(directory.path + filePath).createSync();
    }
    file =  File(directory.path + filePath);
  }

  @override
  lg(msg) async {
    if (file != null) {
      await file!.writeAsString("${msg.toString()}\n",
          mode: FileMode.writeOnlyAppend);
    } else{
      print("file for fileoutput log null");
    }
  }
}
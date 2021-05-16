// dl_name Varchar(6) PRIMARY KEY,
//     dl_level Numeric(3) NOT NULL
import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';

class DangerLevel implements DBObject {
  String name;
  int level;


  DangerLevel(this.name, this.level);

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO DangerLevels(dl_name, dl_level) VALUES
                  ('${name}', '${level}')
                  ON CONFLICT DO NOTHING;
    '''.trim()).catchError((e){
      print(decode(e.toString()));
      return e;
    });;
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }


}
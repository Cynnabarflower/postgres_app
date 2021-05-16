import '../game.dart';
import 'DBObject.dart';
import 'Department.dart';
import 'Owl.dart';
import 'Position.dart';
import 'Product.dart';
import 'Race.dart';

class Race implements DBObject{
  String race;


  Race(this.race);

  @override
  Future addToDB({force = false}) {
    return game.connection.query('''
    INSERT INTO Races(r_race) VALUES
                  ('${race}')
    '''.trim()).catchError((e) {
      if (decode(e.toString()).contains("повторяющееся значение ключа")) {
        return null;
      }
      return e;
    });
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }
}
import 'package:flutter/cupertino.dart';
import 'package:postgres_app/DBObject/Items.dart';

import '../game.dart';
import 'DBObject.dart';


class Sale implements DBObject {
  DateTime date;
  int employerID;
  int id;
  List<Items> items = [];

  @override
  Future addToDB({force = false}) {
    if (force) {
      // employer.addToDB();
    }
    return game.connection.query('''
    INSERT INTO Sales(s_date, s_employee, s_id) VALUES
                  ('${date.toIso8601String()}', ${employerID}, ${id})
                  RETURNING s_id;
    '''.trim()).catchError((e) {
      print(decode(e.toString()));
      return e;
    });
  }

  @override
  Future removeFromDB({force = false}) {
    // TODO: implement deleteFromDB
    throw UnimplementedError();
  }

}

class SaleView extends StatelessWidget {
  List<List<String>> items = [];
  int id;
  String name;
  String family;
  DateTime date;

  @override
  Widget build(BuildContext context) {
    var dateString = '${date.month.toString().padLeft(2,'0')}.${date.day.toString().padLeft(2,'0')} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$id $dateString $name $family '),
        ...items.map((e) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Image.asset(e[0], fit: BoxFit.contain,),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: FittedBox(
          fit: BoxFit.fitHeight,
          child: Text("x ${e[1]} = ${e[2]}")),
    )
    ],))
      ]
    );
  }

  SaleView(this.id, this.name, this.family, this.date);
}
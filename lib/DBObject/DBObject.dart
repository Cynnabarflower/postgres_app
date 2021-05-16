
import 'dart:convert';

abstract class DBObject {
  Future addToDB({force = false});
  Future removeFromDB({force = false});

}

String decode(String s) {
  return utf8.decode(latin1.encode(s));
}
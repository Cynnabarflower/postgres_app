import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres_app/DBObject/Employer.dart';
import 'package:postgres_app/DBObject/Product.dart';

import 'DBObject/Department.dart';
import 'game.dart';

class Room extends StatefulWidget {



  int w = 20;
  int h = 10;
  double cellWidth = 10;
  double cellHeight = 10;
  List<Employee> employers = [];
  List<Product> products = [];
  StreamController<Employee> movingEmployers = StreamController.broadcast();
  dynamic candidate = null;
  Function getNewProduct;
  Duration produceDuration = Duration(seconds: 1);
  int index = -1;
  Widget name;
  Department department;

  void addEmptyProduct() {
    var prod = getNewProduct()
      ..price = null
      ..assetName = null;
    products.add(prod);
  }

  @override
  State createState() => _RoomState();

  @override
  Widget information({tag = 0}) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool loading = false;
        return AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.only(top: 8),
          content: Hero(
            tag: tag,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 1.1,
              height: MediaQuery.of(context).size.width / 1.1 * 2,
              child: Material(
                elevation: 20,
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    color: Colors.brown[500],
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ClipRRect(
                              clipBehavior: Clip.antiAlias,
                              child: Align(
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      height: 50,
                                      child: FittedBox(child: name,),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: loading ?
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width / 1.1 / 2,
                                          height: MediaQuery.of(context).size.width / 1.1 / 2,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ) :
                                        ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: employers.map(
                                                  (e) => Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: SizedBox(
                                                        width: 200,
                                                        child: Container(
                                                            color: Colors.brown[300],
                                                            child: Column(
                                                              children: [
                                                                Expanded(child: e.informationData(setParentState: setState)),
                                                                MaterialButton(onPressed: () {
                                                                  loading = true;
                                                                  setState((){});
                                                                  e.addToDB(replace: true).then((value) {
                                                                    loading = false;
                                                                    setState((){});
                                                                  });
                                                                },
                                                                child: Container(
                                                                  height: 30,
                                                                  alignment: Alignment.center,
                                                                  color: Colors.green[400],
                                                                  child: Text('Save changes'),
                                                                ),
                                                                )
                                                              ],
                                                            ))),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AspectRatio(
                            aspectRatio: 4 / 1,
                            child: ClipRRect(
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context,
                                        rootNavigator: true)
                                        .pop();
                                  },
                                  child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.brown[700],
                                        borderRadius: BorderRadius.only(
                                            bottomLeft:
                                            Radius.circular(16.0),
                                            bottomRight:
                                            Radius.circular(16.0)),
                                      ),
//                              child: Icon(Icons.check_circle_outline, color: Colors.amberAccent, size: 56,),
                                      child: Icon(Icons.check_circle, color: Colors.white54,)),
                                ),
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

  }

  void startWork(Employee e) async {
    Future work() async {
      e.tweenKey = GlobalKey();
      int x = Random().nextInt(w-2)+1;
      int y = Random().nextInt(h-2)+1;
      e.movingTo = Offset(x * cellWidth, y * cellHeight);
      print('walking to $x $y  (${e.offset}->${e.movingTo})');
      var f = movingEmployers.stream.asBroadcastStream().timeout(Duration(seconds: 10)).firstWhere((el) => el == e);
      if ((e.key as GlobalKey)?.currentState?.mounted ?? false)
        (key as GlobalKey)?.currentState?.setState(() {});
      await f;
      if ((e.key as GlobalKey)?.currentState?.mounted ?? false) {
        (e.key as GlobalKey)?.currentState?.setState(() {});
      }
      // print('done');
    }

    print('start working ${e.name} ${(game.key as GlobalKey).currentState?.mounted} ${e.room}');
    while (((game.key as GlobalKey)?.currentState?.mounted ?? false) && e.room != null && e.room.employers.contains(e)) {
      await work();
      await Future.delayed(Duration(seconds: 3 + Random().nextInt(5)));
    }
  }

  void addEmployer(Employee e) {
    e.room = this;
    employers.add(e);
    int x = Random().nextInt(w-2)+1;
    int y = Random().nextInt(h-2)+1;
    e.offset ??= Offset(x * cellWidth, y * cellHeight);
    startWork(e);
    (key as GlobalKey).currentState?.setState(() {});
  }

  Room(this.getNewProduct, {this.produceDuration, this.department}) : super(key: GlobalKey()) {
    department.room = this;
  }
}

class _RoomState extends State<Room> {


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => widget.information(),
            );
          },
          child: Container(
            alignment: Alignment.center,
            child: Stack(
              children: [
                AspectRatio(
                    aspectRatio: 1/0.4,
                    child: Image.asset("assets/images/roomFrame.png", fit: BoxFit.fill,)),
                AspectRatio(
                  aspectRatio: 1/0.4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      var padding = 11/900 * constraints.maxWidth;
                      var cellWidth = (constraints.maxWidth - 2 * padding) / widget.w;
                      var cellHeight = (constraints.maxHeight - 2 * padding) / widget.h;
                      widget.cellWidth = cellWidth;
                      widget.cellHeight = cellHeight;
                      // cellHeight = min(cellHeight, cellWidth);
                      // cellWidth = min(cellHeight, cellWidth);
                      // print('room employers: ${widget.employers}');

                      return Padding(
                        padding: EdgeInsets.all(padding),
                        child: SizedBox(
                          width: cellWidth * widget.w,
                          height:  cellHeight * widget.h,
                          child: Stack(
                            children: [
                            Image.asset("assets/images/roomBack.png", fit: BoxFit.fill, width: cellWidth * widget.w, height: cellHeight * widget.h,),
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                    width: constraints.maxWidth / 2,
                                    height: constraints.maxHeight / 2,
                                    child: Opacity(
                                        opacity: 0.3,
                                        child: widget.name)),
                              ),
                              ...List.generate(widget.w * widget.h, (index) {
                                // var cellWidth = constraints.maxWidth / widget.w;
                                // var cellHeight = constraints.maxHeight / widget.h;
                                // cellHeight = min(cellHeight, cellWidth);
                                // cellWidth = min(cellHeight, cellWidth);
                                var dx = (index - ((index / widget.w).floorToDouble()) * widget.w) * cellWidth;
                                var dy = (index / widget.w).floorToDouble() * cellHeight;
                                return Positioned(
                                  top: dy,
                                  left: dx,
                                  child: DragTarget(
                                    onWillAccept: (data) { widget.candidate = data; return true;},
                                    onLeave: (data) {if (data == widget.candidate) widget.candidate = null;},
                                    onAccept: (data) async {
                                      game.chooser.remove(data);
                                      game.chooser.update();
                                      var e = data as Employee;
                                      e.room = widget;
                                      game.money -= e.hirePrice;
                                      // if (widget.employers.isNotEmpty)
                                      //   e.directorId = widget.employers.fold(999999, (p, el) => min(p, el.id));
                                      e.department = widget.department;
                                      widget.employers.add(data);
                                      e.addToDB();
                                      e.offset = Offset(dx, dy);
                                      widget.startWork(e);
                                    },
                                    builder: (context, candidateData, rejectedData) =>
                                    Container(
                                      width: cellWidth-1,
                                      height: cellHeight-1,
                                    ),
                                  ),
                                );
                              }),
                      ...widget.employers.map(
                      (e) {
                        e.movingTo ??= e.offset;
                        return  TweenAnimationBuilder(
                        key: e.tweenKey,
                        duration: () {
                          return Duration(milliseconds: (30*sqrt((e.offset.dx - e.movingTo.dx)*(e.offset.dx - e.movingTo.dx)+(e.offset.dy - e.movingTo.dy)*(e.offset.dy - e.movingTo.dy)) ).floor());
                        }(),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Positioned(
                              top: e.offset.dy + (e.movingTo.dy - e.offset.dy) * value,
                              left: e.offset.dx + (e.movingTo.dx - e.offset.dx) * value,
                              child: Container(child: child));
                        },
                        child: e,
                        onEnd: () {
                          e.offset = e.movingTo;
                          widget.movingEmployers.add(e);
                          },
                      );},
                      ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        );
      },);
  }


  void produce() async {
    print('prod start');
    while ((game.key as GlobalKey)?.currentState?.mounted ?? false) {
      // print('prod');
      if (widget.products.length < 5) {
        if (widget.employers.length > 0) {
          var prod = (widget.getNewProduct() as Product);
          while (prod.price == null) {
            await Future.delayed(Duration(milliseconds: 300));
          }

          print('New room product $prod');
          // prod.addToDB();
          widget.products.add(prod);
          game.money -= widget.employers.fold(0.0, (p, e) => p+(e.salary ?? 0.0)).floor();
          game.producedProducts.add(widget.index);
        }
      } else {
        game.money -= (widget.employers.fold(0.0, (p, e) => p+(e.salary ?? 0.0)) / 10.0).floor();
        game.producedProducts.add(-1);
      }
      await Future.delayed(Duration(milliseconds: max(500, widget.produceDuration.inMilliseconds - widget.employers.length * 100)));
    }
  }

  @override
  void initState() {
    widget.index = game.rooms.indexOf(widget);
    var name = "";
    var asset = "";
    if (widget.index == 0) {
      // name = "Potionary";
      asset = "assets/images/Potion/Icon1.png";
    } else if (widget.index == 1) {
      // name = "Kitchen";
      asset = "assets/images/Food/Apple.png";
    } else if (widget.index == 2) {
      // name = "Smithy";
      asset = "assets/images/Weapon/GoldenSword.png";
    } else if (widget.index == 3) {
      // name = "Library";
      asset = "assets/images/Book/Book.png";
    }
    name = widget.department?.name ?? "Unrecognized room";

    widget.name = FittedBox(
      fit: BoxFit.cover,
      child: Row(
        children: [
          Image.asset(asset, fit: BoxFit.cover,),
          Text(name, style: TextStyle(
              color: Colors.white
          ),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      produce();
    });

    super.initState();

  }
}
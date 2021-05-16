
import 'dart:math';

import 'package:flame/anchor.dart';
import 'package:flame/spritesheet.dart';
import 'package:flame/widgets/animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flame/animation.dart' as ani;
import 'package:postgres_app/DBObject/Items.dart';
import 'package:postgres_app/DBObject/Manufacturer.dart';
import 'package:postgres_app/DBObject/Product.dart';
import 'package:postgres_app/DBObject/Sale.dart';
import 'package:postgres_app/slide_fade_transition.dart';

import 'game.dart';

class Creature extends StatefulWidget {
  ani.Animation _walkAnimation;
  ani.Animation _idleAnimation;
  ani.Animation _tauntAnimation;
  Offset offset;
  Offset movingTo;
  // Alignment alignTo;
  // Alignment alignment;
  GlobalKey key;
  GlobalKey bKey = GlobalKey();
  List<Product> products;
  List<Product> recieved = [];
  bool taunt = false;
  bool hasProduct = false;
  bool acceptProduct = false;
  int waitProductDurationSeconds = 5;
  GlobalKey productCrossFadeKey = GlobalKey();
  GlobalKey dragKey = GlobalKey();
  List<Items> items = [];

  Creature(this.key, {this.products}) : super(key: key) {
    // offset = movingTo = Offset(20, 30);
    int n = Random().nextInt(3)+1;
    if (products == null) {
      products = [];
    while (n-- > 0) {
      int r = Random().nextInt(4);

        if (r == 0) {
          products.add(Potion.empty());
        } else if (r == 1) {
          products.add(Weapon.empty());
        } else if (r == 2) {
          products.add(Food.empty());
        } else if (r == 3) {
          products.add(Book.empty());
        }
      }
    }
    // hasProduct = true;

    _walkAnimation = SpriteSheet(
      imageName: 'minotaur_walk.png',
      columns: 18,
      rows: 1,
      textureWidth: 720,
      textureHeight: 420,
    ).createAnimation(
        0,
        stepTime: 0.1,
        loop: true
    );
    _idleAnimation = SpriteSheet(
      imageName: 'minotaur_idle.png',
      columns: 12,
      rows: 1,
      textureWidth: 720,
      textureHeight: 420,
    ).createAnimation(
        0,
        stepTime: 0.1,
        loop: true
    );
    _tauntAnimation = SpriteSheet(
      imageName: 'minotaur_taunt.png',
      columns: 18,
      rows: 1,
      textureWidth: 720,
      textureHeight: 420,
    ).createAnimation(
        0,
        stepTime: 0.1,
        loop: false
    )..onCompleteAnimation = () {
      taunt = false;
      if ((key as GlobalKey).currentState.mounted) {
        (key as GlobalKey).currentState.setState(() {});
      }
    };
  }

  Future waitForProduct() async {
    acceptProduct = true;
    hasProduct = true;
    if ((key as GlobalKey).currentState?.mounted ?? false) {
      (key as GlobalKey).currentState.setState(() {});
    }
    while (waitProductDurationSeconds > 0) {
      int _waitSeconds = waitProductDurationSeconds;
      waitProductDurationSeconds = 0;
      await Future.delayed(Duration(seconds: _waitSeconds));
    }
    if (offset == movingTo) {
      leave();
      if (key.currentState?.mounted ?? false) {
        (key as GlobalKey).currentState.setState(() {});
        (game.key as GlobalKey).currentState.setState(() {});
      }
    }
    return;
  }

  Widget animation({walk = false, idle = true, taunt = false}) {
    if (taunt) {
      return AnimationWidget(
        animation: _tauntAnimation,
      );
    }
    if (idle) {
      return AnimationWidget(
        animation: _idleAnimation,
      );
    } else if (walk) {
      return Transform(
        alignment: Alignment.center,
        transform: movingTo.dx > offset.dx ? Matrix4.rotationY(0) : Matrix4.rotationY(pi),
        // transform: alignment.x < alignTo.x ? Matrix4.rotationY(0) : Matrix4.rotationY(pi),
          child: AnimationWidget(
          animation: _walkAnimation,
        )
      );
    }
  }

  @override
  State createState() => CreatureState();

  void leave() {
    // product = null;
    if (recieved.isNotEmpty) {
      var map = Map();
      recieved.forEach((x) {
        // sum += x.price;
        map[x] = !map.containsKey(x) ? (1) : (map[x] + 1);
      });
      recieved.clear();
      items = map.entries.map((e) => Items(e.value, e.key)).toList();
      var employees = items.first.product.category.department.room.employers ?? game.rooms.firstWhere((e) => e.employers.isNotEmpty).employers;
      Sale sale = Sale()
        ..employerID = employees[Random().nextInt(employees.length)].id
        ..date = DateTime.now();
      sale.addToDB().then((value) {
        var id = value.first.first;
        items.forEach((element) {
          element.check = id;
          element.addToDB();
        });
      });
    }

    acceptProduct = false;
    taunt = false;
    hasProduct = false;
    dragKey = GlobalKey();
    movingTo = Offset(-300, offset.dy);
    bKey = GlobalKey();
    productCrossFadeKey = GlobalKey();
    waitForEnd().then((value) {
      game.creatures.remove(this);
    });
    // game.movedStreamController.add(this);
  }

  Future moveTo(Offset offset) {
    movingTo = offset;
    //alignTo = alignment ?? Alignment.lerp(alignment, dx > 0 ? Alignment.centerRight : Alignment.centerLeft, dx.abs());
    bKey = GlobalKey();
    // game.movedStreamController.add(this);
  }

  Future waitForEnd() {
    return game.movedStreamController.stream.asBroadcastStream()
        .firstWhere((element) => element == this);
  }

}

class CreatureState extends State<Creature> {

  int money = null;

  Stream<bool> loading() async* {
    while (!widget._idleAnimation.loaded()) {
      yield false;
      await Future.delayed(Duration(milliseconds: 300));
    }
    yield true;
  }



  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(

      stream: loading(),
      builder: (context, snapshot) {
        // print('${snapshot.hasData} ${snapshot.data} ${widget._idleAnimation.loaded()}');
        if (snapshot.hasData && snapshot.data && (widget._idleAnimation.loaded())) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                DragTarget(
                  key: widget.dragKey,
                  onWillAccept: (_) {print('will accept'); return widget.acceptProduct && widget.hasProduct;},
                  onAccept: (data) async {
                    game.chooser.remove(data);

                    if ((data as Product).assetName != widget.products.first.assetName) {
                      widget.taunt = true;
                      widget.waitProductDurationSeconds += 2;
                    } else {
                      money = (data as Product).price ?? 0;
                      game.money += money;
                      widget.recieved.add(data);
                    if (widget.products.length > 1) {
                      widget.products.removeAt(0);
                      widget.waitProductDurationSeconds += 4;
                    }
                    if (widget.products.length == 1) {
                      widget.hasProduct = false;
                    widget.waitForEnd()
                        .then((value) {
                          game.creatures.remove(this);
                          (game.key as GlobalKey).currentState.setState(() {});
                    });
                    widget.leave();
                    } else {
                      widget.productCrossFadeKey = GlobalKey();
                      (widget.key as GlobalKey).currentState?.setState(() {});
                    }
                    }
                    (game.key as GlobalKey).currentState.setState(() {});
                  },
                  builder: (context, candidateData, rejectedData) {
                    return SizedBox(
                      width: 300,
                      height: 300,
                      child: Container(
                        child: widget.animation(
                          idle: widget.offset == widget.movingTo,
                          walk: widget.offset != widget.movingTo,
                          taunt: widget.taunt
                          // idle: widget.alignTo == widget.alignment,
                          // walk: widget.alignTo != widget.alignment
                        ),
                      ),
                    );
                  },),
                Positioned(
                  top: -60,
                  child: AnimatedOpacity(
                    opacity: widget.hasProduct ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    child: Container(
                      width: 300,
                      height: 40,
                      child: Image.asset(widget.products.first.assetName, alignment: Alignment.center, fit: BoxFit.fitHeight,),
                    ),
                  ),
                ),
                money == null ? Container() : Container(
                  width: 300,
                  key: GlobalKey(),
                  alignment: Alignment.center,
                  child: SlideFadeTransition(child: Text('$money', style: TextStyle(
                      color: Colors.yellow,
                      shadows: [Shadow(blurRadius: 1)],
                      fontWeight: FontWeight.bold
                  ),),
                    onFinish: () {
                      money = null;
                      // (key as GlobalKey).currentState?.setState(() {});
                    },
                  ),
                )
              ],
            );
        } else {
          return SizedBox(
            width: 300,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          );
        }
      }
    );
  }
}

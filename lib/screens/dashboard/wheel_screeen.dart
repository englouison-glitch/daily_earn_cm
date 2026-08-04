import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _spinning = false;
  bool _canSpin = true;

  static const List<int> rewards = [5, 10, 15, 0, 25, 5, 10, 0, 50, 5, 15, 0];
  static const List<Color> colors = [
    Colors.blue, Colors.green, Colors.orange, Colors.grey,
    Colors.purple, Colors.blue, Colors.green, Colors.grey,
    Colors.amber, Colors.blue, Colors.orange, Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = _controller.drive(Tween<double>(begin: 0, end: 0));
    _checkCanSpin();
  }

  Future<void> _checkCanSpin() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return;
    final lastSpin = userDoc.data()?['lastWheelSpin'];
    final now = DateTime.now();
    if (lastSpin != null) {
      final lastDate = (lastSpin as Timestamp).toDate();
      _canSpin = now.day != lastDate.day || now.month != lastDate.month || now.year != lastDate.year;
    }
    setState(() {});
  }

  Future<void> _spinWheel() async {
    if (!_canSpin || _spinning) return;
    setState(() => _spinning = true);

    final random = Random();
    final selectedIndex = random.nextInt(rewards.length);
    final segmentAngle = 2 * pi / rewards.length;
    final targetAngle = 2 * pi * 5 + (2 * pi - selectedIndex * segmentAngle - segmentAngle / 2);

    _animation = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    await _controller.forward(from: 0);
    final reward = rewards[selectedIndex];

    if (reward > 0) {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userData = await tx.get(userRef);
        final currentBalance = userData.data()?['balance'] ?? 0;
        tx.update(userRef, {'balance': currentBalance + reward, 'lastWheelSpin': FieldValue.serverTimestamp()});
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🎉 Gagné : $reward FCFA !"), backgroundColor: Colors.green));
    } else {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'lastWheelSpin': FieldValue.serverTimestamp()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("😞 Rien gagné, réessaye demain !"), backgroundColor: Colors.orange));
    }

    setState(() {_spinning = false; _canSpin = false;});
  }

  @override
  void dispose() {_controller.dispose(); super.dispose();}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎡 Roue de la Chance")),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Tourne 1 fois par jour gratuitement !", style: TextStyle(fontSize:17)),
        const SizedBox(height:30),
        Stack(alignment: Alignment.center, children:[
          AnimatedBuilder(animation: _animation, builder:(ctx,ch)=>Transform.rotate(angle:_animation.value, child:CustomPaint(size:const Size(300,300), painter:WheelPainter(rewards,colors)))),
          const TrianglePointer()
        ]),
        const SizedBox(height:30),
        SizedBox(width:220, child:ElevatedButton(
          style:ElevatedButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:15), backgroundColor:_canSpin&&!_spinning?const Color(0xFF2563EB):Colors.grey),
          onPressed:_canSpin&&!_spinning?_spinWheel:null,
          child:Text(_spinning?"En cours...":_canSpin?"🎰 TOURNER":"Déjà joué", style:const TextStyle(fontSize:17,color:Colors.white))
        ))
      ]))
    );
  }
}

class WheelPainter extends CustomPainter{
  final List<int> rewards; final List<Color> colors;
  WheelPainter(this.rewards,this.colors);
  @override
  void paint(Canvas canvas,Size size){
    final center=Offset(size.width/2,size.height/2); final radius=min(size.width/2,size.height/2); final segAngle=2*pi/rewards.length;
    for(int i=0;i<rewards.length;i++){
      canvas.drawArc(Rect.fromCircle(center:center,radius:radius), -pi/2+i*segAngle,segAngle,true,Paint()..color=colors[i]);
      var tp=TextPainter(text:TextSpan(text:"${rewards[i]}",style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),textDirection:TextDirection.ltr);
      tp.layout(); tp.paint(canvas, Offset(center.dx+(radius-45)*cos(-pi/2+i*segAngle+segAngle/2)-12, center.dy+(radius-45)*sin(-pi/2+i*segAngle+segAngle/2)-10));
    }
    canvas.drawCircle(center,30,Paint()..color=Colors.white);canvas.drawCircle(center,24,Paint()..color=Color(0xFF2563EB));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>true;
}
class TrianglePointer extends StatelessWidget{
  const TrianglePointer({super.key});@override Widget build(BuildContext context)=>Positioned(top:0,child:CustomPaint(size:const Size(40,35),painter:TrianglePainter()));
}
class TrianglePainter extends CustomPainter{
  @override void paint(Canvas canvas,Size size){Path p=Path();p.moveTo(size.width/2,size.height);p.lineTo(0,0);p.lineTo(size.width,0);p.close();canvas.drawPath(p,Paint()..color=Colors.red);}
  @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}


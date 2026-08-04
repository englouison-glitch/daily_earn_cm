import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization/app_localization.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedOperator;
  static const int _minWithdraw = 2000;

  Future<void> _sendRequest(double available) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.parse(_amountCtrl.text.trim());

    if (amount < _minWithdraw && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Minimum : 2000 FCFA !"), backgroundColor: Colors.orange)
      );
      return;
    }
    if (amount > available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Solde insuffisant !"), backgroundColor: Colors.red)
      );
      return;
    }

    await FirebaseFirestore.instance.collection('withdrawRequests').add({
      'userId': _uid,
      'amount': amount,
      'operator': _selectedOperator,
      'phone': _phoneCtrl.text.trim(),
      'date': FieldValue.serverTimestamp(),
      'status': "en_attente"
    });
    await FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'balance': FieldValue.increment(-amount)
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Demande envoyée ! Paiement sous 24-48h"), backgroundColor: Colors.green)
      );
      _amountCtrl.clear(); _phoneCtrl.clear(); setState(()=>_selectedOperator=null);
    }
  }

  @override dispose() {
    _amountCtrl.dispose(); _phoneCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate("wallet")), backgroundColor: const Color(0xFF0F3460)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(18),
        child: Column(children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
            builder: (_, snap) {
              final solde = snap.data?.exists ?? false ? (snap.data() as Map)['balance'] ?? 0 : 0;
              return Container(width: double.infinity, padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius:15)]),
                child: Column(children: [
                  Text(loc.translate("balance"), style: const TextStyle(fontSize:17, color:Colors.black54)),
                  Text("$solde FCFA", style: const TextStyle(fontSize:38, fontWeight:FontWeight.bold, color:Color(0xFF0F3460)))
                ]));
            }
          ),
          const SizedBox(height:15),
          Container(width:double.infinity, padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.blue.shade50, borderRadius:BorderRadius.circular(12)),
            child:Text("ℹ️ Retrait à partir de 2000 FCFA — vérification rapide anti-fraude.", style:TextStyle(color:Color(0xFF0F3460)))),
          const SizedBox(height:20),
          Form(key:_formKey, child:Column(children:[
            TextFormField(controller:_amountCtrl, keyboardType:TextInputType.number,
              decoration:InputDecoration(labelText:"Montant", prefixIcon:const Icon(Icons.monetization_on), border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
              validator:(v)=>v==null||int.tryParse(v)==null?"Nombre valide !":null),
            SizedBox(height:12),
            DropdownButtonFormField<String>(value:_selectedOperator,
              decoration:InputDecoration(labelText:"Opérateur", prefixIcon:const Icon(Icons.network_cell), border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
              items:const [DropdownMenuItem(value:"MTN MoMo", child:Text("MTN MoMo")), DropdownMenuItem(value:"Orange Money", child:Text("Orange Money"))],
              onChanged:(v)=>setState(()=>_selectedOperator=v),
              validator:(v)=>v==null?"Choisissez !":null),
            SizedBox(height:12),
            TextFormField(controller:_phoneCtrl, keyboardType:TextInputType.phone,
              decoration:InputDecoration(labelText:"Numéro Mobile Money", prefixIcon:const Icon(Icons.phone), border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))),
              validator:(v)=>(v??"").length<8?"Numéro valide !":null),
            SizedBox(height:20),
            SizedBox(width:double.infinity, child:ElevatedButton.icon(
              icon:const Icon(Icons.send, color:Colors.white), label:Text("Demander le paiement", style:TextStyle(fontSize:16, fontWeight:FontWeight.bold)),
              style:ElevatedButton.styleFrom(backgroundColor:Colors.green.shade700, padding:const EdgeInsets.symmetric(vertical:14), shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
              onPressed:()async{final d=await FirebaseFirestore.instance.collection('users').doc(_uid).get(); if(d.exists) _sendRequest((d.data() as Map)['balance'].toDouble());}
            ))
          ]))
        ])
      )
    );
  }
}


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'auth_screen.dart';
import 'localization/app_localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate("settings")), backgroundColor: const Color(0xFF0F3460)),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        Card(child: ListTile(
          leading: const Icon(Icons.language, color: Color(0xFF1A5F7A)),
          title: Text(loc.translate("language")),
          subtitle: Text(Localizations.localeOf(context).languageCode == 'fr' ? "Français" : "English"),
          onTap: _showLangDialog
        )),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.gavel, color: Colors.blueGrey), title: Text(loc.translate("terms")), onTap: _showTerms),
          ListTile(leading: const Icon(Icons.privacy_tip, color: Colors.teal), title: Text(loc.translate("privacy_policy")), onTap: _showPrivacy),
        ])),
        Card(child: ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
          title: Text("À propos"),
          subtitle: const Text("DailyEarn CM • Louison Eng • v1.0"),
        )),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.white),
          label: Text(loc.translate("logout"), style: const TextStyle(fontSize:16, fontWeight:FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical:14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: _confirmLogout
        ))
      ])
    );
  }

  void _showLangDialog(){
    showDialog(context:context, builder:(_)=>AlertDialog(
      title:const Text("Choisir la langue / Choose language"),
      actions:[
        TextButton(onPressed:(){Navigator.pop(context); Provider.of<LocaleNotifier>(context,listen:false).setLocale(const Locale('fr'));}, child:const Text("🇫🇷 Français")),
        TextButton(onPressed:(){Navigator.pop(context); Provider.of<LocaleNotifier>(context,listen:false).setLocale(const Locale('en'));}, child:const Text("🇬🇧 English")),
      ]
    ));
  }

  void _showTerms()=>_showInfo("Conditions Générales","Réservé aux +16 ans, pas de fraude, revenus variables selon votre activité...");
  void _showPrivacy()=>_showInfo("Politique de Confidentialité","Vos données sont protégées, jamais vendues, utilisées uniquement pour le bon fonctionnement.");
  void _showInfo(String titre,String texte)=>showDialog(context:context,builder:(_)=>AlertDialog(title:Text(titre),content:Text(texte),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text("OK"))]));

  Future<void> _confirmLogout()async{
    bool? sure=await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text("Confirmer ?"),content:const Text("Vous devrez vous reconnecter."),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text("Annuler")),ElevatedButton(onPressed:()=>Navigator.pop(context,true),child:const Text("Oui"))]));
    if(sure==true&&mounted){await FirebaseAuth.instance.signOut();Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const AuthScreen()));}
  }
}


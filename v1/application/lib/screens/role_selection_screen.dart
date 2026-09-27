
import 'package:flutter/material.dart';
import 'homeowner_dashboard.dart';
import 'constructor_dashboard.dart';
class RoleSelectionScreen extends StatelessWidget{
 const RoleSelectionScreen({super.key});
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text("Select Role")),body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[ElevatedButton.icon(icon:Icon(Icons.person),label:Text("Homeowner"),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const HomeownerDashboard()))),SizedBox(height:20),ElevatedButton.icon(icon:Icon(Icons.engineering),label:Text("Constructor"),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ConstructorDashboard())))])));
}

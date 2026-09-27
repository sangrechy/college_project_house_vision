
import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
class LoginScreen extends StatelessWidget{
 const LoginScreen({super.key});
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text("Login")),body:Padding(padding:EdgeInsets.all(20),child:Column(children:[TextField(decoration:InputDecoration(labelText:"Email")),TextField(obscureText:true,decoration:InputDecoration(labelText:"Password")),SizedBox(height:20),ElevatedButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const RoleSelectionScreen())),child:Text("Login"))])));
}

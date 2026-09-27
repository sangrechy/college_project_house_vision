
import 'package:flutter/material.dart';
import 'login_screen.dart';
class SplashScreen extends StatefulWidget{
 const SplashScreen({super.key});
 @override State<SplashScreen> createState()=>_S();
}
class _S extends State<SplashScreen>{
 @override void initState(){
   super.initState();
   Future.delayed(const Duration(seconds:2),(){
     if (mounted) {
       Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const LoginScreen()));
     }
   });
 }
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.home_work,size:90,color:Colors.blue),Text("House Vision",style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),Text("Visualize • Build • Monitor")])));}

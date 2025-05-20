import 'package:app_v0/features/home/components/timeline_tile.dart';
import 'package:app_v0/features/home/home_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage ({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomePageController>(
      init: HomePageController(),
      builder: (controller){
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: ListView(
              children: [
              MyTimelineTile(
                isFirst: true, 
                isLast: false, 
                isPast: true, 
                eventCard: Text('STATUS DE CONEXAO',
                  style: TextStyle(
                  color: Colors.white
                )),
                ),
            
              MyTimelineTile(
              isFirst: false, 
              isLast: false, 
              isPast: true, 
                eventCard: Text('RECONHECIMENTO BEBE',
                  style: TextStyle(
                  color: Colors.white,
                )),
                ),
            
              MyTimelineTile(
                isFirst: false, 
                isLast: true, 
                isPast: false, 
                eventCard: Text('NOTIFICACAO ENVIADA',
                  style: TextStyle(
                  color: Colors.white,
                )),
                ),
              ],
            ),
          ),
        );
      }
    );
    }
}
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_object_detection/app/app_router.dart';
import 'package:flutter_realtime_object_detection/services/navigation_service.dart';
import 'package:flutter_realtime_object_detection/services/tensorflow_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MultiProvider(
    providers: <SingleChildWidget>[
      Provider<AppRoute>(create: (_) => AppRoute()),
      Provider<NavigationService>(create: (_) => NavigationService()),
      Provider<TensorFlowService>(create: (_) => TensorFlowService())
    ],
    child: Application(),
  ));
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppRoute appRoute = Provider.of<AppRoute>(context, listen: false);
    return ScreenUtilInit(
        designSize: Size(375, 812),
        builder: () {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              // Define the default brightness and colors.
              brightness: Brightness.dark,
              primaryColor: Colors.deepPurpleAccent[800],

              // Define the default font family.
              fontFamily: 'Georgia',

              // Define the default `TextTheme`. Use this to specify the default
              // text styling for headlines, titles, bodies of text, and more.
              textTheme: const TextTheme(
                headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
                headline6: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
                bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
              ),
            ),
            onGenerateRoute: appRoute.generateRoute,
            initialRoute: AppRoute.splashScreen,
            navigatorKey: NavigationService.navigationKey,
            navigatorObservers: <NavigatorObserver>[
              NavigationService.routeObserver
            ],
          );
        });
  }
}

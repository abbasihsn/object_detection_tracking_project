import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as UI;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_realtime_object_detection/app/app_resources.dart';
import 'package:flutter_realtime_object_detection/app/app_router.dart';
import 'package:flutter_realtime_object_detection/app/base/base_stateful.dart';
import 'package:flutter_realtime_object_detection/main.dart';
import 'package:flutter_realtime_object_detection/services/navigation_service.dart';
import 'package:flutter_realtime_object_detection/services/tensorflow_service.dart';
import 'package:flutter_realtime_object_detection/view_models/home_view_model.dart';
import 'package:flutter_realtime_object_detection/widgets/confidence_widget.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends BaseStateful<HomeScreen, HomeViewModel>
    with WidgetsBindingObserver {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  late StreamController<Map> apertureController;


  late Uint8List _imageFile;

  @override
  bool get wantKeepAlive => true;

  @override
  void afterFirstBuild(BuildContext context) {
    super.afterFirstBuild(context);
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void initState() {
    super.initState();
    loadModel(viewModel.state.type);
    initCamera();

    apertureController = StreamController<Map>.broadcast();
  }

  void initCamera() {
    _cameraController = CameraController(
        cameras[viewModel.state.cameraIndex], ResolutionPreset.high);
    _initializeControllerFuture = _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _cameraController.setFlashMode(FlashMode.off);

      /// TODO: Run Model
      setState(() {});
      _cameraController.startImageStream((image) async {
        if (!mounted) {
          return;
        }
        await viewModel.runModel(image);
      });
    });
  }

  void loadModel(ModelType type) async {
    await viewModel.loadModel(type);
  }

  Future<void> runModel(CameraImage image) async {
    if (mounted) {
      await viewModel.runModel(image);
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    viewModel.close();
    apertureController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    /// TODO: Check Camera
    if (!_cameraController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController.dispose();
    } else {
      initCamera();
    }
  }

  @override
  Widget buildPageWidget(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: false,
        appBar: buildAppBarWidget(context),
        body: buildBodyWidget(context),
        floatingActionButton: buildFloatingActionButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
  }

  Widget buildFloatingActionButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
      child: FloatingActionButton(
        heroTag: null,
        onPressed: handleSwitchCameraClick,
        tooltip: "Switch Camera",
        backgroundColor: AppColors.white,
        foregroundColor: Colors.deepPurpleAccent,
        child: Icon(
          viewModel.state.isBackCamera()
              ? Icons.camera_front
              : Icons.camera_rear,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }

  Future<bool> handleSwitchCameraClick() async {
    apertureController.sink.add({});
    viewModel.switchCamera();
    initCamera();
    return true;
  }

  handleSwitchSource(ModelType item) {
    viewModel.dispose();
    viewModel.updateTypeTfLite(item);
    Provider.of<NavigationService>(context, listen: false).pushReplacementNamed(
        AppRoute.homeScreen,
        args: {'isWithoutAnimation': true});
  }

  @override
  AppBar buildAppBarWidget(BuildContext context) {
    return AppBar(
      elevation: 0.0,
      centerTitle: true,
      actions: [
        PopupMenuButton<ModelType>(
            onSelected: (item) => handleSwitchSource(item),
            color: AppColors.white,
            itemBuilder: (context) => [
                  PopupMenuItem(
                      enabled: !viewModel.state.isYolo(),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.api,
                              color: !viewModel.state.isYolo()
                                  ? AppColors.black
                                  : AppColors.grey),
                          Text(' YOLO',
                              style: AppTextStyles.regularTextStyle(
                                  color: !viewModel.state.isYolo()
                                      ? AppColors.black
                                      : AppColors.grey)),
                        ],
                      ),
                      value: ModelType.YOLO),
                  PopupMenuItem(
                      enabled: !viewModel.state.isMobileNet(),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.api,
                              color: !viewModel.state.isMobileNet()
                                  ? AppColors.black
                                  : AppColors.grey),
                          Text(' MobileNet',
                              style: AppTextStyles.regularTextStyle(
                                  color: !viewModel.state.isMobileNet()
                                      ? AppColors.black
                                      : AppColors.grey)),
                        ],
                      ),
                      value: ModelType.MobileNet),
                ]),
      ],
      backgroundColor: Colors.deepPurpleAccent,
      title: Text(
        AppStrings.title,
        style: AppTextStyles.boldTextStyle(
            color: AppColors.white, fontSize: AppFontSizes.large),
      ),
    );
  }

  @override
  Widget buildBodyWidget(BuildContext context) {
    double heightAppBar = AppBar().preferredSize.height;

    bool isInitialized = _cameraController.value.isInitialized;

    final Size screen = MediaQuery.of(context).size;
    final double screenHeight = max(screen.height, screen.width);
    final double screenWidth = min(screen.height, screen.width);

    final Size previewSize =
        isInitialized ? _cameraController.value.previewSize! : Size(100, 100);
    final double previewHeight = max(previewSize.height, previewSize.width);
    final double previewWidth = min(previewSize.height, previewSize.width);

    final double screenRatio = screenHeight / screenWidth;
    final double previewRatio = previewHeight / previewWidth;
    final maxHeight =
        screenRatio > previewRatio ? screenHeight : screenWidth * previewRatio;
    final maxWidth =
        screenRatio > previewRatio ? screenHeight / previewRatio : screenWidth;

    return Container(
        height: MediaQuery.of(context).size.height,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: <Widget>[
                  OverflowBox(
                    maxHeight: maxHeight,
                    maxWidth: maxWidth,
                    child: FutureBuilder<void>(
                        future: _initializeControllerFuture,
                        builder: (_, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return CameraPreview(_cameraController);
                          } else {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.blue));
                          }
                        }),
                  ),
                  Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
                    return ConfidenceWidget(
                      heightAppBar: heightAppBar,
                      entities: homeViewModel.state.recognitions,
                      previewHeight: max(homeViewModel.state.heightImage,
                          homeViewModel.state.widthImage),
                      previewWidth: min(homeViewModel.state.heightImage,
                          homeViewModel.state.widthImage),
                      screenWidth: MediaQuery.of(context).size.width,
                      screenHeight: MediaQuery.of(context).size.height,
                      type: homeViewModel.state.type,
                    );
                  }),
                ],
              )),
        ));
  }
}

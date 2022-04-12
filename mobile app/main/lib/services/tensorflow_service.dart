import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';

enum ModelType { YOLO, VGG2, MobileNet }

class TensorFlowService {
  ModelType _type = ModelType.YOLO;

  ModelType get type => _type;

  set type(type) {
    _type = type;
  }

  loadModel(ModelType type) async {
    try {
      Tflite.close();
      String? res;
      switch (type) {
        case ModelType.YOLO:
          res = await Tflite.loadModel(
              model: 'assets/models/yolov2_tiny.tflite',
              labels: 'assets/models/yolov2_tiny.txt');
          break;
        case ModelType.VGG2:
          res = await Tflite.loadModel(
              model: 'assets/models/cifar10_model.tflite',
              labels: 'assets/models/cifar10_labels.txt');
          break;
        case ModelType.MobileNet:
          res = await Tflite.loadModel(
              model: 'assets/models/mobilenet_v1.tflite',
              labels: 'assets/models/mobilenet_v1.txt');
          break;
        default:
          res = await Tflite.loadModel(
              model: 'assets/models/yolov2_tiny.tflite',
              labels: 'assets/models/yolov2_tiny.txt');
      }
      print('loadModel: $res - $_type');
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  close() async {
    await Tflite.close();
  }

  Future<List<dynamic>?> runModelOnFrame(CameraImage image) async {
    List<dynamic>? recognitions = <dynamic>[];
    switch (_type) {
      case ModelType.YOLO:
        recognitions = await Tflite.detectObjectOnFrame(
          bytesList: image.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          model: "VGG2",
          imageHeight: image.height,
          imageWidth: image.width,
          imageMean: 0,
          imageStd: 255.0,
          threshold: 0.2,
          numResultsPerClass: 1,
        );
        break;
      case ModelType.VGG2:
        recognitions = await Tflite.detectObjectOnFrame(
          bytesList: image.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          model: "SSDMobileNet",
          imageHeight: image.height,
          imageWidth: image.width,
          imageMean: 127.5,
          imageStd: 127.5,
          threshold: 0.4,
          numResultsPerClass: 1,
        );
        break;
      case ModelType.MobileNet:
        recognitions = await Tflite.runModelOnFrame(
          bytesList: image.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: image.height,
          imageWidth: image.width,
          numResults: 5
        );
        break;
      default:
    }
    print("recognitions: $recognitions");
    return recognitions;
  }

  Future<List<dynamic>?> runModelOnImage(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 127.5,
        numResultsPerClass: 1);
    return recognitions;
  }
}

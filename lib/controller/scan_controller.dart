import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
  class ScanController extends GetxController{
    @override
    void onInit() async {
      super.onInit();

      initCamera();
      initTFLite();
    }

    @override
    void dispose(){
      super.dispose();
      cameraController.dispose();
    }

    late CameraController cameraController;
    late List<CameraDescription> cameras;

    var isCameraInitialized = false.obs;
    var cameraCout = 0;

    var x,y,w,h = 0.0;
    var label = "";

    initCamera() {
      Permission.camera.request().then((status) {
        if (status.isGranted) {
          availableCameras().then((cameras) {
            if (cameras.isNotEmpty) {
              cameraController = CameraController(
                cameras[0],
                ResolutionPreset.max,
                imageFormatGroup: ImageFormatGroup.jpeg,
              );

              cameraController.initialize().then((_) {
                cameraController.startImageStream((image) {
                  cameraCout++;
                  if (cameraCout % 10 == 0) {
                    objectDetector(image);
                  }
                  update();
                });

                isCameraInitialized(true);
              });
            } else {
              print("No cameras available");
            }
          });
        } else {
          print("Permission denied");
        }
      });
    }



    initTFLite() async{
      await Tflite.loadModel(
          model: "assets/best_float32.tflite",
          labels: "assets/label.txt",
          isAsset: true,
          useGpuDelegate: false,
      );
      print("TFLite model loaded successfully!");
    }

    objectDetector(CameraImage image) async{
      print("Bắt đầu phát hiện đối tượng");
      var detector = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((e)
      {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 8,
      rotation: 90,
      threshold: 0.2,
      );

      if (detector != null) {
        print("Đã phát hiện được đối tượng");
        var ourDetectedObject = detector.first;
        if (ourDetectedObject['confidenceInClass'] * 100 > 45){
          label = detector.first['detectedClass'].toString();
          h = ourDetectedObject['react']['h'];
          w = ourDetectedObject['react']['w'];
          x = ourDetectedObject['react']['x'];
          y = ourDetectedObject['react']['y'];
        }
        update();
      }
    }
  }
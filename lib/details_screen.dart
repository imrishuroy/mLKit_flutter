import 'dart:io';
import 'dart:async';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DetailsScreen extends StatefulWidget {
  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String title = '';
  bool _isLoading = false;
  File _image;
  var imageFile;
  bool isFaceDetected = false;

  var resultText = '';

  final _picker = ImagePicker();

  List<Rect> rect = new List<Rect>();

  Future selectImage() async {
    final pickedImage = await _picker.getImage(source: ImageSource.gallery);

    imageFile = await pickedImage.readAsBytes();
    imageFile = await decodeImageFromList(imageFile);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _isLoading = true;
        imageFile = imageFile;
        isFaceDetected = true;
      } else {
        print('Some thing went wrong');
      }
    });
  }

  readTextFromImage() async {
    resultText = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(_image);
    TextRecognizer recognizerText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizerText.processImage(myImage);

    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          // print(word.text);
          setState(() {
            resultText = resultText + ' ' + word.text;
          });
        }
      }
    }
  }

  decodeBarCode() async {
    resultText = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(_image);
    BarcodeDetector barcodeDetector = FirebaseVision.instance.barcodeDetector();
    List barCodes = await barcodeDetector.detectInImage(myImage);

    for (Barcode redableCode in barCodes) {
      //print(redableCode.displayValue);
      setState(() {
        resultText = redableCode.displayValue;
      });
    }
  }

  Future labesRead() async {
    resultText = '';
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(_image);
    ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
    List labels = await labeler.processImage(myImage);

    for (ImageLabel label in labels) {
      final String text = label.text;
      final double confidence = label.confidence;
      //print('Text = $text and Confidence = ${(confidence * 100).toInt()}%');
      setState(
        () {
          resultText = resultText +
              ' ' +
              text +
              '  ' 'Confidence - ' '${(confidence * 100).toInt()}%\n';
        },
      );
    }
  }

  Future detectFace() async {
    FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(_image);
    FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(myImage);

    if (rect.length > 0) {
      rect = new List<Rect>();
    }

    for (Face face in faces) {
      rect.add(face.boundingBox);
    }
  }

  @override
  Widget build(BuildContext context) {
    title = ModalRoute.of(context).settings.arguments.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_a_photo,
              color: Colors.white,
            ),
            onPressed: selectImage,
          ),
        ],
      ),
      body: Column(
        children: [
          _isLoading && !isFaceDetected
              ? Container(
                  margin: EdgeInsets.all(20.0),
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_image),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : isFaceDetected && _isLoading
                  ? Center(
                      child: Container(
                        child: FittedBox(
                          child: SizedBox(
                            width: imageFile.width.toDouble(),
                            height: imageFile.height.toDouble(),
                            child: CustomPaint(
                              painter: FacePainter(
                                imageFile: imageFile,
                                rect: rect,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(),
          SizedBox(height: 50.0),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              resultText,
              style: TextStyle(
                fontSize: 18.0,
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: detectFace,
        child: Icon(
          Icons.check,
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Rect> rect;
  var imageFile;

  FacePainter({@required this.imageFile, @required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    for (Rect rectangle in rect) {
      canvas.drawRect(
        rectangle,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    throw UnimplementedError();
  }
}

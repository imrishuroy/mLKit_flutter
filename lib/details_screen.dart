import 'dart:io';

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

  var resultText = '';

  final _picker = ImagePicker();

  Future selectImage() async {
    final pickedImage = await _picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
        _isLoading = true;
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
          _isLoading
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
              : Center(
                  child: Text('No Image Found'),
                ),
          SizedBox(height: 50.0),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              resultText,
              style: TextStyle(
                fontSize: 18.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: decodeBarCode,
        child: Icon(
          Icons.check,
        ),
      ),
    );
  }
}

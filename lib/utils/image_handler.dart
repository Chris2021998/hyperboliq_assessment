import 'dart:math';

import 'package:hyperboliq_assessment/main.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as imgPicker;
import 'package:logger/logger.dart';

class ImageHandler {
  
  // Calculate average RGB of an image
  List<int> getAverageRGB(Uint8List inputImg) {
    try {
      final decodedImg = img.decodeImage(inputImg);
      final decodedBytes = decodedImg!.getBytes(order: img.ChannelOrder.rgb);

      var red = 0;
      var green = 0;
      var blue = 0;
      for (int y = 0; y < decodedImg.height; y++) {
        for (int x = 0; x < decodedImg.width; x++) {
          red = red + decodedBytes[y * decodedImg.width * 3 + x * 3];
          green = green + decodedBytes[y * decodedImg.width * 3 + x * 3 + 1];
          blue = blue + decodedBytes[y * decodedImg.width * 3 + x * 3 + 2];
        }
      }

      final pixels = decodedImg.height * decodedImg.width;
      final avgRed = (red / pixels).round();
      final avgGreen = (green / pixels).round();
      final avgBlue = (blue / pixels).round();
      
      return [avgRed, avgGreen, avgBlue];
    } catch (e) {
      logger.e(e);
      rethrow;
    }
  }

  // Split image into a grid
  List<List<Uint8List>> splitImage(Uint8List inputImg, { int rows = 20, int columns = 20 }) {
    try {
      // convert image to image from image package
      final decodedImg = img.decodeImage(inputImg);

      int x = 0, y = 0;
      int width = (decodedImg!.width / columns).round();
      int height = (decodedImg.height / rows).round();
      
      // split image to parts
      final parts = <List<Uint8List>>[];
      for (int i = 0; i < rows; i++) {
        final row = <Uint8List>[];
        for (int j = 0; j < columns; j++) {
          final croppedImg = img.copyCrop(decodedImg, x: x, y: y, width: width, height: height);
          final imgEncoded = img.encodeJpg(croppedImg);
          row.add(imgEncoded);
          x += width;
        }
        parts.add(row);
        x = 0;
        y += height;
      }

      return parts;
    } catch (e) {
      logger.e(e);
      rethrow;
    }
  }

  // Replace segments of an image with tiles
  Uint8List replaceWithTiles(Uint8List inputImg, List<List<Uint8List>> tiles) {
    try {
      final decodedImg = img.decodeImage(inputImg);
      img.Image? image;

      int x = 0, y = 0;
      int height = (decodedImg!.height / tiles.length).round();

      for (int i = 0; i < tiles.length; i++) {
        final row = tiles[i];
        int width = (decodedImg.width / row.length).round();

        for (int j = 0; j < row.length; j++) {
          final tile = img.decodeImage(row[j]);
          image = img.compositeImage(decodedImg, tile!, dstX: x, dstY: y, dstW: width, dstH: height);
          x += width;
        }
        x = 0;
        y += height;
      }

      
      return img.encodeJpg(image!);
    } catch (e) {
      logger.e(e);
      rethrow;
    }
  }

  // Convert RGB to XYZ
  List<double> convertRgbToXyz(List<int> rgb) {
    try {
      // D50 1964
      var varR = rgb[0] / 255;
      var varG = rgb[1] / 255;
      var varB = rgb[2] / 255;

      varR = varR > 0.04045 ? pow(((varR + 0.055) / 1.055), 2.4).toDouble() : varR / 12.92;
      varG = varR > 0.04045 ? pow(((varG + 0.055) / 1.055), 2.4).toDouble() : varG / 12.92;
      varB = varR > 0.04045 ? pow(((varB + 0.055) / 1.055), 2.4).toDouble() : varB / 12.92;

      varR = varR * 100;
      varG = varG * 100;
      varB = varB * 100;

      final x = varR * 0.4124 + varG * 0.3576 + varB * 0.1805;
      final y = varR * 0.2126 + varG * 0.7152 + varB * 0.0722;
      final z = varR * 0.0193 + varG * 0.1192 + varB * 0.9505;

      return [x, y, z];
    } catch (e) {
      logger.e(e);
      rethrow;
    }
  }

  // Conver XYZ to LAB
  List<double> convertXyzToLab(List<double> xyz) {
    try {
      // D65 1931 2 degrees
      var varX = xyz[0] / 95.044;
      var varY = xyz[1] / 100.000;
      var varZ = xyz[2] / 108.755;
      
      varX = varX > 0.008856 ? pow(varX, (1/3)).toDouble() : ( 7.787 * varX ) + ( 16 / 116 );
      varY = varY > 0.008856 ? pow(varY, (1/3)).toDouble() : ( 7.787 * varY ) + ( 16 / 116 );
      varZ = varZ > 0.008856 ? pow(varZ, (1/3)).toDouble() : ( 7.787 * varZ ) + ( 16 / 116 );

      final cieL = ( 116 * varY ) - 16;
      final cieA = 500 * ( varX - varY );
      final cieB = 200 * ( varY - varZ );

      return [cieL, cieA, cieB];
    } catch (e) {
      logger.e(e);
      rethrow;
    }
  }

  // Calculate DeltaECIE
  double differenceDelteECIE(List<double> upload, List<double> asset) {
    try {
        final cieL1 = upload[0];
        final cieA1 = upload[1];
        final cieB1 = upload[2];
        final cieL2 = asset[0];
        final cieA2 = asset[1];
        final cieB2 = asset[2];

        final deltaE = sqrt(pow( cieL1 - cieL2, 2 ) + pow( cieA1 - cieA2, 2 ) + pow( cieB1 - cieB2, 2 ));
        return deltaE;
    } catch (e) {
      logger.e(e);
      rethrow;
    }
  }
}

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

bool _webcamViewRegistered = false;

void registerWebcamViewFactory(String viewType, String containerId) {
  if (_webcamViewRegistered) return;

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    return html.document.getElementById(containerId) ??
        (html.DivElement()
          ..id = containerId
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.display = 'flex'
          ..style.justifyContent = 'center'
          ..style.alignItems = 'center'
          ..style.background = '#000');
  });

  _webcamViewRegistered = true;
}

Widget buildWebcamView(String viewType) {
  return HtmlElementView(viewType: viewType);
}

import 'package:ensemble/framework/action.dart' as action;
import 'package:ensemble/framework/icon.dart' as ensemble;
import 'package:ensemble/framework/view.dart';
import 'package:ensemble/page_model.dart';
import 'package:ensemble/util/utils.dart';
import 'package:ensemble_ts_interpreter/invokables/invokable.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

/// base mixin for Ensemble Container (e.g Column)
mixin UpdatableContainer {
  void initChildren({List<Widget>? children, ItemTemplate? itemTemplate});
}


/// base Controller class for your Ensemble widget
abstract class WidgetController extends Controller {

  // Note: we manage these here so the user doesn't need to do in their widgets
  // base properties applicable to all widgets
  bool expanded = false;
  //int? padding;

  @override
  Map<String, Function> getBaseGetters() {
    return {
      'expanded': () => expanded,
      //'padding': () => padding,
    };
  }

  @override
  Map<String, Function> getBaseSetters() {
    return {
      'expanded': (value) => expanded = Utils.getBool(value, fallback: false),
      //'padding': (value) => padding = Utils.optionalInt(value),
    };
  }
}

/// base class for widgets that want to participate in Ensemble layout
abstract class WidgetState<W extends HasController> extends BaseWidgetState<W> {
  @override
  void dispose() {
    /*ViewManager? viewManager = ViewWidget.of(context);
    if (viewManager != null) {
      //viewManager.dispose(widget);
    }*/
    super.dispose();
  }
}



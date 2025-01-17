
import 'package:ensemble/framework/action.dart';
import 'package:ensemble/framework/widget/icon.dart' as ensembleLib;
import 'package:ensemble/screen_controller.dart';
import 'package:ensemble/util/utils.dart';
import 'package:ensemble/framework/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:ensemble_ts_interpreter/invokables/invokable.dart';

class EnsembleIcon extends StatefulWidget with Invokable, HasController<IconController, IconState> {
  static const type = 'Icon';
  EnsembleIcon({Key? key}) : super(key: key);

  final IconController _controller = IconController();
  @override
  IconController get controller => _controller;

  @override
  State<StatefulWidget> createState() => IconState();

  @override
  Map<String, Function> getters() {
    return {};
  }
  @override
  Map<String, Function> setters() {
    return {
      'icon': (value) => _controller.icon = value,
      'library': (value) => _controller.library = Utils.optionalString(value),
      'size': (value) => _controller.size = Utils.optionalInt(value),
      'color': (value) => _controller.color = Utils.getColor(value),
      'onTap': (funcDefinition) => _controller.onTap = Utils.getAction(funcDefinition, initiator: this),
    };
  }
  @override
  Map<String, Function> methods() {
    return {};
  }

}
class IconController extends WidgetController {
  dynamic icon;
  String? library;
  int? size;
  Color? color;
  EnsembleAction? onTap;
}

class IconState extends WidgetState<EnsembleIcon> {

  @override
  Widget buildWidget(BuildContext context) {

    return InkWell(
      splashColor: Colors.transparent,
      onTap: widget._controller.onTap == null ? null : () =>
          ScreenController().executeAction(context, widget._controller.onTap!),
      child: ensembleLib.Icon(
        widget._controller.icon,
        library: widget._controller.library,
        size: widget._controller.size,
        color: widget._controller.color
      )
    );
  }



}
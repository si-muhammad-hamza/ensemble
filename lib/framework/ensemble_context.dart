


import 'package:ensemble/widget/widgets.dart';
import 'package:flutter/cupertino.dart';

class EnsembleContext {
  EnsembleContext(Map<String, dynamic>? dataMap) {
    addDataContext(dataMap);
  }

  EnsembleContext clone() {
    EnsembleContext newContext = EnsembleContext(_dataMap);
    newContext._invokableMap.addAll(_invokableMap);
    return newContext;
  }

  // TODO: combine data nd widgets and everything else for a global context
  //Map<String, Invokable> _contextMap = {};

  // raw data (data map, api result), traversable with dot and bracket notations
  final Map<String, dynamic> _dataMap = {};
  void addDataContext(Map<String, dynamic>? data) {
    if (data != null) {
      _dataMap.addAll(data);
    }
  }
  void addDataContextById(String id, dynamic value) {
    if (value != null) {
      _dataMap[id] = value;
    }
  }

  // invokable widget, traversable with getters, setters & methods
  final Map<String, UpdatableWidget> _invokableMap = {};
  void addInvokableContext(String id, UpdatableWidget widget) {
    _invokableMap[id] = widget;
  }

  // Other Contexts:
  // - invokable (built-in methods - navigateScreen)
  // - state management



  /// evaluate single inline binding expression (getters only) e.g $(myVar.text).
  /// Note that this expects the variable to be surrounded by $(...)
  dynamic eval(dynamic expression) {
    if (expression is! String) {
      return expression;
    }

    // if just have single standalone expression, return the actual type (e.g integer)
    RegExpMatch? simpleExpression = RegExp(r'^\$\(([a-z_-\d.\[\]]+)\)$', caseSensitive: false)
        .firstMatch(expression);
    if (simpleExpression != null) {
      return evalVariable(simpleExpression.group(1)!);
    }
    // if we have multiple expressions, or mixing with text, return as String
    // greedy match anything inside a $() with letters, digits, period, square brackets.
    return expression.replaceAllMapped(RegExp(r'\$\(([a-z_-\d.\[\]]+)\)', caseSensitive: false),
            (match) => evalVariable("${match[1]}").toString());

  }

  /// evaluate Typescript code block here
  void evalCode(String codeBlock) {

  }



  /// evaluate a single variable expression e.g myVariable.value.
  /// Note: use eval() if your variable are surrounded by $(...)
  dynamic evalVariable(String variable) {
    List<String> tokens = variable.split('.');
    // look into data map first
    if (_dataMap[tokens[0]] != null) {
      return _parseToken(tokens, 0, _dataMap) ?? variable;
    }
    // then look into invokable widgets
    else if (_invokableMap[tokens[0]] != null) {
      // support getters only
      if (tokens.length == 2) {
        UpdatableWidget widget = _invokableMap[tokens[0]]!;
        if (widget.getGettableProperties().contains(tokens[1])) {
          return widget.getProperty(tokens[1]);
        }
      }
    }
    // can't resolve, return the original input
    return variable;
  }

  /// token format: result
  static dynamic _parseToken(List<String> tokens, int index, Map<String, dynamic> map) {
    if (index == tokens.length-1) {
      return map[tokens[index]];
    }
    if (map[tokens[index]] == null) {
      return null;
    }
    return _parseToken(tokens, index+1, map[tokens[index]]);
  }


}
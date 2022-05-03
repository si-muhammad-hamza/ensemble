import 'dart:async';
import 'dart:developer';

import 'package:ensemble/framework/context.dart';
import 'package:ensemble/provider.dart';
import 'package:ensemble/screen_controller.dart';
import 'package:ensemble/util/http_utils.dart';
import 'package:flutter/material.dart';
import 'package:ensemble/layout/ensemble_page_route.dart';
import 'package:yaml/yaml.dart';

class Ensemble {
  static final Ensemble _instance = Ensemble._internal();
  Ensemble._internal();
  factory Ensemble() {
    return _instance;
  }
  // Ensemble-powered App have a root page concept, so pageName is optional
  static const String ensembleRootPagePlaceholder = 'MyAppRootPage';

  bool init = false;
  String? definitionFrom;
  String? localPath;
  String? remotePath;
  String? appKey;

  /// initialize Ensemble configurations. This will be called
  /// automatically upon first page load. However call it in your existing
  /// code will enable faster load for the initial page.
  Future<void> initialize(BuildContext context) async {
    if (!init) {
      init = true;
      try {
        final yamlString = await DefaultAssetBundle.of(context)
            .loadString('ensemble-config.yaml');
        final YamlMap yamlMap = loadYaml(yamlString);

        String? definitionType = yamlMap['definitions']?['from'];
        if (definitionType == null) {
          throw ConfigError(
              "Definitions needed to be defined as 'local', 'remote', or 'ensemble'");
        }
        if (definitionType == 'local') {
          String? path = yamlMap['definitions']?['local']?['path'];
          if (path == null) {
            throw ConfigError(
                "Path to page definitions is required for Local definitions");
          }
          definitionFrom = 'local';
          localPath = path;
        } else if (definitionType == 'remote') {
          String? path = yamlMap['definitions']?['remote']?['path'];
          if (path == null) {
            throw ConfigError("Path to definitions is required for Remote definitions");
          }
          definitionFrom = 'remote';
          remotePath = path;
        } else if (definitionType == 'ensemble') {
          definitionFrom = 'ensemble';
          // appKey can be passed at decision time, so don't required it here
          appKey = yamlMap['definitions']?['ensemble']?['appKey'];
        }
      } catch (error) {
        log("Error loading ensemble-config.yaml.\n$error");
      }
    }
  }

  /// return an Ensemble page as an embeddable Widget
  /// Optionally can pass in data argument to fill any value e.g hotelName = "St Regis"
  FutureBuilder getPage(
      BuildContext context,
      String pageName, {
        Map<String, dynamic>? pageArgs
      }) {
    return FutureBuilder(
        future: getPageDefinition(context, pageName),
        builder: (context, AsyncSnapshot snapshot) => processPageDefinition(context, snapshot, pageName, pageArgs: pageArgs)
    );
  }


  Widget processPageDefinition(
      BuildContext context,
      AsyncSnapshot snapshot,
      String pageName,
      {
        Map<String, dynamic>? pageArgs
      }) {

    if (snapshot.hasError) {
      return Scaffold(
          body: Center(
              child: Text('Error loading page $pageName')
          )
      );
    } else if (!snapshot.hasData) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator()
          )
      );
    }

    // init our context with the Page arguments
    DataContext dataContext = DataContext(buildContext: context, initialMap: pageArgs);

    // load page
    if (snapshot.data['View'] != null) {
      // fetch data remotely before loading page
      String? apiName = snapshot.data['Action']?['pageload']?['api'];
      if (apiName != null) {
        YamlMap apiPayload = snapshot.data['API'][apiName];
        return FutureBuilder(
            future: HttpUtils.invokeApi(apiPayload, dataContext),
            builder: (context, AsyncSnapshot apiSnapshot) {
              if (!apiSnapshot.hasData) {
                return const Scaffold(
                    body: Center(
                        child: CircularProgressIndicator()
                    )
                );
              } else if (apiSnapshot.hasError) {
                ScreenController().onApiError(dataContext, apiPayload, apiSnapshot.error);
                return const Scaffold(
                    body: Center(
                        child: Text(
                            "Unable to retrieve data. Please check your API definition.")
                    )
                );
              }

              // update our context with API result
              dataContext.addInvokableContext(apiName, APIResponse(apiSnapshot.data));

              // render the page
              Widget page = _renderPage(context, dataContext, pageName, snapshot);

              // once page has been rendered, run the onResponse code block of the API
              ScreenController().onAPIComplete(dataContext, apiPayload, apiSnapshot.data);

              return page;
            }
        );
      } else {
        return _renderPage(context, dataContext, pageName, snapshot);
      }
    }
    // else error
    return Scaffold(
        body: Center(
            child: Text('Error loading reference page $pageName')
        )
    );
  }


  /// Navigate to an Ensemble-powered page
  void navigateToPage(
      BuildContext context,
      String pageName,
      {
        bool replace = false,
        Map<String, dynamic>? pageArgs,
      }) {

    MaterialPageRoute pageRoute = getPageRoute(pageName, pageArgs: pageArgs);
    if (replace) {
      Navigator.pushReplacement(context, pageRoute);
    } else {
      Navigator.push(context, pageRoute);
    }

  }


  /// return an Ensemble page's PageRoute, suitable to be embedded as a PageRoute
  MaterialPageRoute getPageRoute(
      String pageName,
      {
        Map<String, dynamic>? pageArgs
      }) {
    return EnsemblePageRoute(
        builder: (context) => getPage(context, pageName, pageArgs: pageArgs)
    );
  }


  /// get Page Definition from local or remote
  @protected
  Future<YamlMap> getPageDefinition(BuildContext context, String pageName) async {
    if (!init) {
      await initialize(context);
    }
    if (definitionFrom == 'local') {
      return LocalDefinitionProvider(localPath!, pageName).getDefinition();
    } else if (definitionFrom == 'remote') {
      return RemoteDefinitionProvider(remotePath!, pageName).getDefinition();
    } else {
      // throw error here if AppKey is missing for Ensemble-hosted page
      /*if (appKey == null) {
        throw ConfigError("AppKey is required for Ensemble-hosted definitions");
      }*/
      return EnsembleDefinitionProvider(appKey!, pageName).getDefinition();
    }
  }


  Widget _renderPage(
      BuildContext context,
      DataContext eContext,
      String pageName,
      AsyncSnapshot<dynamic> snapshot,
      {
        bool replace=false
      }) {
    //log ("Screen Arguments: " + args.toString());
    return ScreenController().renderPage(context, eContext, pageName, snapshot.data);
  }

}
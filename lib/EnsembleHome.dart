import 'package:ensemble/ensemble.dart';
import 'package:ensemble/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:yaml/yaml.dart';

class EnsembleHome extends StatefulWidget {
  const EnsembleHome({
    this.initialPage,
    this.pageArgs,
    Key? key
  }) : super(key: key);

  final String? initialPage;
  final Map<String, dynamic>? pageArgs;

  @override
  State<StatefulWidget> createState() => HomeState();

}

class HomeState extends State<EnsembleHome> {
  late Future<YamlMap> initialPageDefinition;

  @override
  void initState() {
    initialPageDefinition = Ensemble().getPageDefinition(context, widget.initialPage);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialPageDefinition,
      builder: (context, AsyncSnapshot snapshot) => Ensemble().processPageDefinition(
          context,
          snapshot,
          pageArgs: widget.pageArgs
      )
    );
  }


}

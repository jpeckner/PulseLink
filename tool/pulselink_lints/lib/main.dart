import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:pulselink_lints/src/keep_pigeon_imports_local.dart';
import 'package:pulselink_lints/src/no_assertions.dart';
import 'package:pulselink_lints/src/no_catch_all_cases.dart';
import 'package:pulselink_lints/src/no_dynamic.dart';
import 'package:pulselink_lints/src/no_ignored_results.dart';
import 'package:pulselink_lints/src/use_switch_on_closed_types.dart';

/// The entry point the analysis server looks for.
final plugin = PulseLinkLintsPlugin();

/// PulseLink's own lint rules, for checks no built-in lint covers.
///
/// Rules are registered as lints, so each one is off until it's enabled
/// under `plugins: pulselink_lints: diagnostics:` in analysis_options.yaml.
class PulseLinkLintsPlugin extends Plugin {
  @override
  String get name => 'pulselink_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(KeepPigeonImportsLocal())
      ..registerLintRule(NoAssertions())
      ..registerLintRule(NoCatchAllCases())
      ..registerLintRule(NoDynamic())
      ..registerLintRule(NoIgnoredResults())
      ..registerLintRule(UseSwitchOnClosedTypes());
  }
}

import 'dart:io';

import '../../domain/feature.dart';
import '../../domain/feature_files.dart';
import '../../domain/shared_files.dart';
import '../../domain/step_snippet.dart';
import '../../domain/steps_class.dart';
import '../../domain/undefined_step_hint.dart';
import '../../domain/unresolved_reason.dart';
import '../../domain/unresolved_step.dart';
import '../../infrastructure/builders/snippet_code.dart';
import '../../infrastructure/steps/snippet_generator.dart';
import '../../infrastructure/steps/step_matcher.dart';

/// Collects the undefined steps of every feature in a build and turns them
/// into hints: one per step definition to write, with the class to add it
/// to and a snippet.
///
/// Like Cucumber, it only suggests; it never writes to a steps file. A step
/// used by one feature goes in that feature's class; a step used by several,
/// or defined in another feature's class, goes in the shared steps mixin.
class UndefinedSteps {
  final SharedFiles _sharedFiles;
  final StepsClass? _shared;
  final List<_FeatureSteps> _features = [];

  /// Set-up steps already given in an earlier hint, said only once.
  final Set<String> _said = {};

  UndefinedSteps(this._sharedFiles, this._shared);

  /// Records the steps [unresolved] of the feature [files], whose steps
  /// class is [own].
  void add(FeatureFiles files, StepsClass? own, List<UnresolvedStep> unresolved) {
    final undefined = unresolved.where((u) => u.reason == UnresolvedReason.undefined).toList();
    _features.add(_FeatureSteps(files, own, undefined));
  }

  /// One hint per step definition to write, in the order the steps were
  /// first seen.
  List<UndefinedStepHint> hints() {
    _said.clear();
    final groups = _group();
    final namer = _MethodNamer();
    return [for (final group in groups) _hint(group, namer)];
  }

  /// Groups the steps one method can serve, keyed by the snippet built with
  /// the types every feature can see.
  List<_Group> _group() {
    final generator = SnippetGenerator.build(_shared?.parameterTypes ?? const []);
    final groups = <String, _Group>{};
    for (final feature in _features) {
      for (final step in feature.undefined) {
        final snippet = generator.snippetFor(step);
        groups.putIfAbsent(snippet.key, () => _Group(snippet, step)).add(feature);
      }
    }
    return groups.values.toList();
  }

  UndefinedStepHint _hint(_Group group, _MethodNamer namer) {
    final definedIn = _definedElsewhere(group);
    final useShared = group.features.length > 1 || definedIn.isNotEmpty;
    final featureNames = group.features.map((f) => '${f.files.feature.fileName}.feature').join(', ');
    final warning = 'undefined step `${group.step.step.keyword} ${group.step.text}` in $featureNames.';
    if (!useShared) return _ownHint(warning, group, namer);
    return _sharedHint(warning, group, definedIn, namer);
  }

  UndefinedStepHint _ownHint(String warning, _Group group, _MethodNamer namer) {
    final feature = group.features.single;
    final types = [...?feature.own?.parameterTypes, ...?_shared?.parameterTypes];
    final snippet = SnippetGenerator.build(types).snippetFor(group.step);
    final className = feature.files.stepsClass;
    return UndefinedStepHint(warning, [
      'Add to $className in ${feature.files.stepsPath}:',
      ..._code(snippet, namer.name(className, feature.own, snippet.methodName)),
    ]);
  }

  UndefinedStepHint _sharedHint(String warning, _Group group, List<_FeatureSteps> definedIn, _MethodNamer namer) {
    final mixinName = _sharedFiles.mixinName;
    final users = [...group.features, ...definedIn];
    final withoutMixin = users.where((f) => f.own != null && !f.own!.mixins.contains(mixinName));
    final setUp = [if (_shared == null) _createMixin(mixinName), for (final f in withoutMixin) _mixIn(f, mixinName)];
    return UndefinedStepHint(warning, [
      for (final f in definedIn)
        '${f.files.stepsClass} defines it, but only ${f.files.feature.fileName}.feature can use it; move it to $mixinName.',
      'Add to $mixinName in ${_sharedFiles.stepsPath}:',
      ...setUp.where(_said.add),
      ..._code(group.snippet, namer.name(mixinName, _shared, group.snippet.methodName)),
    ]);
  }

  String _mixIn(_FeatureSteps feature, String mixinName) {
    final import = SharedFiles.relativeImport(feature.files.stepsPath, _sharedFiles.stepsPath);
    return "Add `with $mixinName` to ${feature.files.stepsClass} in ${feature.files.stepsPath}, "
        "with `import '$import';`.";
  }

  String _createMixin(String mixinName) {
    final path = _sharedFiles.stepsPath;
    if (File(path).existsSync()) return 'Declare `mixin $mixinName {}` in $path.';
    return "Create $path with `import 'package:bdd_flutter/bdd_flutter.dart';` and `mixin $mixinName {}`.";
  }

  /// The features outside [group] whose own class defines its step, which
  /// the features of [group] cannot call.
  List<_FeatureSteps> _definedElsewhere(_Group group) {
    final text = group.step.text;
    return [
      for (final feature in _features)
        if (!group.features.contains(feature) && feature.own != null && !feature.matcher.match(text).isUndefined)
          feature,
    ];
  }

  List<String> _code(StepSnippet snippet, String methodName) {
    return ['', for (final line in snippetCode(snippet, methodName)) '  $line', ''];
  }
}

/// One feature's steps class and its undefined steps.
class _FeatureSteps {
  final FeatureFiles files;
  final StepsClass? own;
  final List<UnresolvedStep> undefined;
  StepMatcher? _matcher;

  _FeatureSteps(this.files, this.own, this.undefined);

  /// A matcher over [own] alone, built on first use.
  StepMatcher get matcher => _matcher ??= StepMatcher.build(own: own);
}

/// Undefined steps one method can serve, and the features that use them.
class _Group {
  final StepSnippet snippet;

  /// The first step seen, shown in the warning.
  final UnresolvedStep step;
  final List<_FeatureSteps> features = [];

  _Group(this.snippet, this.step);

  void add(_FeatureSteps feature) {
    if (!features.contains(feature)) features.add(feature);
  }
}

/// Gives snippets method names not yet taken in their class, by its
/// existing members or by earlier snippets.
class _MethodNamer {
  final Map<String, Set<String>> _taken = {};

  String name(String className, StepsClass? existing, String base) {
    final taken = _taken.putIfAbsent(className, () => _members(existing));
    var candidate = base;
    for (var i = 2; !taken.add(candidate); i++) {
      candidate = '$base$i';
    }
    return candidate;
  }

  static Set<String> _members(StepsClass? existing) {
    if (existing == null) return {};
    return {
      ...existing.steps.map((d) => d.methodName),
      ...existing.hooks.map((h) => h.methodName),
      ...existing.parameterTypes.map((t) => t.methodName),
    };
  }
}

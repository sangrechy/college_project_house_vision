import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/design_component.dart';
import '../../domain/models/project_model.dart';
import '../../domain/repositories/project_repository.dart';

class HomeownerViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  StreamSubscription? _projectSub;
  StreamSubscription? _designSub;

  ProjectModel _project = ProjectModel.defaultProject();
  DesignComponent _latestDesign = DesignComponent.initial();
  bool _isLoading = false;

  HomeownerViewModel({required this._projectRepository}) {
    _initStreams();
  }

  ProjectModel get project => _project;
  DesignComponent get latestDesign => _latestDesign;
  bool get isLoading => _isLoading;

  void _initStreams() {
    _projectSub = _projectRepository.streamProject(AppStrings.defaultProjectId).listen((p) {
      _project = p;
      notifyListeners();
    });

    _designSub = _projectRepository.streamLatestDesign(AppStrings.defaultProjectId).listen((d) {
      _latestDesign = d;
      notifyListeners();
    });
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _project = await _projectRepository.getProject(AppStrings.defaultProjectId);
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _projectSub?.cancel();
    _designSub?.cancel();
    super.dispose();
  }
}

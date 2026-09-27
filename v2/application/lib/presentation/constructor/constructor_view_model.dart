import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/models/design_component.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/verification_item.dart';
import '../../domain/repositories/project_repository.dart';

class ConstructorViewModel extends ChangeNotifier {
  final ProjectRepository _projectRepository;
  StreamSubscription? _projectSub;
  StreamSubscription? _designSub;

  ProjectModel _project = ProjectModel.defaultProject();
  DesignComponent _latestDesign = DesignComponent.initial();
  List<VerificationItem> _verificationItems = [];
  bool _hasUnreadDesignUpdate = true;
  bool _isLoading = false;

  ConstructorViewModel({required this._projectRepository}) {
    _init();
  }

  ProjectModel get project => _project;
  DesignComponent get latestDesign => _latestDesign;
  List<VerificationItem> get verificationItems => _verificationItems;
  bool get hasUnreadDesignUpdate => _hasUnreadDesignUpdate;
  bool get isLoading => _isLoading;

  void _init() {
    _projectSub = _projectRepository.streamProject(AppStrings.defaultProjectId).listen((p) {
      _project = p;
      notifyListeners();
    });

    _designSub = _projectRepository.streamLatestDesign(AppStrings.defaultProjectId).listen((d) {
      _latestDesign = d;
      _hasUnreadDesignUpdate = true;
      notifyListeners();
    });

    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    _verificationItems = await _projectRepository.getVerificationItems(AppStrings.defaultProjectId);
    notifyListeners();
  }

  void acknowledgeDesignUpdate() {
    _hasUnreadDesignUpdate = false;
    notifyListeners();
  }

  Future<void> updateProgress(double progress) async {
    await _projectRepository.updateProgress(AppStrings.defaultProjectId, progress);
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _project = await _projectRepository.getProject(AppStrings.defaultProjectId);
    await _loadVerifications();
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

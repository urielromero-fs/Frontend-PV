import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  //Initialize user data on login
  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  //Complete onboarding step and check if all steps are completed
  void completeOnboardingStep(String step) {
    if (_user == null) return;

    _user!['onboarding']['stepsCompleted'][step] = true;

    notifyListeners();
  }
}
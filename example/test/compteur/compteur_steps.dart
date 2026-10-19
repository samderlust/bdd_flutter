import 'package:flutter_test/flutter_test.dart';

import 'compteur.bdd_steps.dart';

/// The steps of the feature "Compteur".
class CompteurSteps implements CompteurStepsContract {
  int compteur = 0;

  @override
  Future<void> unCompteurA(num number) async {
    compteur = number.toInt();
  }

  @override
  Future<void> jincrementeLeCompteur() async {
    compteur++;
  }

  @override
  Future<void> leCompteurVaut(num number) async {
    expect(compteur, number);
  }
}

import 'package:flutter_test/flutter_test.dart';

class IncrMenterScenario {
  int compteur = 0;

  Future<void> unCompteur0() async {
    compteur = 0;
  }

  Future<void> jIncrMenteLeCompteur() async {
    compteur++;
  }

  Future<void> leCompteurVaut1() async {
    expect(compteur, 1);
  }

}

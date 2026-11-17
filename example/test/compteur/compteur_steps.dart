import 'package:bdd_flutter/bdd_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The steps of the feature "Compteur".
class CompteurSteps {
  int compteur = 0;

  @Given('un compteur à {num}')
  Future<void> unCompteurA(num number) async {
    compteur = number.toInt();
  }

  @When("j'incrémente le compteur")
  Future<void> jincrementeLeCompteur() async {
    compteur++;
  }

  @Then('le compteur vaut {num}')
  Future<void> leCompteurVaut(num number) async {
    expect(compteur, number);
  }
}

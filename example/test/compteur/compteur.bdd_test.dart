import 'package:flutter_test/flutter_test.dart';
import 'compteur.bdd_scenarios.dart';

void main() {
  group('Compteur', () {
    test('Incrémenter', () async {
      final scenario = IncrMenterScenario();
      //Scenario: Incrémenter
      // Soit un compteur à 0
      await scenario.unCompteur0();
      // Quand j'incrémente le compteur
      await scenario.jIncrMenteLeCompteur();
      // Alors le compteur vaut 1
      await scenario.leCompteurVaut1();
    });
  });
}

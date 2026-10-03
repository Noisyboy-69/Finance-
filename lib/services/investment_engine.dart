
import '../models/models.dart';

class InvestmentEngine {
  static List<InvestmentAnalysis> analyze(List<InvestmentPosition> positions) {
    final total = positions.fold(0.0, (s,p) => s + p.currentValue);
    return positions.map((p) {
      final weight = total == 0 ? 0.0 : p.currentValue / total * 100;
      final risk = switch (p.type) {
        InvestmentType.crypto => 'Alto',
        InvestmentType.stock => 'Medio-alto',
        InvestmentType.etf => 'Medio',
        InvestmentType.other => 'Variabile',
      };
      final trend = p.gainPercent > 5 ? 'Positivo' : p.gainPercent < -5 ? 'Negativo' : 'Laterale';
      final risks = <String>[
        if (weight > 40) 'Concentrazione elevata',
        if (p.type == InvestmentType.crypto) 'Volatilità elevata',
      ];
      final scenarios = <String>[
        'Positivo: crescita del valore se il mercato di riferimento resta favorevole.',
        'Neutro: andamento laterale con mantenimento della posizione.',
        'Negativo: correzione del mercato e riduzione temporanea del valore.',
      ];
      return InvestmentAnalysis(
        position:p, weight:weight, risk:risk, trend:trend,
        summary:'Lettura descrittiva dei dati inseriti: non è una previsione garantita e non esegue ordini.',
        scenarios:scenarios, risks:risks,
      );
    }).toList();
  }
}

import '../models/contrato.dart';
import '../supabase_client.dart';

class ContratosRepository {
  Future<List<Contrato>> listarPorImovel(String imovelId) async {
    final rows = await supabase
        .from('contratos')
        .select()
        .eq('imovel_id', imovelId)
        .order('data_inicio', ascending: false);
    return rows.map(Contrato.fromMap).toList();
  }

  Future<void> criar(Contrato contrato) async {
    await supabase.from('contratos').insert(contrato.toMap());
  }

  /// Encerra o contrato; se não tinha data de fim, usa hoje.
  Future<void> encerrar(Contrato contrato) async {
    final hoje = DateTime.now().toIso8601String().substring(0, 10);
    await supabase.from('contratos').update({
      'status': 'encerrado',
      if (contrato.dataFim == null) 'data_fim': hoje,
    }).eq('id', contrato.id!);
  }
}

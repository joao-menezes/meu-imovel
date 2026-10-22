import '../models/imovel.dart';
import '../supabase_client.dart';

class ImoveisRepository {
  Future<List<Imovel>> listar() async {
    final rows = await supabase.from('imoveis').select().order('apelido');
    return rows.map(Imovel.fromMap).toList();
  }

  Future<Imovel> buscar(String id) async {
    final row = await supabase.from('imoveis').select().eq('id', id).single();
    return Imovel.fromMap(row);
  }

  Future<void> salvar(Imovel imovel) async {
    if (imovel.id == null) {
      await supabase.from('imoveis').insert(imovel.toMap());
    } else {
      await supabase.from('imoveis').update(imovel.toMap()).eq('id', imovel.id!);
    }
  }

  Future<void> excluir(String id) async {
    await supabase.from('imoveis').delete().eq('id', id);
  }
}

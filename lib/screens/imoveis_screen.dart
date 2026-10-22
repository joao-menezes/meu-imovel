import 'package:flutter/material.dart';

import '../data/imoveis_repository.dart';
import '../models/imovel.dart';
import '../supabase_client.dart';
import 'imovel_detail_screen.dart';
import 'imovel_form_screen.dart';

class ImoveisScreen extends StatefulWidget {
  const ImoveisScreen({super.key});

  @override
  State<ImoveisScreen> createState() => _ImoveisScreenState();
}

class _ImoveisScreenState extends State<ImoveisScreen> {
  final _repo = ImoveisRepository();
  late Future<List<Imovel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listar();
  }

  Future<void> _recarregar() async {
    setState(() => _future = _repo.listar());
    await _future;
  }

  Future<void> _abrir(Widget tela) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus imóveis'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(const ImovelFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Imóvel'),
      ),
      body: FutureBuilder<List<Imovel>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Mensagem(
              icone: Icons.error_outline,
              texto: 'Não foi possível carregar os imóveis.',
              acao: TextButton(
                  onPressed: _recarregar, child: const Text('Tentar de novo')),
            );
          }
          final imoveis = snap.data!;
          if (imoveis.isEmpty) {
            return const _Mensagem(
              icone: Icons.home_outlined,
              texto: 'Nenhum imóvel ainda.\nToque em "+ Imóvel" para começar.',
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: imoveis.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final im = imoveis[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: Text(im.apelido),
                    subtitle: Text('${im.tipo.label} · ${im.endereco}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrir(ImovelDetailScreen(imovelId: im.id!)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.icone, required this.texto, this.acao});
  final IconData icone;
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
            if (acao != null) acao!,
          ],
        ),
      ),
    );
  }
}

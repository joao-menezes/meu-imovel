import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/contratos_repository.dart';
import '../data/imoveis_repository.dart';
import '../models/contrato.dart';
import '../models/imovel.dart';
import 'contrato_form_screen.dart';
import 'imovel_form_screen.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _data = DateFormat('dd/MM/yyyy');

class ImovelDetailScreen extends StatefulWidget {
  const ImovelDetailScreen({super.key, required this.imovelId});
  final String imovelId;

  @override
  State<ImovelDetailScreen> createState() => _ImovelDetailScreenState();
}

class _ImovelDetailScreenState extends State<ImovelDetailScreen> {
  final _imoveis = ImoveisRepository();
  final _contratos = ContratosRepository();
  late Future<(Imovel, List<Contrato>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<(Imovel, List<Contrato>)> _carregar() async {
    final r = await Future.wait([
      _imoveis.buscar(widget.imovelId),
      _contratos.listarPorImovel(widget.imovelId),
    ]);
    return (r[0] as Imovel, r[1] as List<Contrato>);
  }

  void _recarregar() => setState(() => _future = _carregar());

  Future<void> _editar(Imovel imovel) async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ImovelFormScreen(imovel: imovel)));
    if (mounted) _recarregar();
  }

  Future<void> _excluir(Imovel imovel) async {
    final ok = await _confirmar(
      'Excluir imóvel?',
      '"${imovel.apelido}" e todos os contratos dele serão apagados.',
      'Excluir',
    );
    if (!ok) return;
    await _imoveis.excluir(imovel.id!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _novoContrato(Imovel imovel) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ContratoFormScreen(imovelId: imovel.id!)));
    if (mounted) _recarregar();
  }

  Future<void> _encerrar(Contrato c) async {
    final ok = await _confirmar(
      'Encerrar contrato?',
      'O contrato de ${c.inquilinoNome} vai para o histórico.',
      'Encerrar',
    );
    if (!ok) return;
    await _contratos.encerrar(c);
    if (mounted) _recarregar();
  }

  Future<bool> _confirmar(String titulo, String texto, String acao) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(acao)),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Imovel, List<Contrato>)>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: TextButton(
                  onPressed: _recarregar,
                  child: const Text('Erro ao carregar. Tentar de novo')),
            ),
          );
        }
        final (imovel, contratos) = snap.data!;
        final ativos = contratos.where((c) => c.ativo);
        final ativo = ativos.isEmpty ? null : ativos.first;
        final historico = contratos.where((c) => !c.ativo).toList();
        final tema = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(imovel.apelido),
            actions: [
              IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editar(imovel)),
              IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _excluir(imovel)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${imovel.tipo.label} · ${imovel.endereco}',
                  style: tema.textTheme.bodyLarge),
              if (imovel.observacoes != null) ...[
                const SizedBox(height: 8),
                Text(imovel.observacoes!, style: tema.textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              Text('Contrato atual', style: tema.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (ativo == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Imóvel sem contrato ativo.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _novoContrato(imovel),
                          icon: const Icon(Icons.add),
                          label: const Text('Novo contrato'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _ContratoCard(
                    contrato: ativo, onEncerrar: () => _encerrar(ativo)),
              if (historico.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Histórico', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final c in historico) _ContratoCard(contrato: c),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ContratoCard extends StatelessWidget {
  const _ContratoCard({required this.contrato, this.onEncerrar});
  final Contrato contrato;
  final VoidCallback? onEncerrar;

  @override
  Widget build(BuildContext context) {
    final c = contrato;
    final periodo = c.dataFim == null
        ? 'Desde ${_data.format(c.dataInicio)}'
        : '${_data.format(c.dataInicio)} – ${_data.format(c.dataFim!)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.inquilinoNome,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('${_moeda.format(c.valorAluguel)} · vence dia ${c.diaVencimento}'),
            Text(periodo),
            if (c.inquilinoTelefone != null) Text(c.inquilinoTelefone!),
            if (c.inquilinoEmail != null) Text(c.inquilinoEmail!),
            if (onEncerrar != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: onEncerrar,
                    child: const Text('Encerrar contrato')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

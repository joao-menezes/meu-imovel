import 'package:flutter/material.dart';

import '../data/imoveis_repository.dart';
import '../models/imovel.dart';

/// Cadastro e edição de imóvel. Passe [imovel] para editar.
class ImovelFormScreen extends StatefulWidget {
  const ImovelFormScreen({super.key, this.imovel});
  final Imovel? imovel;

  @override
  State<ImovelFormScreen> createState() => _ImovelFormScreenState();
}

class _ImovelFormScreenState extends State<ImovelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ImoveisRepository();
  late final _apelido = TextEditingController(text: widget.imovel?.apelido);
  late final _endereco = TextEditingController(text: widget.imovel?.endereco);
  late final _obs = TextEditingController(text: widget.imovel?.observacoes);
  late TipoImovel _tipo = widget.imovel?.tipo ?? TipoImovel.casa;
  bool _salvando = false;

  bool get _editando => widget.imovel != null;

  @override
  void dispose() {
    _apelido.dispose();
    _endereco.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await _repo.salvar(Imovel(
        id: widget.imovel?.id,
        apelido: _apelido.text.trim(),
        endereco: _endereco.text.trim(),
        tipo: _tipo,
        observacoes: _obs.text.trim().isEmpty ? null : _obs.text.trim(),
      ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar o imóvel.')));
    }
  }

  String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar imóvel' : 'Novo imóvel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _apelido,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Apelido',
                hintText: 'Ex.: Apto Centro, Casa da Rua 7',
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endereco,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Endereço'),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TipoImovel>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final t in TipoImovel.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (t) => setState(() => _tipo = t ?? _tipo),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _obs,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando…' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/contratos_repository.dart';
import '../models/contrato.dart';

final _fmtData = DateFormat('dd/MM/yyyy');

class ContratoFormScreen extends StatefulWidget {
  const ContratoFormScreen({super.key, required this.imovelId});
  final String imovelId;

  @override
  State<ContratoFormScreen> createState() => _ContratoFormScreenState();
}

class _ContratoFormScreenState extends State<ContratoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ContratosRepository();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _valor = TextEditingController();
  final _dia = TextEditingController(text: '10');
  DateTime _inicio = DateTime.now();
  DateTime? _fim;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_nome, _telefone, _email, _valor, _dia]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Aceita "1500", "1500.50", "1.500,50" e "1500,50".
  double? _parseValor(String s) {
    s = s.trim();
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  Future<void> _escolherData({required bool inicio}) async {
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : (_fim ?? _inicio),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (inicio) {
        _inicio = d;
      } else {
        _fim = d;
      }
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fim != null && _fim!.isBefore(_inicio)) {
      _erro('A data de fim não pode ser antes do início.');
      return;
    }
    setState(() => _salvando = true);
    String? opcional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    try {
      await _repo.criar(Contrato(
        imovelId: widget.imovelId,
        inquilinoNome: _nome.text.trim(),
        inquilinoTelefone: opcional(_telefone),
        inquilinoEmail: opcional(_email),
        valorAluguel: _parseValor(_valor.text)!,
        diaVencimento: int.parse(_dia.text),
        dataInicio: _inicio,
        dataFim: _fim,
      ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _erro('Erro ao salvar o contrato.');
    }
  }

  void _erro(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo contrato')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Inquilino', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 24),
            Text('Aluguel', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _valor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Valor', prefixText: r'R$ '),
                    validator: (v) {
                      final n = _parseValor(v ?? '');
                      return (n == null || n <= 0) ? 'Valor inválido' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dia,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Dia do vencimento'),
                    validator: (v) {
                      final d = int.tryParse(v ?? '');
                      return (d == null || d < 1 || d > 31) ? '1 a 31' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CampoData(
              label: 'Início',
              valor: _fmtData.format(_inicio),
              onTap: () => _escolherData(inicio: true),
            ),
            const SizedBox(height: 16),
            _CampoData(
              label: 'Fim (opcional)',
              valor: _fim == null ? 'Indeterminado' : _fmtData.format(_fim!),
              onTap: () => _escolherData(inicio: false),
              onLimpar: _fim == null ? null : () => setState(() => _fim = null),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _salvando ? null : _salvar,
              child: Text(_salvando ? 'Salvando…' : 'Salvar contrato'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoData extends StatelessWidget {
  const _CampoData(
      {required this.label,
      required this.valor,
      required this.onTap,
      this.onLimpar});
  final String label;
  final String valor;
  final VoidCallback onTap;
  final VoidCallback? onLimpar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onLimpar == null
              ? const Icon(Icons.calendar_today_outlined)
              : IconButton(icon: const Icon(Icons.close), onPressed: onLimpar),
        ),
        child: Text(valor),
      ),
    );
  }
}

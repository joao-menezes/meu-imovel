class Contrato {
  final String? id;
  final String imovelId;
  final String inquilinoNome;
  final String? inquilinoTelefone;
  final String? inquilinoEmail;
  final double valorAluguel;
  final int diaVencimento;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final bool ativo;

  const Contrato({
    this.id,
    required this.imovelId,
    required this.inquilinoNome,
    this.inquilinoTelefone,
    this.inquilinoEmail,
    required this.valorAluguel,
    required this.diaVencimento,
    required this.dataInicio,
    this.dataFim,
    this.ativo = true,
  });

  factory Contrato.fromMap(Map<String, dynamic> m) => Contrato(
        id: m['id'] as String,
        imovelId: m['imovel_id'] as String,
        inquilinoNome: m['inquilino_nome'] as String,
        inquilinoTelefone: m['inquilino_telefone'] as String?,
        inquilinoEmail: m['inquilino_email'] as String?,
        valorAluguel: (m['valor_aluguel'] as num).toDouble(),
        diaVencimento: m['dia_vencimento'] as int,
        dataInicio: DateTime.parse(m['data_inicio'] as String),
        dataFim: m['data_fim'] == null
            ? null
            : DateTime.parse(m['data_fim'] as String),
        ativo: m['status'] == 'ativo',
      );

  Map<String, dynamic> toMap() => {
        'imovel_id': imovelId,
        'inquilino_nome': inquilinoNome,
        'inquilino_telefone': inquilinoTelefone,
        'inquilino_email': inquilinoEmail,
        'valor_aluguel': valorAluguel,
        'dia_vencimento': diaVencimento,
        'data_inicio': _date(dataInicio),
        'data_fim': dataFim == null ? null : _date(dataFim!),
        'status': ativo ? 'ativo' : 'encerrado',
      };

  static String _date(DateTime d) => d.toIso8601String().substring(0, 10);
}

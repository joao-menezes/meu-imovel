enum TipoImovel {
  casa('Casa'),
  apartamento('Apartamento'),
  comercial('Comercial'),
  outro('Outro');

  const TipoImovel(this.label);
  final String label;

  static TipoImovel fromName(String? name) => TipoImovel.values.firstWhere(
        (t) => t.name == name,
        orElse: () => TipoImovel.outro,
      );
}

class Imovel {
  final String? id;
  final String apelido;
  final String endereco;
  final TipoImovel tipo;
  final String? observacoes;

  const Imovel({
    this.id,
    required this.apelido,
    required this.endereco,
    this.tipo = TipoImovel.casa,
    this.observacoes,
  });

  factory Imovel.fromMap(Map<String, dynamic> m) => Imovel(
        id: m['id'] as String,
        apelido: m['apelido'] as String,
        endereco: m['endereco'] as String,
        tipo: TipoImovel.fromName(m['tipo'] as String?),
        observacoes: m['observacoes'] as String?,
      );

  /// owner_id é preenchido pelo banco (default auth.uid()).
  Map<String, dynamic> toMap() => {
        'apelido': apelido,
        'endereco': endereco,
        'tipo': tipo.name,
        'observacoes': observacoes,
      };
}

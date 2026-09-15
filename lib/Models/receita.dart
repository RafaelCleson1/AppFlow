class Receita {
  final int? id;
  final String titulo;
  final String ingredientes;
  final String preparo;
  final List<String> fotos;

  const Receita({
    this.id,
    required this.titulo,
    required this.ingredientes,
    required this.preparo,
    this.fotos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'ingredientes': ingredientes,
      'preparo': preparo,
      if (fotos.isNotEmpty) 'fotos': fotos,
    };
  }

  factory Receita.fromMap(Map<String, dynamic> map) {
    final fotosBruto = map['fotos'];

    return Receita(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      ingredientes: map['ingredientes'] as String,
      preparo: map['preparo'] as String,
      fotos: fotosBruto == null
          ? const []
          : (fotosBruto as List).cast<String>(),
    );
  }
}
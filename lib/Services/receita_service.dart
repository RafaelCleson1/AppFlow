import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../Models/receita.dart';

class ReceitaService {
  static const String _bucketFotos = 'receitas';

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> criarReceita(Receita receita) async {
    await supabase.from('receitas').insert(receita.toMap());
  }

  Future<List<Receita>> buscarReceitas() async {
    final response = await supabase.from('receitas').select();

    return response.map<Receita>((item) => Receita.fromMap(item)).toList();
  }

  Future<void> atualizarReceita(Receita receita) async {
    await supabase
        .from('receitas')
        .update(receita.toMap())
        .eq('id', receita.id!);
  }

  Future<void> excluirReceita(int id) async {
    await supabase.from('receitas').delete().eq('id', id);
  }

  Future<String> subirFoto({
    required String nome,
    required Uint8List bytes,
  }) async {
    final caminho =
        'projeto_${DateTime.now().millisecondsSinceEpoch}_$nome';

    await supabase.storage.from(_bucketFotos).uploadBinary(caminho, bytes);

    return caminho;
  }

  String urlDaFoto(String caminho) {
    return supabase.storage.from(_bucketFotos).getPublicUrl(caminho);
  }
}
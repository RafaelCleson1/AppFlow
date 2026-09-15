import 'package:flutter/material.dart';

import '../Models/receita.dart';
import '../Services/receita_service.dart';
import 'cadastro_receita.dart';
import 'detalhe_receita.dart';

class HomePage extends StatefulWidget {
  final Future<List<Receita>> Function()? buscar;

  const HomePage({super.key, this.buscar});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _buscaController = TextEditingController();

  ReceitaService? _service;
  late Future<List<Receita>> _receitas;
  String _filtro = '';

  @override
  void initState() {
    super.initState();

    _receitas = _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();

    super.dispose();
  }

  ReceitaService _servico() => _service ??= ReceitaService();

  Future<List<Receita>> _carregar() {
    final buscar = widget.buscar;
    if (buscar != null) return buscar();

    return _servico().buscarReceitas();
  }

  Future<void> _atualizar() async {
    final future = _carregar();

    setState(() {
      _receitas = future;
    });

    try {
      await future;
    } catch (_) {
      // O erro é exibido pelo FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Receitas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _buscaController,
              onChanged: (valor) => setState(() {
                _filtro = valor.trim().toLowerCase();
              }),
              decoration: InputDecoration(
                hintText: 'Buscar receitas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtro.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscaController.clear();
                          setState(() => _filtro = '');
                        },
                      ),
                filled: true,
                isDense: true,
              ),
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<Receita>>(
        future: _receitas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Erro ao carregar receitas:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _atualizar,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final receitas = snapshot.data ?? <Receita>[];

          if (receitas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma receita cadastrada',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final filtradas = _filtro.isEmpty
              ? receitas
              : receitas
                  .where(
                    (receita) =>
                        receita.titulo.toLowerCase().contains(_filtro),
                  )
                  .toList();

          if (filtradas.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma receita encontrada',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _atualizar,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtradas.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final receita = filtradas[index];

                return ListTile(
                  leading: receita.fotos.isEmpty
                      ? const Icon(Icons.restaurant_menu)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _servico().urlDaFoto(receita.fotos.first),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                  title: Text(receita.titulo),
                  subtitle: Text(receita.ingredientes),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetalheReceita(receita: receita),
                      ),
                    );

                    if (mounted) _atualizar();
                  },
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroReceita()),
          );

          if (mounted) _atualizar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
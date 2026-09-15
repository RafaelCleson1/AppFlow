import 'package:flutter/material.dart';

import '../Models/receita.dart';
import '../Services/receita_service.dart';
import 'cadastro_receita.dart';

class DetalheReceita extends StatefulWidget {
  final Receita receita;

  const DetalheReceita({super.key, required this.receita});

  @override
  State<DetalheReceita> createState() => _DetalheReceitaState();
}

class _DetalheReceitaState extends State<DetalheReceita> {
  late Receita _receita;

  ReceitaService? _service;
  bool _excluindo = false;
  int _indiceFoto = 0;

  ReceitaService get _receitaService => _service ??= ReceitaService();

  @override
  void initState() {
    super.initState();

    _receita = widget.receita;
  }

  List<String> _linhas(String texto) => texto
      .split('\n')
      .map((linha) => linha.trim())
      .where((linha) => linha.isNotEmpty)
      .toList();

  Future<void> _editar() async {
    final atualizada = await Navigator.push<Receita>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroReceita(receita: _receita),
      ),
    );

    if (atualizada != null && mounted) {
      setState(() {
        _receita = atualizada;
        _indiceFoto = 0;
      });
    }
  }

  Future<void> _excluir() async {
    final id = _receita.id;
    if (id == null) {
      _mostrarErro('Receita sem identificador válido.');
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir receita'),
        content: Text('Tem certeza que deseja excluir "${_receita.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _excluindo = true);

    try {
      await _receitaService.excluirReceita(id);

      messenger.showSnackBar(
        const SnackBar(content: Text('Receita excluída!')),
      );

      navigator.pop();
    } catch (erro) {
      debugPrint('ERRO: $erro');

      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $erro')),
      );

      if (mounted) setState(() => _excluindo = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_receita.titulo),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (opcao) {
              switch (opcao) {
                case 'editar':
                  _editar();
                case 'excluir':
                  _excluir();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Excluir'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: _excluindo
          ? const Center(child: CircularProgressIndicator())
          : _conteudo(),
    );
  }

  Widget _galeriaFotos() {
    final fotos = _receita.fotos;

    if (fotos.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFB74D),
              Color(0xFFFF7043),
              Color(0xFFE53935),
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 56, color: Colors.white70),
            SizedBox(height: 8),
            Text(
              'Adicione fotos da sua receita',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: fotos.length,
              onPageChanged: (indice) =>
                  setState(() => _indiceFoto = indice),
              itemBuilder: (context, indice) => Image.network(
                _receitaService.urlDaFoto(fotos[indice]),
                fit: BoxFit.cover,
                loadingBuilder: (context, filho, progresso) {
                  if (progresso == null) return filho;

                  return const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black12,
                  child: Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_indiceFoto + 1}/${fotos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < fotos.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _indiceFoto ? 18 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final tema = Theme.of(context);
    final ingredientes = _linhas(_receita.ingredientes);
    final preparo = _linhas(_receita.preparo);

    Widget tituloSecao(String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            texto,
            style: tema.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        );

    Widget card(List<Widget> filhos) => Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: filhos,
            ),
          ),
        );

    Widget ponto(String texto) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(texto, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );

    Widget passo(int indice, String texto) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: tema.colorScheme.primary,
                foregroundColor: tema.colorScheme.onPrimary,
                child: Text('$indice', style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child:
                      Text(texto, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _galeriaFotos(),
        const SizedBox(height: 16),
        card([
          tituloSecao('Ingredientes'),
          if (ingredientes.isEmpty)
            const Text('Sem ingredientes informados.')
          else
            ...ingredientes.map(ponto),
        ]),
        const SizedBox(height: 16),
        card([
          tituloSecao('Modo de preparo'),
          if (preparo.isEmpty)
            const Text('Sem modo de preparo informado.')
          else
            ...preparo.asMap().entries.map(
                  (entrada) => passo(entrada.key + 1, entrada.value),
                ),
        ]),
      ],
    );
  }
}
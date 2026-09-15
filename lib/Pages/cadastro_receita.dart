import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Models/receita.dart';
import '../Services/receita_service.dart';

class CadastroReceita extends StatefulWidget {
  final Receita? receita;

  const CadastroReceita({super.key, this.receita});

  @override
  State<CadastroReceita> createState() => _CadastroReceitaState();
}

class _CadastroReceitaState extends State<CadastroReceita> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController tituloController;
  late final TextEditingController ingredientesController;
  late final TextEditingController preparoController;

  final ReceitaService receitaService = ReceitaService();
  final ImagePicker _picker = ImagePicker();

  final List<XFile> _novasFotos = [];
  final List<String> _fotosExistentes = [];

  bool _salvando = false;

  bool get _editando => widget.receita != null;

  @override
  void initState() {
    super.initState();

    final receita = widget.receita;

    tituloController = TextEditingController(text: receita?.titulo);
    ingredientesController = TextEditingController(text: receita?.ingredientes);
    preparoController = TextEditingController(text: receita?.preparo);

    if (receita != null) _fotosExistentes.addAll(receita.fotos);
  }

  @override
  void dispose() {
    tituloController.dispose();
    ingredientesController.dispose();
    preparoController.dispose();

    super.dispose();
  }

  String? _validarObrigatorio(String? valor, String rotulo) {
    if (valor == null || valor.trim().isEmpty) {
      return '$rotulo é obrigatório.';
    }

    return null;
  }

  Future<void> _escolherFotos() async {
    final selecionadas = await _picker.pickMultiImage(limit: 6);

    if (selecionadas.isEmpty) return;

    setState(() {
      _novasFotos.addAll(selecionadas);
    });
  }

  Widget _preview(Widget imagem, VoidCallback aoRemover) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagem,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: aoRemover,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoAdicionarFotos() {
    return SizedBox(
      width: 100,
      height: 100,
      child: OutlinedButton(
        onPressed: _salvando ? null : _escolherFotos,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 28),
            SizedBox(height: 4),
            Text('Fotos', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _salvando = true);

    try {
      final fotos = [..._fotosExistentes];

      for (final foto in _novasFotos) {
        final bytes = await foto.readAsBytes();
        fotos.add(
          await receitaService.subirFoto(nome: foto.name, bytes: bytes),
        );
      }

      final receita = Receita(
        id: widget.receita?.id,
        titulo: tituloController.text.trim(),
        ingredientes: ingredientesController.text.trim(),
        preparo: preparoController.text.trim(),
        fotos: fotos,
      );

      if (_editando) {
        await receitaService.atualizarReceita(receita);

        messenger.showSnackBar(
          const SnackBar(content: Text('Receita atualizada!')),
        );

        navigator.pop(receita);
      } else {
        await receitaService.criarReceita(receita);

        messenger.showSnackBar(
          const SnackBar(content: Text('Receita salva com sucesso!')),
        );

        navigator.pop();
      }
    } catch (erro) {
      debugPrint('ERRO: $erro');

      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $erro')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Receita' : 'Cadastrar Receita'),
      ),

      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: tituloController,
                  validator: (valor) => _validarObrigatorio(valor, 'Título'),
                  decoration: const InputDecoration(
                    labelText: 'Título da receita',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: ingredientesController,
                  maxLines: 5,
                  validator: (valor) => _validarObrigatorio(valor, 'Ingrediente'),
                  decoration: const InputDecoration(
                    labelText: 'Ingredientes',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: preparoController,
                  maxLines: 7,
                  validator: (valor) =>
                      _validarObrigatorio(valor, 'Modo de preparo'),
                  decoration: const InputDecoration(
                    labelText: 'Modo de preparo',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Fotos da receita',
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                Text(
                  'Adicione até 6 fotos do prato.',
                  style: tema.textTheme.bodySmall,
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _fotosExistentes.length; i++)
                      _preview(
                        Image.network(
                          receitaService.urlDaFoto(_fotosExistentes[i]),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        () => setState(
                          () => _fotosExistentes.removeAt(i),
                        ),
                      ),
                    for (var i = 0; i < _novasFotos.length; i++)
                      _preview(
                        _ImagemXFile(foto: _novasFotos[i]),
                        () => setState(() => _novasFotos.removeAt(i)),
                      ),
                    _botaoAdicionarFotos(),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _editando ? 'Salvar Alterações' : 'Salvar Receita',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagemXFile extends StatefulWidget {
  final XFile foto;

  const _ImagemXFile({required this.foto});

  @override
  State<_ImagemXFile> createState() => _ImagemXFileState();
}

class _ImagemXFileState extends State<_ImagemXFile> {
  late final Future<Uint8List> _bytes = widget.foto.readAsBytes();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }

        return const ColoredBox(
          color: Colors.black12,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
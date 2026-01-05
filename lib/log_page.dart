import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'widgets/loading.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  _LogViewerPageState createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  String _logContent = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/app_log.txt');
  }

  Future<void> _loadLog() async {
    setState(() {
      _loading = true;
    });

    try {
      final file = await _getLogFile();
      final exists = await file.exists();
      if (exists) {
        final lines = await file.readAsLines();

        final buffer = StringBuffer();
        String? lastDate;
        StringBuffer? currentEntry;

        final timestampRegex = RegExp(r'^\[(.*?)\]');

        for (final line in lines) {
          if (line.trim().isEmpty) continue;

          final match = timestampRegex.firstMatch(line);

          if (match != null) {
            if (currentEntry != null) {
              buffer.writeln(currentEntry.toString());
              buffer.writeln();
            }
            currentEntry = StringBuffer();

            final timestamp = match.group(1)!;
            final date = DateTime.tryParse(timestamp)?.toLocal();
            if (date != null) {
              final formattedDate = '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}/'
                  '${date.year}';
              if (formattedDate != lastDate) {
                buffer.writeln('\n== $formattedDate ==\n');
                lastDate = formattedDate;
              }
            }

            currentEntry.writeln('• $line');
          } else {
            currentEntry?.writeln('    $line'); 
          }
        }

        if (currentEntry != null) {
          buffer.writeln(currentEntry.toString());
        }

        setState(() {
          _logContent = buffer.toString().trim();
          _loading = false;
        });
      } else {
        setState(() {
          _logContent = 'Nenhum log encontrado.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _logContent = 'Erro ao ler o log: $e';
        _loading = false;
      });
    }
  }

  Future<void> _clearLog() async {
    try {
      final file = await _getLogFile();
      final exists = await file.exists();
      if (exists) {
        await file.writeAsString('');
      }
      await _loadLog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao limpar o log: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadLog,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar'),
                  content: const Text('Deseja limpar o log?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
                  ],
                ),
              );
              if (confirm == true) {
                await _clearLog();
              }
            },
            tooltip: 'Limpar log',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Loading(
                icon: Icons.article, 
                color: Colors.green,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _logContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

    );
  }
}

import 'package:flutter/material.dart';

import 'log_page.dart';
import 'pendents_page.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.article), text: 'Logs'),
              Tab(icon: Icon(Icons.send), text: 'Pendentes'),
            ],
          ),
        ),
        body: const TabBarView(children: [LogViewerPage(), PendentsPage()]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminBroadcastPage extends StatefulWidget {
  const AdminBroadcastPage({super.key});

  @override
  State<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final supabase = Supabase.instance.client;

  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final programCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  bool sendToAll = true;
  bool isLoading = false;

  Future<void> sendBroadcast() async {
    setState(() => isLoading = true);

    final broadcast = await supabase.from('broadcasts').insert({
      'title': titleCtrl.text,
      'message': messageCtrl.text,
      'target_program': sendToAll ? null : programCtrl.text,
      'target_year': sendToAll ? null : yearCtrl.text,
    }).select().single();

    await supabase.from('admin_logs').insert({
      'action': 'Broadcast Created',
      'entity': titleCtrl.text,
    });

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Broadcast sent successfully")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Broadcast")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            TextField(
              controller: messageCtrl,
              decoration: const InputDecoration(labelText: "Message"),
            ),

            SwitchListTile(
              value: sendToAll,
              title: const Text("Send to ALL students"),
              onChanged: (v) => setState(() => sendToAll = v),
            ),

            if (!sendToAll) ...[
              TextField(
                controller: programCtrl,
                decoration: const InputDecoration(labelText: "Program"),
              ),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: "Year"),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : sendBroadcast,
              child: Text(isLoading ? "Sending..." : "Send Broadcast"),
            ),
          ],
        ),
      ),
    );
  }
}
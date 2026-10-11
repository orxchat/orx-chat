import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

const svc = 'com.btchat.app';
const strat = Strategy.P2P_CLUSTER;
const seed = Color(0xFF0E7C66);

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'orx chat',
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: ThemeMode.system,
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed)),
        darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark)),
        home: const Home(),
      );
}

class Msg {
  final bool mine;
  final String? text, img, from;
  Msg(this.mine, {this.text, this.img, this.from});
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final name = TextEditingController(), input = TextEditingController();
  final found = <String, String>{}, names = <String, String>{};
  final pending = <int, String>{};
  final msgs = <Msg>[];
  final peers = <String>{};
  bool on = false, inChat = false;

  void snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> start() async {
    if (name.text.trim().isEmpty) return snack('اكتب اسمك الأول');
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();
    try {
      await Nearby().startAdvertising(name.text.trim(), strat,
          onConnectionInitiated: init,
          onConnectionResult: res,
          onDisconnected: lost,
          serviceId: svc);
      await Nearby().startDiscovery(name.text.trim(), strat,
          onEndpointFound: (id, n, s) => setState(() => found[id] = n),
          onEndpointLost: (id) => setState(() => found.remove(id)),
          serviceId: svc);
      setState(() => on = true);
    } catch (e) {
      snack('شغّل البلوتوث والموقع (GPS) وجرّب تاني');
    }
  }

  void connect(String id) => Nearby().requestConnection(name.text.trim(), id,
      onConnectionInitiated: init, onConnectionResult: res, onDisconnected: lost);

  void lost(String id) {
    if (mounted) {
      setState(() {
        peers.remove(id);
        if (peers.isEmpty) inChat = false;
      });
    }
  }

  Future<void> init(String id, ConnectionInfo i) async {
    names[id] = i.endpointName;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('اتصال مع ${i.endpointName}'),
        content: Text('رمز التأكيد: ${i.authenticationToken}\nلازم يكون نفس الرمز عند الطرف التاني'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('رفض')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('قبول')),
        ],
      ),
    );
    if (ok == true) {
      Nearby().acceptConnection(id, onPayLoadRecieved: got, onPayloadTransferUpdate: upd);
    } else {
      Nearby().rejectConnection(id);
    }
  }

  void res(String id, Status s) {
    if (s == Status.CONNECTED) {
      setState(() {
        peers.add(id);
        found.remove(id);
        inChat = true;
      });
    } else {
      snack('تعذر الاتصال');
    }
  }

  void got(String id, Payload p) {
    if (p.type == PayloadType.BYTES) {
      setState(() => msgs.add(Msg(false, text: utf8.decode(p.bytes!), from: names[id])));
    } else if (p.type == PayloadType.FILE && p.uri != null) {
      pending[p.id] = p.uri!;
    }
  }

  Future<void> upd(String id, PayloadTransferUpdate u) async {
    if (u.status == PayloadStatus.SUCCESS && pending.containsKey(u.id)) {
      final d = await getApplicationDocumentsDirectory();
      final path = '${d.path}/${u.id}.jpg';
      await Nearby().copyFileAndDeleteOriginal(pending.remove(u.id)!, path);
      if (mounted) setState(() => msgs.add(Msg(false, img: path, from: names[id])));
    }
  }

  void sendText() {
    final t = input.text.trim();
    if (t.isEmpty || peers.isEmpty) return;
    for (final p in peers) {
      Nearby().sendBytesPayload(p, Uint8List.fromList(utf8.encode(t)));
    }
    setState(() => msgs.add(Msg(true, text: t)));
    input.clear();
  }

  Future<void> sendImg() async {
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 70);
    if (f == null || peers.isEmpty) return;
    for (final p in peers) {
      Nearby().sendFilePayload(p, f.path);
    }
    setState(() => msgs.add(Msg(true, img: f.path)));
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Text(inChat ? 'orx chat  (${peers.length + 1})' : 'orx chat'),
          actions: [
            if (inChat)
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => setState(() => inChat = false),
              ),
          ],
        ),
        body: inChat ? chat() : lobby(),
      );

  Widget lobby() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'اسمك', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: on ? null : start,
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(on ? 'جاري البحث عن أجهزة قريبة...' : 'ابدأ البحث'),
          ),
          if (peers.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => inChat = true),
              icon: const Icon(Icons.chat),
              label: Text('رجوع للشات (${peers.length} متصل)'),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              for (final e in found.entries)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(e.value),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => connect(e.key),
                  ),
                ),
            ]),
          ),
        ]),
      );

  Widget chat() => Column(children: [
        Expanded(
          child: ListView(
              padding: const EdgeInsets.all(12), children: [for (final m in msgs) bubble(m)]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.image), onPressed: sendImg),
              Expanded(
                child: TextField(
                    controller: input,
                    decoration: const InputDecoration(hintText: 'اكتب رسالة', border: OutlineInputBorder())),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: sendText),
            ]),
          ),
        ),
      ]);

  Widget bubble(Msg m) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: m.mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: m.mine ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!m.mine && m.from != null)
              Text(m.from!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
            m.img != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(m.img!)))
                : Text(m.text!, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

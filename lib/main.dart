import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cryptography/cryptography.dart' show Ed25519, KeyPairType, Signature, SimplePublicKey;

const svc = 'com.btchat.app';
const strat = Strategy.P2P_CLUSTER;
const seed = Color(0xFF0E7C66);
const ownerPk = 'pk2WAoJGgQCIMj3hH1xeMZYxB+1Rmssl2248qDQon4M=';
const storyColors = [
  Color(0xFF0E7C66),
  Color(0xFF6A1B9A),
  Color(0xFFC2185B),
  Color(0xFFEF6C00),
  Color(0xFF1565C0),
];

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

class Prof {
  final String u, n;
  final String? a, k, sd;
  Prof(this.u, this.n, {this.a, this.k, this.sd});
  Map toJson() => {'u': u, 'n': n, 'a': a, 'k': k, 'sd': sd};
  factory Prof.fromJson(Map j) => Prof(j['u'], j['n'], a: j['a'], k: j['k'], sd: j['sd']);
}

class Grp {
  final String o;
  String n;
  List<String> m;
  Grp(this.o, this.n, this.m);
  Map toJson() => {'o': o, 'n': n, 'm': m};
  factory Grp.fromJson(Map j) => Grp(j['o'], j['n'], List<String>.from(j['m']));
}

class Msg {
  final String c, s, i;
  final String? t, img;
  Msg(this.c, this.s, this.i, {this.t, this.img});
  Map toJson() => {'c': c, 's': s, 'i': i, 't': t, 'g': img};
  factory Msg.fromJson(Map j) => Msg(j['c'], j['s'], j['i'], t: j['t'], img: j['g']);
}

class Story {
  final String from;
  final String? text, img;
  final DateTime at;
  Story(this.from, {this.text, this.img, DateTime? at}) : at = at ?? DateTime.now();
  bool get live => DateTime.now().difference(at).inHours < 24;
  Color get color =>
      storyColors[(text ?? '').codeUnits.fold(0, (a, b) => a + b) % storyColors.length];
  Map toJson() => {'f': from, 't': text, 'i': img, 'a': at.millisecondsSinceEpoch};
  factory Story.fromJson(Map j) =>
      Story(j['f'], text: j['t'], img: j['i'], at: DateTime.fromMillisecondsSinceEpoch(j['a']));
}

class StoryView extends StatelessWidget {
  final List<Story> l;
  final String title;
  const StoryView(this.l, this.title, {super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(title)),
        body: PageView(children: [
          for (final s in l)
            GestureDetector(
              onTap: () => Navigator.pop(c),
              child: s.img != null
                  ? Center(child: Image.file(File(s.img!)))
                  : Container(
                      color: s.color,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Text(s.text!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ),
            ),
        ]),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final uCtl = TextEditingController(), nCtl = TextEditingController(), input = TextEditingController(), kCtl = TextEditingController();
  Prof? me;
  String? tmpAv, cur;
  String view = 'home';
  bool editing = false, on = false;
  final contacts = <String, Prof>{}, groups = <String, Grp>{};
  final who = <String, String>{}, found = <String, String>{};
  final peers = <String>{}, seen = <String>{};
  final fq = <String, List<Map>>{};
  final pending = <int, Map>{};
  final msgs = <Msg>[], stories = <Story>[];
  final certs = <String, Map>{};
  final tok = <String, String>{};
  final chain = <String, Future<void>>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  // ---------- storage ----------
  Future<File> get store async =>
      File('${(await getApplicationDocumentsDirectory()).path}/orx_data2.json');

  Future<void> load() async {
    try {
      final f = await store;
      if (!await f.exists()) return;
      final j = jsonDecode(await f.readAsString());
      setState(() {
        if (j['me'] != null) me = Prof.fromJson(j['me']);
        for (final e in (j['contacts'] as List)) {
          final p = Prof.fromJson(e);
          contacts[p.u] = p;
        }
        for (final e in (j['groups'] as List)) {
          final g = Grp.fromJson(e);
          groups[g.o] = g;
        }
        msgs.addAll((j['msgs'] as List).map((e) => Msg.fromJson(e)));
        for (final e in (j['certs'] as List? ?? [])) {
          certs[e['p']] = Map.from(e);
        }
        stories.addAll((j['stories'] as List).map((e) => Story.fromJson(e)).where((s) => s.live));
      });
      if (me != null && me!.sd == null) {
        final sd = base64Encode(List.generate(32, (_) => Random.secure().nextInt(256)));
        final pk = await pubOf(sd);
        setState(() => me = Prof(me!.u, me!.n, a: me!.a, k: pk, sd: sd));
        save();
      }
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      await (await store).writeAsString(jsonEncode({
        'me': me?.toJson(),
        'contacts': contacts.values.map((p) => p.toJson()).toList(),
        'groups': groups.values.map((g) => g.toJson()).toList(),
        'certs': certs.values.toList(),
        'msgs': msgs.map((m) => m.toJson()).toList(),
        'stories': stories.where((s) => s.live).map((s) => s.toJson()).toList(),
      }));
    } catch (_) {}
  }

  Future<String> keep(String path) async {
    final d = await getApplicationDocumentsDirectory();
    final n = '${d.path}/my_${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(path).copy(n);
    return n;
  }

  void snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Prof prof(String u) => u == me?.u ? me! : (contacts[u] ?? Prof(u, u));

  String chatTitle(String c) =>
      c.startsWith('g:') ? (groups[c.substring(2)]?.n ?? 'مجموعة') : prof(c.substring(2)).n;

  Widget av(String? path, {double r = 22, IconData icon = Icons.person}) {
    final ok = path != null && File(path).existsSync();
    return CircleAvatar(
        radius: r, backgroundImage: ok ? FileImage(File(path)) : null, child: ok ? null : Icon(icon));
  }

  // ---------- profile ----------
  Future<void> pickAv() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 70);
    if (f == null) return;
    final k = await keep(f.path);
    setState(() => tmpAv = k);
  }

  Future<void> saveProfile() async {
    final u = uCtl.text.trim().toLowerCase(), n = nCtl.text.trim();
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u) || n.isEmpty) {
      return snack('اكتب اسمك، واسم مستخدم 3 حروف أو أكتر (إنجليزي/أرقام)');
    }
    var sd = me?.sd;
    final kin = kCtl.text.trim();
    if (kin.isNotEmpty) {
      try {
        if (await pubOf(kin) != ownerPk) return snack('مفتاح المالك غلط');
        sd = kin;
      } catch (_) {
        return snack('مفتاح المالك غلط');
      }
    }
    sd ??= base64Encode(List.generate(32, (_) => Random.secure().nextInt(256)));
    final pk = await pubOf(sd);
    kCtl.clear();
    setState(() {
      me = Prof(u, n, a: tmpAv, k: pk, sd: sd);
      editing = false;
    });
    save();
  }

  // ---------- keys, badges ----------
  final ed = Ed25519();

  Future<String> pubOf(String sd) async {
    final kp = await ed.newKeyPairFromSeed(base64Decode(sd));
    return base64Encode((await kp.extractPublicKey()).bytes);
  }

  Future<String> sign(String msg) async {
    final kp = await ed.newKeyPairFromSeed(base64Decode(me!.sd!));
    return base64Encode((await ed.sign(utf8.encode(msg), keyPair: kp)).bytes);
  }

  Future<bool> check(String msg, String sig, String pk) => ed.verify(utf8.encode(msg),
      signature: Signature(base64Decode(sig),
          publicKey: SimplePublicKey(base64Decode(pk), type: KeyPairType.ed25519)));

  bool get isOwner => me?.k == ownerPk;

  String? role(String u) {
    final k = prof(u).k;
    if (k == null) return null;
    if (k == ownerPk) return 'o';
    final c = certs[k];
    return (c != null && c['r'] == 'v' && c['u'] == u) ? 'v' : null;
  }

  Widget badge(String u, {double s = 16}) {
    final r = role(u);
    if (r == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Icon(Icons.verified, size: s, color: r == 'o' ? const Color(0xFFFFB300) : const Color(0xFF1E88E5)),
    );
  }

  Widget nm(String u, String text, {TextStyle? st}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: Text(text, style: st, overflow: TextOverflow.ellipsis)), badge(u)]);

  Future<void> hello(String id) async {
    sendJ(id, {'k': 'p', 'u': me!.u, 'n': me!.n, 'pk': me!.k, 'sg': await sign('${tok[id]}|${me!.u}')});
    if (me!.a != null) sendFile(id, {'k': 'f', 'w': 'a'}, me!.a!);
  }

  Future<void> mergeCerts(List l) async {
    var ch = false;
    for (final e in l) {
      try {
        final p = e['p'] as String, t = e['t'] as int;
        if (certs[p] != null && (certs[p]!['t'] as int) >= t) continue;
        if (await check('${e['r']}|${e['u']}|$p|$t', e['s'], ownerPk)) {
          certs[p] = Map.from(e);
          ch = true;
        }
      } catch (_) {}
    }
    if (ch) {
      setState(() {});
      save();
    }
  }

  void sendCerts(String id) {
    if (certs.isNotEmpty) sendJ(id, {'k': 'c', 'l': certs.values.toList()});
  }

  Future<void> setVerify(String u, bool v) async {
    final k = contacts[u]?.k;
    if (k == null) return snack('الشخص ده لازم يتصل بيك الأول');
    final t = DateTime.now().millisecondsSinceEpoch, r = v ? 'v' : 'x';
    final e = {'p': k, 'u': u, 'r': r, 't': t, 's': await sign('$r|$u|$k|$t')};
    setState(() => certs[k] = e);
    save();
    for (final id in peers) {
      sendJ(id, {'k': 'c', 'l': [e]});
    }
  }

  void contactMenu(String u) => showModalBottomSheet(
        context: context,
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isOwner && role(u) != 'o')
              ListTile(
                leading: const Icon(Icons.verified),
                title: Text(role(u) == 'v' ? 'إلغاء التوثيق' : 'توثيق الحساب'),
                onTap: () {
                  Navigator.pop(c);
                  setVerify(u, role(u) != 'v');
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_remove),
              title: const Text('حذف الجهة'),
              onTap: () {
                Navigator.pop(c);
                setState(() => contacts.remove(u));
                save();
              },
            ),
          ]),
        ),
      );

  Widget setup() => Scaffold(
        appBar: AppBar(
          title: Text(editing ? 'تعديل الملف الشخصي' : 'أهلاً في orx chat'),
          leading: editing
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => editing = false))
              : null,
        ),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: GestureDetector(onTap: pickAv, child: av(tmpAv, r: 52, icon: Icons.add_a_photo))),
          const SizedBox(height: 20),
          TextField(
              controller: nCtl,
              decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: uCtl,
              readOnly: editing,
              decoration: const InputDecoration(
                  labelText: 'اسم المستخدم', prefixText: '@', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: kCtl,
              decoration: const InputDecoration(
                  labelText: 'مفتاح المالك (للمالك فقط)', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          FilledButton(onPressed: saveProfile, child: const Text('حفظ')),
        ]),
      );

  // ---------- connections ----------
  Future<void> start() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();
    try {
      await Nearby().startAdvertising(me!.u, strat,
          onConnectionInitiated: init, onConnectionResult: res, onDisconnected: lost, serviceId: svc);
      await Nearby().startDiscovery(me!.u, strat,
          onEndpointFound: (id, n, s) => setState(() => found[id] = n),
          onEndpointLost: (id) => setState(() => found.remove(id)),
          serviceId: svc);
      setState(() => on = true);
    } catch (e) {
      snack('شغّل البلوتوث والموقع (GPS) وجرّب تاني');
    }
  }

  void connect(String id) => Nearby().requestConnection(me!.u, id,
      onConnectionInitiated: init, onConnectionResult: res, onDisconnected: lost);

  void lost(String id) {
    if (!mounted) return;
    setState(() {
      peers.remove(id);
      who.remove(id);
    });
  }

  Future<void> init(String id, ConnectionInfo i) async {
    tok[id] = i.authenticationToken;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('اتصال مع @${i.endpointName}'),
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
      });
      hello(id);
    } else {
      snack('تعذر الاتصال');
    }
  }

  // ---------- sending ----------
  Future<void> sendJ(String id, Map j) async {
    await Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode(jsonEncode(j))));
  }

  Future<void> sendFile(String id, Map h, String path) async {
    await sendJ(id, h);
    Nearby().sendFilePayload(id, path);
  }

  Future<void> sendItem(String id, Msg m) async {
    final h = {'c': m.c.startsWith('g:') ? m.c : 'p', 's': m.s, 'i': m.i};
    if (m.img != null) {
      await sendFile(id, {'k': 'f', 'w': 'm', ...h}, m.img!);
    } else {
      await sendJ(id, {'k': 'm', ...h, 't': m.t});
    }
  }

  List<String> targets(String c, {String? skip}) {
    final Set<String> ok;
    if (c.startsWith('g:')) {
      final g = groups[c.substring(2)];
      if (g == null) return [];
      ok = {...g.m, g.o};
    } else {
      ok = {c.substring(2)};
    }
    return who.entries
        .where((e) => peers.contains(e.key) && ok.contains(e.value) && e.value != me!.u && e.key != skip)
        .map((e) => e.key)
        .toList();
  }

  void post(String c, {String? t, String? img}) {
    final m = Msg(c, me!.u, '${me!.u}${DateTime.now().microsecondsSinceEpoch}', t: t, img: img);
    final ts = targets(c);
    if (ts.isEmpty) snack('مفيش حد متصل من المحادثة دي دلوقتي');
    for (final id in ts) {
      sendItem(id, m);
    }
    seen.add(m.i);
    setState(() => msgs.add(m));
    save();
  }

  void sendText() {
    final t = input.text.trim();
    if (t.isEmpty || cur == null) return;
    post(cur!, t: t);
    input.clear();
  }

  Future<void> sendImg() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 70);
    if (f == null || cur == null) return;
    post(cur!, img: await keep(f.path));
  }

  void sendGroup(String id) {
    final g = groups[me!.u];
    if (g != null) sendJ(id, {'k': 'g', 'o': g.o, 'n': g.n, 'm': g.m});
  }

  // ---------- receiving ----------
  void q(String id, Future<void> Function() f) {
    chain[id] = (chain[id] ?? Future.value()).then((_) => f()).catchError((_) {});
  }

  void got(String id, Payload p) => q(id, () async {
        if (p.type == PayloadType.BYTES) {
          await onJson(id, jsonDecode(utf8.decode(p.bytes!)));
        } else if (p.type == PayloadType.FILE && p.uri != null) {
          final l = fq[id];
          pending[p.id] = {'u': p.uri!, 'h': (l != null && l.isNotEmpty) ? l.removeAt(0) : {}};
        }
      });

  Future<void> onJson(String id, Map j) async {
    final k = j['k'];
    if (k == 'p') {
      final u = j['u'] as String, pk = j['pk'] as String?;
      if (pk == null || !await check('${tok[id]}|$u', (j['sg'] ?? '') as String, pk)) return;
      final old = contacts[u];
      if (old?.k != null && old!.k != pk) {
        snack('تحذير: @$u بيستخدم مفتاح مختلف عن اللي نعرفه، اتجاهل');
        return;
      }
      who[id] = u;
      setState(() => contacts[u] = Prof(u, j['n'], a: old?.a, k: pk));
      save();
      sendCerts(id);
      if (groups[me!.u]?.m.contains(u) ?? false) sendGroup(id);
      for (final s in stories.where((s) => s.live && s.from == me!.u)) {
        pushStory(id, s);
      }
      return;
    }
    final u = who[id];
    if (u == null) return;
    if (k == 'f') {
      (fq[id] ??= []).add(j);
    } else if (k == 'm') {
      recv(id, j, t: j['t']);
    } else if (k == 'c') {
      await mergeCerts(j['l']);
    } else if (k == 's') {
      setState(() => stories.add(Story(u, text: j['t'])));
      save();
    } else if (k == 'g' && u == j['o']) {
      final m = List<String>.from(j['m']);
      setState(() {
        if (m.contains(me!.u)) {
          groups[u] = Grp(u, j['n'], m);
        } else {
          groups.remove(u);
        }
      });
      save();
    }
  }

  void recv(String id, Map h, {String? t, String? img}) {
    final u = who[id];
    if (u == null) return;
    final cc = (h['c'] ?? 'p') as String;
    final s = cc.startsWith('g:') ? (h['s'] ?? u) as String : u;
    final i = (h['i'] ?? '$s${DateTime.now().microsecondsSinceEpoch}') as String;
    if (!seen.add(i)) return;
    String c = 'p:$u';
    if (cc.startsWith('g:')) {
      c = cc;
      final g = groups[cc.substring(2)];
      if (g == null) return;
      final ok = {...g.m, g.o};
      if (!ok.contains(s) || !ok.contains(u) || (s != u && u != g.o)) return;
      if (g.o == me!.u) {
        for (final t2 in targets(c, skip: id)) {
          if (who[t2] != s) sendItem(t2, Msg(c, s, i, t: t, img: img));
        }
      }
    }
    setState(() => msgs.add(Msg(c, s, i, t: t, img: img)));
    save();
  }

  void upd(String id, PayloadTransferUpdate t) => q(id, () => upd2(id, t));

  Future<void> upd2(String id, PayloadTransferUpdate t) async {
    if (t.status != PayloadStatus.SUCCESS || !pending.containsKey(t.id)) return;
    final e = pending.remove(t.id)!;
    final d = await getApplicationDocumentsDirectory();
    final path = '${d.path}/${t.id}.jpg';
    await Nearby().copyFileAndDeleteOriginal(e['u'], path);
    final h = e['h'] as Map;
    final u = who[id];
    if (!mounted || u == null) return;
    if (h['w'] == 'a') {
      setState(() => contacts[u] = Prof(u, prof(u).n, a: path, k: prof(u).k));
    } else if (h['w'] == 's') {
      setState(() => stories.add(Story(u, img: path)));
    } else if (h['w'] == 'm') {
      recv(id, h, img: path);
    }
    save();
  }

  // ---------- groups ----------
  Future<void> newGroup() async {
    final t = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('اسم مجموعتك'),
        content: TextField(controller: t, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('إنشاء')),
        ],
      ),
    );
    if (ok != true || t.text.trim().isEmpty) return;
    setState(() => groups[me!.u] = Grp(me!.u, t.text.trim(), []));
    save();
  }

  Future<void> manage() async {
    final g = groups[me!.u]!;
    final sel = {...g.m};
    final people = contacts.values.where((p) => p.u != me!.u).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, st) => AlertDialog(
          title: const Text('أعضاء المجموعة'),
          content: SizedBox(
            width: double.maxFinite,
            child: people.isEmpty
                ? const Text('اتصل بأشخاص الأول من "الأجهزة القريبة" وهيظهروا هنا')
                : ListView(shrinkWrap: true, children: [
                    for (final p in people)
                      CheckboxListTile(
                        value: sel.contains(p.u),
                        title: Text('${p.n} (@${p.u})'),
                        onChanged: (v) => st(() {
                          if (v == true) {
                            sel.add(p.u);
                          } else {
                            sel.remove(p.u);
                          }
                        }),
                      ),
                  ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => g.m = sel.toList());
    for (final id in peers) {
      sendGroup(id);
    }
    save();
  }

  // ---------- stories ----------
  Future<void> pushStory(String id, Story s) async {
    if (s.img != null) {
      await sendFile(id, {'k': 'f', 'w': 's'}, s.img!);
    } else {
      await sendJ(id, {'k': 's', 't': s.text});
    }
  }

  void addStory() => showModalBottomSheet(
        context: context,
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('قصة نصية'),
              onTap: () {
                Navigator.pop(c);
                textStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('قصة بصورة'),
              onTap: () {
                Navigator.pop(c);
                imgStory();
              },
            ),
          ]),
        ),
      );

  void publish(Story s) {
    for (final id in peers) {
      pushStory(id, s);
    }
    setState(() => stories.add(s));
    save();
  }

  Future<void> textStory() async {
    final t = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('قصة نصية'),
        content: TextField(controller: t, maxLines: 4, maxLength: 200, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نشر')),
        ],
      ),
    );
    final txt = t.text.trim();
    if (ok == true && txt.isNotEmpty) publish(Story(me!.u, text: txt));
  }

  Future<void> imgStory() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
    if (f == null) return;
    publish(Story(me!.u, img: await keep(f.path)));
  }

  Widget ring(String label, Widget child, VoidCallback onTap, bool active) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: active ? cs.primary : cs.outlineVariant, width: 3),
            ),
            child: child,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ]),
      ),
    );
  }

  Widget storiesBar() {
    final by = <String, List<Story>>{};
    for (final s in stories.where((s) => s.live)) {
      (by[s.from] ??= []).add(s);
    }
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        children: [
          ring('إضافة', const CircleAvatar(radius: 22, child: Icon(Icons.add)), addStory, false),
          for (final e in by.entries)
            ring(
              e.key == me!.u ? 'قصتي' : prof(e.key).n,
              av(prof(e.key).a),
              () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => StoryView(e.value, prof(e.key).n))),
              true,
            ),
        ],
      ),
    );
  }

  // ---------- screens ----------
  @override
  Widget build(BuildContext c) {
    if (me == null || editing) return setup();
    final owner = view == 'chat' && cur == 'g:${me!.u}';
    return PopScope(
      canPop: view == 'home',
      onPopInvokedWithResult: (d, _) {
        if (!d) {
          setState(() {
            view = 'home';
            cur = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: view == 'home'
              ? nm(me!.u, 'orx chat')
              : view == 'near'
                  ? const Text('الأجهزة القريبة')
                  : (cur!.startsWith('p:')
                      ? nm(cur!.substring(2), chatTitle(cur!))
                      : Text(chatTitle(cur!))),
          actions: [
            if (view == 'home')
              IconButton(
                icon: av(me!.a, r: 14),
                onPressed: () {
                  uCtl.text = me!.u;
                  nCtl.text = me!.n;
                  tmpAv = me!.a;
                  setState(() => editing = true);
                },
              ),
            if (owner) IconButton(icon: const Icon(Icons.group_add), onPressed: manage),
          ],
        ),
        body: view == 'home' ? home() : (view == 'near' ? near() : chat()),
        floatingActionButton: view == 'home'
            ? FloatingActionButton.extended(
                onPressed: () => setState(() => view = 'near'),
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('الأجهزة القريبة'),
              )
            : null,
      ),
    );
  }

  Widget tile(String c, String title, String? a, IconData i) {
    final last = msgs.where((m) => m.c == c).lastOrNull;
    final online = c.startsWith('p:') && who.containsValue(c.substring(2));
    return ListTile(
      leading: av(a, icon: i),
      title: c.startsWith('p:') ? nm(c.substring(2), title) : Text(title),
      onLongPress: c.startsWith('p:') ? () => contactMenu(c.substring(2)) : null,
      subtitle: Text(last == null ? '' : (last.t ?? '📷 صورة'), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: online ? const Icon(Icons.circle, size: 12, color: Colors.green) : null,
      onTap: () => setState(() {
        cur = c;
        view = 'chat';
      }),
    );
  }

  Widget home() => Column(children: [
        storiesBar(),
        Expanded(
          child: ListView(children: [
            if (groups[me!.u] == null)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.group_add)),
                title: const Text('إنشاء مجموعتي'),
                subtitle: const Text('أنت فقط اللي بتضيف الأعضاء'),
                onTap: newGroup,
              ),
            for (final g in groups.values) tile('g:${g.o}', g.n, null, Icons.group),
            for (final p in contacts.values.where((p) => p.u != me!.u)) tile('p:${p.u}', p.n, p.a, Icons.person),
          ]),
        ),
      ]);

  Widget near() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          FilledButton.icon(
            onPressed: on ? null : start,
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(on ? 'جاري البحث عن أجهزة قريبة...' : 'ابدأ البحث'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              for (final u in who.values)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: nm(u, '${prof(u).n} (@$u)'),
                  subtitle: const Text('متصل'),
                ),
              for (final e in found.entries)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('@${e.value}'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => connect(e.key),
                  ),
                ),
            ]),
          ),
        ]),
      );

  Widget chat() {
    final l = msgs.where((m) => m.c == cur).toList();
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [for (final m in l) bubble(m)])),
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
  }

  Widget bubble(Msg m) {
    final cs = Theme.of(context).colorScheme;
    final mine = m.s == me!.u;
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine && cur!.startsWith('g:'))
              nm(m.s, prof(m.s).n,
                  st: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
            m.img != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(m.img!)))
                : Text(m.t ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart' show AudioPlayer, DeviceFileSource, ReleaseMode;
import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:record/record.dart' show AudioRecorder, AudioEncoder, RecordConfig;
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
  final String? t, img, a;
  int st;
  Msg(this.c, this.s, this.i, {this.t, this.img, this.a, this.st = 0});
  Map toJson() => {'c': c, 's': s, 'i': i, 't': t, 'g': img, 'a': a, 'st': st};
  factory Msg.fromJson(Map j) =>
      Msg(j['c'], j['s'], j['i'], t: j['t'], img: j['g'], a: j['a'], st: j['st'] ?? 2);
}

class XO {
  final List<String> b = List.filled(9, '');
  final String my;
  String turn = 'X';
  XO(this.my);
  String? get win {
    const l = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]
    ];
    for (final x in l) {
      if (b[x[0]] != '' && b[x[0]] == b[x[1]] && b[x[0]] == b[x[2]]) return b[x[0]];
    }
    return b.every((e) => e != '') ? 'D' : null;
  }
}

class Story {
  final String from, id;
  final String? text, img;
  String? audio;
  final Set<String> likes;
  final DateTime at;
  Story(this.from, {this.text, this.img, this.audio, String? id, DateTime? at, Set<String>? likes})
      : likes = likes ?? {},
        at = at ?? DateTime.now(),
        id = id ?? '$from${DateTime.now().microsecondsSinceEpoch}';
  bool get live => DateTime.now().difference(at).inHours < 24;
  Color get color =>
      storyColors[(text ?? '').codeUnits.fold(0, (a, b) => a + b) % storyColors.length];
  Map toJson() =>
      {'f': from, 't': text, 'i': img, 'a': at.millisecondsSinceEpoch, 'd': id, 'u': audio, 'k': likes.toList()};
  factory Story.fromJson(Map j) => Story(j['f'],
      text: j['t'],
      img: j['i'],
      audio: j['u'],
      id: j['d'],
      likes: Set<String>.from(j['k'] ?? []),
      at: DateTime.fromMillisecondsSinceEpoch(j['a']));
}

class Post {
  final String i, a;
  final String? t, img, by;
  final int at;
  final Set<String> likes;
  final List<Map> cm;
  Post(this.i, this.a, this.at, {this.t, this.img, this.by, Set<String>? likes, List<Map>? cm})
      : likes = likes ?? {},
        cm = cm ?? [];
  Map toJson() => {'i': i, 'a': a, 'at': at, 't': t, 'g': img, 'b': by, 'l': likes.toList(), 'm': cm};
  factory Post.fromJson(Map j) => Post(j['i'], j['a'], j['at'],
      t: j['t'],
      img: j['g'],
      by: j['b'],
      likes: Set<String>.from(j['l'] ?? []),
      cm: List<Map>.from((j['m'] ?? []).map((e) => Map.from(e))));
}

class StoryView extends StatefulWidget {
  final List<Story> l;
  final String title, meU;
  final void Function(Story) onLike;
  const StoryView(this.l, this.title, this.meU, this.onLike, {super.key});
  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  final pl = AudioPlayer();

  @override
  void initState() {
    super.initState();
    play(0);
  }

  Future<void> play(int i) async {
    try {
      await pl.stop();
      final a = widget.l[i].audio;
      if (a != null && File(a).existsSync()) {
        await pl.setReleaseMode(ReleaseMode.loop);
        await pl.play(DeviceFileSource(a));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    pl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(widget.title)),
        body: PageView(
          onPageChanged: play,
          children: [
            for (final s in widget.l)
              GestureDetector(
                onTap: () => Navigator.pop(c),
                child: Stack(children: [
                  Positioned.fill(
                    child: s.img != null
                        ? Center(child: Image.file(File(s.img!)))
                        : Container(
                            color: s.color,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(24),
                            child: Text(s.text ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          ),
                  ),
                  if (s.img != null && s.text != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 40,
                      child: Text(s.text!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, backgroundColor: Colors.black54)),
                    ),
                  if (s.audio != null)
                    const Positioned(top: 12, right: 12, child: Icon(Icons.music_note, color: Colors.white70)),
                  Positioned(
                    bottom: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: s.from == widget.meU
                          ? Text('❤ ${s.likes.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 18))
                          : IconButton(
                              icon: Icon(
                                  s.likes.contains(widget.meU) ? Icons.favorite : Icons.favorite_border,
                                  color: s.likes.contains(widget.meU) ? Colors.red : Colors.white,
                                  size: 30),
                              onPressed: () {
                                widget.onLike(s);
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ]),
              ),
          ],
        ),
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
  final posts = <Post>[];
  final audioFor = <String, String>{};
  final sentStory = <String>{};
  final blocked = <String>{};
  final games = <String, XO>{};
  final rec = AudioRecorder();
  final vp = AudioPlayer();
  final sCtl = TextEditingController();
  String? gameWith, playing;
  bool recording = false, searching = false;
  DateTime? recAt;
  final following = <String>{}, followers = <String>{};
  final tok = <String, String>{};
  final chain = <String, Future<void>>{};

  @override
  void initState() {
    super.initState();
    vp.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = null);
    });
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
        for (final e in (j['posts'] as List? ?? [])) {
          posts.add(Post.fromJson(e));
        }
        following.addAll(List<String>.from(j['fing'] ?? []));
        blocked.addAll(List<String>.from(j['blk'] ?? []));
        followers.addAll(List<String>.from(j['fers'] ?? []));
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
        'posts': posts.map((p) => p.toJson()).toList(),
        'fing': following.toList(),
        'fers': followers.toList(),
        'blk': blocked.toList(),
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
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 256, maxHeight: 256, imageQuality: 50);
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
    final f = me!.a == null ? null : File(me!.a!);
    if (f != null && f.existsSync()) {
      if (f.lengthSync() <= 22000) {
        sendJ(id, {'k': 'av', 'd': base64Encode(f.readAsBytesSync())});
      } else {
        sendFile(id, {'k': 'f', 'w': 'a'}, me!.a!);
      }
    }
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
            ListTile(
              leading: Icon(following.contains(u) ? Icons.person_remove_alt_1 : Icons.person_add_alt_1),
              title: Text(following.contains(u) ? 'إلغاء المتابعة' : 'متابعة'),
              onTap: () {
                Navigator.pop(c);
                toggleFollow(u);
              },
            ),
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
              leading: const Icon(Icons.block),
              title: Text(blocked.contains(u) ? 'إلغاء الحظر' : 'حظر'),
              onTap: () {
                Navigator.pop(c);
                setState(() {
                  if (blocked.contains(u)) {
                    blocked.remove(u);
                  } else {
                    blocked.add(u);
                    for (final e in who.entries.where((e) => e.value == u).toList()) {
                      Nearby().disconnectFromEndpoint(e.key);
                    }
                  }
                });
                save();
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
          Center(child: logo()),
          const SizedBox(height: 16),
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
          if (editing) ...[
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text('المتابعين (${followers.length})'),
              onTap: () => listUsers('المتابعين', followers),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: Text('بتتابع (${following.length})'),
              onTap: () => listUsers('بتتابع', following),
            ),
          ],
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
    if (blocked.contains(i.endpointName)) {
      Nearby().rejectConnection(id);
      return;
    }
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
    final f = m.img ?? m.a;
    if (f != null) {
      await sendFile(id, {'k': 'f', 'w': 'm', ...h, 'v': m.a != null ? 1 : 0, 'x': f.split('.').last}, f);
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

  void post(String c, {String? t, String? img, String? aud}) {
    final m = Msg(c, me!.u, '${me!.u}${DateTime.now().microsecondsSinceEpoch}', t: t, img: img, a: aud);
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
      if (blocked.contains(u)) {
        Nearby().disconnectFromEndpoint(id);
        return;
      }
      who[id] = u;
      setState(() => contacts[u] = Prof(u, j['n'], a: old?.a, k: pk));
      save();
      sendCerts(id);
      if (following.contains(u)) sendJ(id, flMsg(u, true));
      for (final p in posts.where((p) => p.a == u && p.likes.contains(me!.u))) {
        sendJ(id, {'k': 'lk', 'p': p.i, 'on': true});
      }
      for (final p in posts.where((p) => p.a == u)) {
        for (final x in p.cm.where((x) => x['u'] == me!.u)) {
          sendJ(id, {'k': 'cm', 'p': p.i, 'ci': x['ci'], 't': x['t'], 'at': x['at']});
        }
      }
      for (final st in stories.where((x) => x.from == u && x.live && x.likes.contains(me!.u))) {
        sendJ(id, {'k': 'sl', 'sid': st.id, 'on': true});
      }
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
    } else if (k == 'ack') {
      for (final m in msgs.where((m) => m.i == j['i'] && m.s == me!.u && m.st < 1).toList()) {
        setState(() => m.st = 1);
      }
      save();
    } else if (k == 'rd') {
      final ids = List<String>.from(j['ids'] ?? []);
      setState(() {
        for (final m in msgs.where((m) => ids.contains(m.i) && m.s == me!.u)) {
          m.st = 2;
        }
      });
      save();
    } else if (k == 'cm') {
      final pp = posts.where((p) => p.i == j['p']).firstOrNull;
      if (pp != null && !pp.cm.any((x) => x['ci'] == j['ci'])) {
        setState(() => pp.cm.add({'ci': j['ci'], 'u': u, 't': (j['t'] ?? '').toString(), 'at': j['at']}));
        save();
      }
    } else if (k == 'sl') {
      final st = stories.where((x) => x.id == j['sid'] && x.from == me!.u).firstOrNull;
      if (st != null) {
        setState(() {
          if (j['on'] == true) {
            st.likes.add(u);
          } else {
            st.likes.remove(u);
          }
        });
        save();
      }
    } else if (k == 'xo') {
      xoRecv(u, j);
    } else if (k == 'av') {
      final d = await getApplicationDocumentsDirectory();
      final path = '${d.path}/av_${u}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(base64Decode(j['d']));
      setState(() => contacts[u] = Prof(u, prof(u).n, a: path, k: prof(u).k));
      save();
    } else if (k == 'po') {
      recvPost(id, j);
    } else if (k == 'lk') {
      final pp = posts.where((p) => p.i == j['p']).firstOrNull;
      if (pp != null) {
        setState(() {
          if (j['on'] == true) {
            pp.likes.add(u);
          } else {
            pp.likes.remove(u);
          }
        });
        save();
      }
    } else if (k == 'fl') {
      setState(() {
        if (j['on'] == true) {
          followers.add(u);
        } else {
          followers.remove(u);
        }
      });
      save();
      if (j['on'] == true) {
        final have = (j['h'] as List? ?? []);
        for (final p in posts.where((p) => p.a == me!.u && !have.contains(p.i)).toList().reversed.take(30)) {
          sendPost(id, p);
        }
      }
    } else if (k == 's') {
      if (!stories.any((x) => x.id == j['sid'])) {
        setState(() => stories.add(Story(u, text: j['t'], id: j['sid'], audio: audioFor.remove(j['sid']))));
      }
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

  void recv(String id, Map h, {String? t, String? img, String? aud}) {
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
          if (who[t2] != s) sendItem(t2, Msg(c, s, i, t: t, img: img, a: aud));
        }
      }
    }
    final m = Msg(c, s, i, t: t, img: img, a: aud);
    final viewing = view == 'chat' && cur == c;
    if (viewing) m.st = 2;
    setState(() => msgs.add(m));
    save();
    if (!c.startsWith('g:')) {
      sendJ(id, {'k': 'ack', 'i': i});
      if (viewing) sendJ(id, {'k': 'rd', 'ids': [i]});
    }
    if (!viewing) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
      snack('رسالة جديدة من ${prof(s).n}');
    }
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
      if (!stories.any((x) => x.id == h['sid'])) {
        setState(() => stories
            .add(Story(u, text: h['t'], img: path, id: h['sid'], audio: audioFor.remove(h['sid']))));
      }
    } else if (h['w'] == 'sa') {
      final ext = ((h['x'] ?? 'mp3') as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final ap = '${d.path}/${t.id}.$ext';
      await File(path).rename(ap);
      final st = stories.where((x) => x.id == h['sid']).firstOrNull;
      if (st != null) {
        setState(() => st.audio = ap);
      } else {
        audioFor[h['sid']] = ap;
      }
    } else if (h['w'] == 'm') {
      if (h['v'] == 1) {
        final ext = ((h['x'] ?? 'm4a') as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final ap = '${d.path}/${t.id}.$ext';
        await File(path).rename(ap);
        recv(id, h, aud: ap);
      } else {
        recv(id, h, img: path);
      }
    } else if (h['w'] == 'po') {
      recvPost(id, h, img: path);
    }
    save();
  }

  // ---------- posts, follow, presence ----------
  bool online(String u) => who.containsValue(u);

  Widget avOn(String u, {double r = 22}) => Stack(clipBehavior: Clip.none, children: [
        av(prof(u).a, r: r),
        if (online(u))
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              width: r * .6,
              height: r * .6,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          ),
      ]);

  Widget logo() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: const Text('orx',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
      );

  String ago(int ms) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 1) return 'الآن';
    if (d.inHours < 1) return 'من ${d.inMinutes} د';
    if (d.inDays < 1) return 'من ${d.inHours} س';
    return 'من ${d.inDays} يوم';
  }

  Map flMsg(String u, bool on) =>
      {'k': 'fl', 'on': on, 'h': posts.where((p) => p.a == u).map((p) => p.i).toList()};

  void toggleFollow(String u) {
    final on = !following.contains(u);
    setState(() {
      if (on) {
        following.add(u);
      } else {
        following.remove(u);
      }
    });
    save();
    for (final e in who.entries) {
      if (e.value == u) sendJ(e.key, flMsg(u, on));
    }
  }

  void listUsers(String title, Set<String> s) => showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: s.isEmpty
                ? const Text('لسه مفيش')
                : ListView(shrinkWrap: true, children: [
                    for (final u in s) ListTile(leading: avOn(u), title: nm(u, '${prof(u).n} (@$u)')),
                  ]),
          ),
        ),
      );

  void sendPost(String id, Post p, {String? by}) {
    final h = {
      'i': p.i,
      'a': p.a,
      'at': p.at,
      't': p.t,
      'l': p.likes.toList(),
      'cm': p.cm,
      if (by != null) 'b': by,
    };
    if (p.img != null && File(p.img!).existsSync()) {
      sendFile(id, {'k': 'f', 'w': 'po', ...h}, p.img!);
    } else {
      sendJ(id, {'k': 'po', ...h});
    }
  }

  void recvPost(String id, Map h, {String? img}) {
    final u = who[id];
    if (u == null) return;
    final a = h['a'] as String, by = h['b'] as String?;
    if (a == me!.u) return;
    if (by != null ? by != u : (a != u || !following.contains(a))) return;
    final likes = Set<String>.from(h['l'] ?? []);
    final cms = List<Map>.from((h['cm'] ?? []).map((e) => Map.from(e)));
    final old = posts.where((p) => p.i == h['i']).firstOrNull;
    if (old != null) {
      setState(() {
        old.likes.addAll(likes);
        for (final x in cms) {
          if (!old.cm.any((y) => y['ci'] == x['ci'])) old.cm.add(x);
        }
      });
    } else {
      setState(() => posts.add(Post(h['i'], a, h['at'], t: h['t'], img: img, by: by, likes: likes, cm: cms)));
    }
    save();
  }

  void like(Post p) {
    final on = !p.likes.contains(me!.u);
    setState(() {
      if (on) {
        p.likes.add(me!.u);
      } else {
        p.likes.remove(me!.u);
      }
    });
    save();
    for (final id in peers) {
      sendJ(id, {'k': 'lk', 'p': p.i, 'on': on});
    }
  }

  Future<void> share(Post p) async {
    final people = contacts.values.where((c) => c.u != me!.u).toList();
    final sel = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, st) => AlertDialog(
          title: const Text('share with friends'),
          content: SizedBox(
            width: double.maxFinite,
            child: people.isEmpty
                ? const Text('اتصل بأصحابك الأول من "الأجهزة القريبة"')
                : ListView(shrinkWrap: true, children: [
                    for (final c2 in people)
                      CheckboxListTile(
                        value: sel.contains(c2.u),
                        title: Text('${c2.n} (@${c2.u})'),
                        secondary: online(c2.u) ? const Icon(Icons.circle, size: 12, color: Colors.green) : null,
                        onChanged: (v) => st(() {
                          if (v == true) {
                            sel.add(c2.u);
                          } else {
                            sel.remove(c2.u);
                          }
                        }),
                      ),
                  ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('إرسال')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    var n = 0;
    for (final e in who.entries) {
      if (sel.contains(e.value)) {
        sendPost(e.key, p, by: me!.u);
        n++;
      }
    }
    snack(n == 0 ? 'مفيش حد من اللي اخترتهم متصل دلوقتي' : 'اتبعت لـ $n');
  }

  Future<void> newPost() async {
    final t = TextEditingController();
    String? img;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, st) => AlertDialog(
          title: const Text('منشور جديد'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: t,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(hintText: 'بتفكر في إيه؟')),
              if (img != null)
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(img!), height: 120)),
              TextButton.icon(
                onPressed: () async {
                  final f = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
                  if (f == null) return;
                  final k = await keep(f.path);
                  st(() => img = k);
                },
                icon: const Icon(Icons.image),
                label: const Text('إضافة صورة'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نشر')),
          ],
        ),
      ),
    );
    final txt = t.text.trim();
    if (ok != true || (txt.isEmpty && img == null)) return;
    final p = Post('${me!.u}${DateTime.now().microsecondsSinceEpoch}', me!.u,
        DateTime.now().millisecondsSinceEpoch,
        t: txt.isEmpty ? null : txt, img: img);
    setState(() => posts.add(p));
    save();
    for (final e in who.entries) {
      if (followers.contains(e.value)) sendPost(e.key, p);
    }
  }

  Widget feed() {
    final l = posts.where((p) => p.a == me!.u || following.contains(p.a) || p.by != null).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    if (l.isEmpty) {
      return const Center(
          child: Text('مفيش منشورات لسه.\nانشر حاجة أو تابع حد من الشاشة الرئيسية.', textAlign: TextAlign.center));
    }
    return ListView(padding: const EdgeInsets.all(8), children: [for (final p in l) postCard(p)]);
  }

  Widget postCard(Post p) {
    final liked = p.likes.contains(me!.u);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            avOn(p.a, r: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                nm(p.a, prof(p.a).n, st: const TextStyle(fontWeight: FontWeight.bold)),
                Text(p.by != null ? 'شاركه ${prof(p.by!).n} • ${ago(p.at)}' : ago(p.at),
                    style: const TextStyle(fontSize: 11)),
              ]),
            ),
            if (p.a == me!.u)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() => posts.remove(p));
                  save();
                },
              ),
          ]),
          if (p.t != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(p.t!, style: const TextStyle(fontSize: 16))),
          if (p.img != null && File(p.img!).existsSync())
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p.img!))),
            ),
          const SizedBox(height: 4),
          Wrap(children: [
            TextButton.icon(
              onPressed: () => like(p),
              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
              label: Text('لايك${p.likes.isEmpty ? '' : ' (${p.likes.length})'}'),
            ),
            TextButton.icon(
              onPressed: () => comments(p),
              icon: const Icon(Icons.comment_outlined),
              label: Text('تعليق${p.cm.isEmpty ? '' : ' (${p.cm.length})'}'),
            ),
            TextButton.icon(
              onPressed: () => share(p),
              icon: const Icon(Icons.share),
              label: const Text('share with friends'),
            ),
          ]),
        ]),
      ),
    );
  }

  // ---------- voice, game, backup, block ----------
  Future<void> toggleRec() async {
    if (cur == null) return;
    if (!recording) {
      if (!await rec.hasPermission()) return snack('اسمح بالميكروفون من إعدادات التطبيق');
      final d = await getApplicationDocumentsDirectory();
      final path = '${d.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await rec.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      setState(() {
        recording = true;
        recAt = DateTime.now();
      });
    } else {
      final path = await rec.stop();
      final secs = DateTime.now().difference(recAt!).inSeconds;
      setState(() => recording = false);
      if (path != null && secs >= 1) post(cur!, aud: path);
    }
  }

  Future<void> playVoice(Msg m) async {
    try {
      if (playing == m.i) {
        await vp.stop();
        setState(() => playing = null);
        return;
      }
      await vp.stop();
      await vp.play(DeviceFileSource(m.a!));
      setState(() => playing = m.i);
    } catch (_) {}
  }

  Widget voiceW(Msg m) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: Icon(playing == m.i ? Icons.pause_circle : Icons.play_circle, size: 34),
          onPressed: () => playVoice(m),
        ),
        const Text('رسالة صوتية'),
      ]);

  void markRead(String c) {
    final un = msgs.where((m) => m.c == c && m.s != me!.u && m.st == 0).toList();
    if (un.isEmpty) return;
    for (final m in un) {
      m.st = 2;
    }
    if (c.startsWith('p:')) {
      final ids = un.map((m) => m.i).toList();
      for (final id in targets(c)) {
        sendJ(id, {'k': 'rd', 'ids': ids});
      }
    }
    save();
  }

  void openGame() {
    final u = cur!.substring(2);
    final g = games[u];
    if (g == null || g.win != null) {
      startGame(u);
    } else {
      setState(() {
        gameWith = u;
        view = 'game';
      });
    }
  }

  void startGame(String u) {
    final ids = who.entries.where((e) => e.value == u).map((e) => e.key).toList();
    if (ids.isEmpty) return snack('${prof(u).n} مش متصل دلوقتي');
    for (final id in ids) {
      sendJ(id, {'k': 'xo', 'op': 'new'});
    }
    setState(() {
      games[u] = XO('X');
      gameWith = u;
      view = 'game';
    });
  }

  void xoRecv(String u, Map j) {
    if (j['op'] == 'new') {
      setState(() => games[u] = XO('O'));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${prof(u).n} بدأ لعبة إكس أو'),
        action: SnackBarAction(
          label: 'العب',
          onPressed: () => setState(() {
            gameWith = u;
            view = 'game';
          }),
        ),
      ));
    } else if (j['op'] == 'mv') {
      final g = games[u];
      final i = j['i'];
      if (g == null || i is! int || i < 0 || i > 8 || g.win != null || g.turn == g.my || g.b[i] != '') return;
      setState(() {
        g.b[i] = g.turn;
        g.turn = g.turn == 'X' ? 'O' : 'X';
      });
    }
  }

  void xoMove(String u, int i) {
    final g = games[u];
    if (g == null || g.win != null || g.turn != g.my || g.b[i] != '') return;
    setState(() {
      g.b[i] = g.my;
      g.turn = g.my == 'X' ? 'O' : 'X';
    });
    for (final e in who.entries.where((e) => e.value == u)) {
      sendJ(e.key, {'k': 'xo', 'op': 'mv', 'i': i});
    }
  }

  Widget game() {
    final u = gameWith!;
    final g = games[u]!;
    final w = g.win;
    final cs = Theme.of(context).colorScheme;
    final status = w == 'D'
        ? 'تعادل 🤝'
        : (w != null ? (w == g.my ? 'كسبت 🎉' : 'خسرت 😅') : (g.turn == g.my ? 'دورك (${g.my})' : 'دور ${prof(u).n}'));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(status, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 9; i++)
                GestureDetector(
                  onTap: () => xoMove(u, i),
                  child: Container(
                    decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(g.b[i],
                        style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: g.b[i] == 'X' ? cs.primary : cs.tertiary)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (w != null) FilledButton(onPressed: () => startGame(u), child: const Text('العب تاني')),
      ]),
    );
  }

  Future<void> backup() async {
    await save();
    final txt = await (await store).readAsString();
    final r = await FilePicker.platform.saveFile(
        dialogTitle: 'احفظ النسخة الاحتياطية',
        fileName: 'orx_backup.json',
        bytes: Uint8List.fromList(utf8.encode(txt)));
    snack(r == null ? 'اتلغت النسخة' : 'اتحفظت النسخة. خليها خاصة، فيها مفتاحك السري');
  }

  Future<void> restore() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = r?.files.single.path;
    if (path == null) return;
    try {
      final txt = await File(path).readAsString();
      if (jsonDecode(txt)['me'] == null) throw 'bad';
      await (await store).writeAsString(txt);
      setState(() {
        contacts.clear();
        groups.clear();
        msgs.clear();
        stories.clear();
        posts.clear();
        following.clear();
        followers.clear();
        certs.clear();
        blocked.clear();
        me = null;
      });
      await load();
      snack('اتسترجعت النسخة');
    } catch (_) {
      snack('الملف مش نسخة صالحة');
    }
  }

  void showBlocked() => showDialog(
        context: context,
        builder: (c) => StatefulBuilder(
          builder: (c, up) => AlertDialog(
            title: const Text('المحظورين'),
            content: SizedBox(
              width: double.maxFinite,
              child: blocked.isEmpty
                  ? const Text('مفيش حد محظور')
                  : ListView(shrinkWrap: true, children: [
                      for (final u in blocked.toList())
                        ListTile(
                          title: Text('${prof(u).n} (@$u)'),
                          trailing: TextButton(
                            onPressed: () {
                              setState(() => blocked.remove(u));
                              save();
                              up(() {});
                            },
                            child: const Text('إلغاء الحظر'),
                          ),
                        ),
                    ]),
            ),
          ),
        ),
      );

  void likeStory(Story s) {
    final on = !s.likes.contains(me!.u);
    setState(() {
      if (on) {
        s.likes.add(me!.u);
      } else {
        s.likes.remove(me!.u);
      }
    });
    save();
    for (final e in who.entries.where((e) => e.value == s.from)) {
      sendJ(e.key, {'k': 'sl', 'sid': s.id, 'on': on});
    }
  }

  void comment(Post p, String t) {
    final ci = '${me!.u}${DateTime.now().microsecondsSinceEpoch}';
    final at = DateTime.now().millisecondsSinceEpoch;
    setState(() => p.cm.add({'ci': ci, 'u': me!.u, 't': t, 'at': at}));
    save();
    for (final id in peers) {
      sendJ(id, {'k': 'cm', 'p': p.i, 'ci': ci, 't': t, 'at': at});
    }
  }

  Future<void> comments(Post p) async {
    final t = TextEditingController();
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, up) => AlertDialog(
          title: const Text('التعليقات'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: p.cm.isEmpty
                    ? const Text('لسه مفيش تعليقات')
                    : ListView(shrinkWrap: true, children: [
                        for (final x in p.cm)
                          ListTile(
                            dense: true,
                            title: nm(x['u'], prof(x['u']).n, st: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${x['t']}'),
                          ),
                      ]),
              ),
              TextField(
                controller: t,
                decoration: InputDecoration(
                  hintText: 'اكتب تعليق',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final s2 = t.text.trim();
                      if (s2.isEmpty) return;
                      comment(p, s2);
                      t.clear();
                      up(() {});
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
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
    if (!sentStory.add('${who[id]}|${s.id}')) return;
    final au = s.audio != null && File(s.audio!).existsSync();
    final h = {'sid': s.id, 'au': au, 't': s.text};
    if (s.img != null) {
      await sendFile(id, {'k': 'f', 'w': 's', ...h}, s.img!);
    } else {
      await sendJ(id, {'k': 's', ...h});
    }
    if (au) {
      await sendFile(id, {'k': 'f', 'w': 'sa', 'sid': s.id, 'x': s.audio!.split('.').last}, s.audio!);
    }
  }

  Future<(String, String)?> pickSong() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio);
    final f = r?.files.single;
    if (f == null || f.path == null) return null;
    if (f.size > 15 * 1024 * 1024) {
      snack('الأغنية كبيرة (أكتر من 15 ميجا)، اختار أصغر');
      return null;
    }
    final d = await getApplicationDocumentsDirectory();
    final ext = (f.extension ?? 'mp3').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final n = '${d.path}/song_${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(f.path!).copy(n);
    return (n, f.name);
  }

  void publish(Story s) {
    for (final id in peers) {
      pushStory(id, s);
    }
    setState(() => stories.add(s));
    save();
  }

  Future<void> addStory() async {
    final t = TextEditingController();
    String? img, song, songName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, st) => AlertDialog(
          title: const Text('ستوري جديد'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: t,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(hintText: 'اكتب نص (أو ضيف صورة)')),
              if (img != null)
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(img!), height: 100)),
              TextButton.icon(
                onPressed: () async {
                  final f = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 70);
                  if (f == null) return;
                  final k = await keep(f.path);
                  st(() => img = k);
                },
                icon: const Icon(Icons.image),
                label: Text(img == null ? 'إضافة صورة' : 'تغيير الصورة'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final r = await pickSong();
                  if (r == null) return;
                  st(() {
                    song = r.$1;
                    songName = r.$2;
                  });
                },
                icon: const Icon(Icons.music_note),
                label: Text(song == null ? 'إضافة أغنية من الموبايل' : songName ?? 'أغنية'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نشر')),
          ],
        ),
      ),
    );
    final txt = t.text.trim();
    if (ok != true || (txt.isEmpty && img == null)) return;
    publish(Story(me!.u, text: txt.isEmpty ? null : txt, img: img, audio: song));
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
                  context, MaterialPageRoute(builder: (_) => StoryView(e.value, prof(e.key).n, me!.u, likeStory))),
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
    final inChat = view == 'chat';
    return PopScope(
      canPop: view == 'home',
      onPopInvokedWithResult: (d, _) {
        if (!d) {
          setState(() {
            if (view == 'game') {
              view = 'chat';
            } else {
              view = 'home';
              cur = null;
              searching = false;
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: view == 'home'
              ? Row(mainAxisSize: MainAxisSize.min, children: [logo(), badge(me!.u)])
              : view == 'feed'
                  ? const Text('المنشورات')
                  : view == 'near'
                      ? const Text('الأجهزة القريبة')
                      : view == 'game'
                          ? Text('إكس أو مع ${prof(gameWith!).n}')
                          : (searching
                              ? TextField(
                                  controller: sCtl,
                                  autofocus: true,
                                  decoration:
                                      const InputDecoration(hintText: 'ابحث في المحادثة', border: InputBorder.none),
                                  onChanged: (_) => setState(() {}),
                                )
                              : (cur!.startsWith('p:')
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      avOn(cur!.substring(2), r: 16),
                                      const SizedBox(width: 8),
                                      nm(cur!.substring(2), chatTitle(cur!)),
                                    ])
                                  : Text(chatTitle(cur!)))),
          actions: [
            if (view == 'home') ...[
              IconButton(
                icon: av(me!.a, r: 14),
                onPressed: () {
                  uCtl.text = me!.u;
                  nCtl.text = me!.n;
                  tmpAv = me!.a;
                  setState(() => editing = true);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'b') backup();
                  if (v == 'r') restore();
                  if (v == 'k') showBlocked();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'b', child: Text('نسخة احتياطية')),
                  PopupMenuItem(value: 'r', child: Text('استرجاع نسخة')),
                  PopupMenuItem(value: 'k', child: Text('المحظورين')),
                ],
              ),
            ],
            if (inChat)
              IconButton(
                icon: Icon(searching ? Icons.close : Icons.search),
                onPressed: () => setState(() {
                  searching = !searching;
                  sCtl.clear();
                }),
              ),
            if (inChat && cur!.startsWith('p:'))
              IconButton(icon: const Icon(Icons.sports_esports), onPressed: openGame),
            if (owner) IconButton(icon: const Icon(Icons.group_add), onPressed: manage),
          ],
        ),
        body: view == 'home'
            ? home()
            : (view == 'feed' ? feed() : (view == 'near' ? near() : (view == 'game' ? game() : chat()))),
        floatingActionButton:
            view == 'feed' ? FloatingActionButton(onPressed: newPost, child: const Icon(Icons.add)) : null,
        bottomNavigationBar: (view == 'chat' || view == 'game')
            ? null
            : NavigationBar(
                selectedIndex: view == 'feed' ? 1 : (view == 'near' ? 2 : 0),
                onDestinationSelected: (i) => setState(() => view = const ['home', 'feed', 'near'][i]),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'المحادثات'),
                  NavigationDestination(icon: Icon(Icons.dynamic_feed), label: 'المنشورات'),
                  NavigationDestination(icon: Icon(Icons.bluetooth_searching), label: 'الأجهزة القريبة'),
                ],
              ),
      ),
    );
  }

  Widget tile(String c, String title, String? a, IconData i) {
    final last = msgs.where((m) => m.c == c).lastOrNull;
    final unread = msgs.where((m) => m.c == c && m.s != me!.u && m.st == 0).length;
    return ListTile(
      leading: c.startsWith('p:') ? avOn(c.substring(2)) : av(a, icon: i),
      title: c.startsWith('p:') ? nm(c.substring(2), title) : Text(title),
      onLongPress: c.startsWith('p:') ? () => contactMenu(c.substring(2)) : null,
      subtitle: Text(last == null ? '' : (last.t ?? (last.a != null ? '🎤 رسالة صوتية' : '📷 صورة')),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: unread > 0 ? Badge(label: Text('$unread')) : null,
      onTap: () {
        markRead(c);
        setState(() {
          cur = c;
          view = 'chat';
          searching = false;
        });
      },
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
            for (final p in contacts.values.where((p) => p.u != me!.u && !blocked.contains(p.u))) tile('p:${p.u}', p.n, p.a, Icons.person),
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
                  leading: avOn(u),
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
    final q = sCtl.text.trim();
    final l = msgs.where((m) => m.c == cur && (!searching || q.isEmpty || (m.t ?? '').contains(q))).toList();
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [for (final m in l) bubble(m)])),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.image), onPressed: sendImg),
            IconButton(
              icon: Icon(recording ? Icons.stop_circle : Icons.mic, color: recording ? Colors.red : null),
              onPressed: toggleRec,
            ),
            Expanded(
              child: recording
                  ? const Text('🔴 بيسجّل... اضغط ⏹ للإرسال')
                  : TextField(
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
            if (m.a != null)
              voiceW(m)
            else if (m.img != null)
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(m.img!)))
            else
              Text(m.t ?? '', style: const TextStyle(fontSize: 16)),
            if (mine)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(m.st >= 1 ? Icons.done_all : Icons.done,
                    size: 14, color: m.st >= 2 ? Colors.lightBlueAccent : Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

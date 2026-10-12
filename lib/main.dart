import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart' show AudioPlayer, DeviceFileSource;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' show AudioEncoder, AudioRecorder, RecordConfig;
import 'package:cryptography/cryptography.dart'
    show AesGcm, Ed25519, Hkdf, Hmac, KeyPairType, SecretBox, SecretKey, Sha256, Signature, SimpleKeyPair, SimplePublicKey, X25519;

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

const accents = [
  Color(0xFF0E7C66),
  Color(0xFF6A1B9A),
  Color(0xFFC2185B),
  Color(0xFFEF6C00),
  Color(0xFF1565C0),
  Color(0xFF455A64),
];
final accentIdx = ValueNotifier<int>(0);
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final d = await getApplicationDocumentsDirectory();
    final f = File('${d.path}/orx_data2.json');
    if (await f.exists()) {
      final j = jsonDecode(await f.readAsString());
      final a = j['accent'];
      if (a is int && a >= 0 && a < accents.length) accentIdx.value = a;
      final t = j['tmode'];
      if (t is int && t >= 0 && t < ThemeMode.values.length) themeMode.value = ThemeMode.values[t];
    }
  } catch (_) {}
  runApp(const App());
}

ThemeData orxTheme(Brightness b, [Color? sc]) {
  final cs = ColorScheme.fromSeed(seedColor: sc ?? seed, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

InputDecoration fld(BuildContext c, {String? label, String? hint, IconData? icon}) {
  final cs = Theme.of(c).colorScheme;
  OutlineInputBorder ob([Color? col]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: col == null ? BorderSide.none : BorderSide(color: col, width: 1.6),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: cs.surfaceContainerHigh,
    border: ob(),
    enabledBorder: ob(),
    focusedBorder: ob(cs.primary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => ValueListenableBuilder<int>(
        valueListenable: accentIdx,
        builder: (c, ai, _) => ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (c, tm, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ORX',
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: tm,
            theme: orxTheme(Brightness.light, accents[ai]),
            darkTheme: orxTheme(Brightness.dark, accents[ai]),
            home: const Splash(),
          ),
        ),
      );
}

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const Home(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: ac,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: ac, curve: Curves.easeOutBack)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                ),
                child: Icon(Icons.chat_bubble_rounded, size: 46, color: cs.onPrimary),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => LinearGradient(colors: [cs.primary, cs.tertiary]).createShader(r),
                child: const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12),
                  child: Text('ORX',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              Text('دردشة بدون إنترنت', style: TextStyle(color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

const sbUrl = 'https://leotxhvwrbuqjssdyqav.supabase.co';
const sbKey = 'sb_publishable_fjjlcGPmqjvJN9iXDsSvVQ_OHOxCLfo';

/// Minimal Supabase client (auth + REST + storage) over dart:io, no extra packages.
class Cloud {
  final HttpClient hc = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  String? at, rt, uid;
  String err = '';
  DateTime exp = DateTime.fromMillisecondsSinceEpoch(0);
  void Function()? onSession;

  Future<(int, dynamic)> rest(String method, String path,
      {Object? body, Map<String, String>? headers, bool auth = true}) async {
    try {
      final r = await hc.openUrl(method, Uri.parse('$sbUrl$path')).timeout(const Duration(seconds: 15));
      r.headers.set('apikey', sbKey);
      if (auth && at != null) r.headers.set('Authorization', 'Bearer $at');
      if (body != null) {
        r.headers.set('Content-Type', 'application/json');
        r.add(utf8.encode(jsonEncode(body)));
      }
      headers?.forEach((k, v) => r.headers.set(k, v));
      final res = await r.close().timeout(const Duration(seconds: 20));
      final txt = await res.transform(utf8.decoder).join();
      dynamic js;
      try {
        js = txt.isEmpty ? null : jsonDecode(txt);
      } catch (_) {
        js = txt;
      }
      return (res.statusCode, js);
    } catch (_) {
      return (-1, null);
    }
  }

  Future<bool> upload(String path, List<int> data, String type) async {
    try {
      final r = await hc.openUrl('POST', Uri.parse('$sbUrl/storage/v1/object/orx/$path'));
      r.headers.set('apikey', sbKey);
      r.headers.set('Authorization', 'Bearer $at');
      r.headers.set('Content-Type', type);
      r.contentLength = data.length;
      r.add(data);
      final res = await r.close();
      await res.drain();
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> download(String path) async {
    try {
      final r = await hc.getUrl(Uri.parse('$sbUrl/storage/v1/object/public/orx/$path'));
      final res = await r.close();
      if (res.statusCode != 200) {
        await res.drain();
        return null;
      }
      final b = BytesBuilder(copy: false);
      await for (final c in res) {
        b.add(c);
      }
      return b.takeBytes();
    } catch (_) {
      return null;
    }
  }

  void _ses(Map j) {
    at = j['access_token'] as String?;
    rt = j['refresh_token'] as String?;
    final u = j['user'];
    if (u is Map) uid = u['id'] as String?;
    final ea = j['expires_at'];
    exp = ea is int
        ? DateTime.fromMillisecondsSinceEpoch(ea * 1000)
        : DateTime.now().add(Duration(seconds: (j['expires_in'] ?? 3600) as int));
    onSession?.call();
  }

  String _msg(dynamic js) =>
      js is Map ? (js['msg'] ?? js['error_description'] ?? js['message'] ?? js['error'] ?? '').toString() : '';

  Future<bool> ensure() async {
    if (at != null && DateTime.now().isBefore(exp.subtract(const Duration(minutes: 2)))) return true;
    if (rt != null) {
      final r = await rest('POST', '/auth/v1/token?grant_type=refresh_token',
          body: {'refresh_token': rt}, auth: false);
      if (r.$1 == 200 && r.$2 is Map) {
        _ses(r.$2 as Map);
        return true;
      }
      if (r.$1 == -1) {
        err = 'مفيش اتصال بالإنترنت';
        return false;
      }
    }
    if (uid == null) {
      final r = await rest('POST', '/auth/v1/signup', body: {'data': {}}, auth: false);
      if (r.$1 == 200 && r.$2 is Map) {
        _ses(r.$2 as Map);
        return true;
      }
      err = r.$1 == -1
          ? 'مفيش اتصال بالإنترنت'
          : (_msg(r.$2).toLowerCase().contains('anonymous')
              ? 'فعّل Anonymous sign-ins من إعدادات Supabase'
              : 'تعذر تسجيل الدخول للسيرفر (${r.$1})');
      return false;
    }
    err = 'انتهت جلسة الإنترنت';
    return false;
  }
}

class Prof {
  final String u, n;
  final String? a, k, sd, bio;
  Prof(this.u, this.n, {this.a, this.k, this.sd, this.bio});
  Map toJson() => {'u': u, 'n': n, 'a': a, 'k': k, 'sd': sd, 'b': bio};
  factory Prof.fromJson(Map j) => Prof(j['u'], j['n'], a: j['a'], k: j['k'], sd: j['sd'], bio: j['b']);
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
  final String? t, img, aud;
  final Map<String, String> r;
  Msg(this.c, this.s, this.i, {this.t, this.img, this.aud, Map<String, String>? r}) : r = r ?? {};
  Map toJson() => {'c': c, 's': s, 'i': i, 't': t, 'g': img, 'u': aud, 'r': r};
  factory Msg.fromJson(Map j) => Msg(j['c'], j['s'], j['i'],
      t: j['t'], img: j['g'], aud: j['u'], r: Map<String, String>.from((j['r'] as Map?) ?? {}));
}

class Post {
  final String id, from;
  String? text, img, ip;
  bool im;
  final DateTime at;
  Set<String> likes;
  Post(this.id, this.from, {this.text, this.img, this.ip, this.im = false, DateTime? at, Set<String>? likes})
      : at = at ?? DateTime.now(),
        likes = likes ?? {};
  Color get color =>
      storyColors[(text ?? id).codeUnits.fold(0, (a, b) => a + b) % storyColors.length];
  Map toJson() => {
        'i': id,
        'f': from,
        't': text,
        'g': img,
        'm': im,
        'ip': ip,
        'a': at.millisecondsSinceEpoch,
        'l': likes.toList(),
      };
  factory Post.fromJson(Map j) => Post(j['i'], j['f'],
      text: j['t'],
      img: j['g'],
      im: j['m'] == true,
      ip: j['ip'],
      at: DateTime.fromMillisecondsSinceEpoch(j['a']),
      likes: Set<String>.from((j['l'] as List?) ?? []));
}

String ago(DateTime d) {
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'الآن';
  if (m < 60) return 'منذ $m د';
  if (m < 1440) return 'منذ ${m ~/ 60} س';
  return 'منذ ${m ~/ 1440} يوم';
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
    cloud.onSession = () {
      save();
    };
    load();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = null);
    });
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
        following.addAll(List<String>.from((j['following'] as List?) ?? []));
        followers.addAll(List<String>.from((j['followers'] as List?) ?? []));
        myLikes.addAll(List<String>.from((j['myLikes'] as List?) ?? []));
        posts.addAll(((j['posts'] as List?) ?? []).map((e) => Post.fromJson(e)));
        for (final e in ((j['stats'] as Map?) ?? {}).entries) {
          stats[e.key] = List<int>.from(e.value);
        }
        final cj = j['cloud'];
        if (cj is Map) {
          cloud.rt = cj['rt'] as String?;
          cloud.uid = cj['uid'] as String?;
          cavSrc = cj['avSrc'] as String?;
          cav = cj['av'] as String?;
          lastMsgId = (cj['last'] ?? 0) as int;
        }
      });
      if (me != null && me!.sd == null) {
        final sd = base64Encode(List.generate(32, (_) => Random.secure().nextInt(256)));
        final pk = await pubOf(sd);
        setState(() => me = Prof(me!.u, me!.n, a: me!.a, k: pk, sd: sd, bio: me!.bio));
        save();
      }
      initNet();
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
        'following': following.toList(),
        'followers': followers.toList(),
        'myLikes': myLikes.toList(),
        'posts': posts.map((p) => p.toJson()).toList(),
        'stats': stats,
        'accent': accentIdx.value,
        'tmode': themeMode.value.index,
        'cloud': {'rt': cloud.rt, 'uid': cloud.uid, 'avSrc': cavSrc, 'av': cav, 'last': lastMsgId},
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
      me = Prof(u, n, a: tmpAv, k: pk, sd: sd, bio: bCtl.text.trim());
      editing = false;
    });
    save();
    xkp = null;
    initNet();
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
    sendJ(id, {
      'k': 'p',
      'u': me!.u,
      'n': me!.n,
      'b': me!.bio,
      'pk': me!.k,
      'sg': await sign('${tok[id]}|${me!.u}')
    });
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
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('الملف الشخصي'),
              onTap: () {
                Navigator.pop(c);
                openProf(u);
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

  Widget setup() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: editing ? const Text('تعديل الملف الشخصي') : logo(),
        leading: editing
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => editing = false))
            : null,
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
        if (!editing) ...[
          const SizedBox(height: 8),
          Text('أهلاً بيك في ORX',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('دردشة بدون إنترنت مع الناس القريبين منك',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
        ],
        Center(
          child: GestureDetector(
            onTap: pickAv,
            child: Stack(children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [cs.primary, cs.tertiary])),
                child: av(tmpAv, r: 54, icon: Icons.add_a_photo),
              ),
              PositionedDirectional(
                bottom: 2,
                end: 2,
                child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primary,
                    child: Icon(Icons.edit, size: 16, color: cs.onPrimary)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        TextField(controller: nCtl, decoration: fld(context, label: 'الاسم', icon: Icons.badge_outlined)),
        const SizedBox(height: 12),
        TextField(
            controller: uCtl,
            readOnly: editing,
            decoration: fld(context, label: 'اسم المستخدم', icon: Icons.alternate_email)),
        const SizedBox(height: 12),
        TextField(
            controller: bCtl,
            maxLines: 3,
            maxLength: 120,
            decoration: fld(context, label: 'نبذة عنك', icon: Icons.short_text)),
        const SizedBox(height: 4),
        TextField(
            controller: kCtl,
            decoration: fld(context, label: 'مفتاح المالك (للمالك فقط)', icon: Icons.key_outlined)),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: saveProfile,
          child: const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

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
    if (id.startsWith('net:')) return cloudSend(id.substring(4), j);
    await Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode(jsonEncode(j))));
  }

  Future<void> sendFile(String id, Map h, String path) async {
    if (id.startsWith('net:')) return cloudFile(id.substring(4), h, path);
    await sendJ(id, h);
    Nearby().sendFilePayload(id, path);
  }

  Future<void> sendItem(String id, Msg m) async {
    final h = {'c': m.c.startsWith('g:') ? m.c : 'p', 's': m.s, 'i': m.i};
    if (m.aud != null) {
      await sendFile(id, {'k': 'f', 'w': 'm', 'x': 'a', ...h}, m.aud!);
    } else if (m.img != null) {
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
    final by = <String, String>{};
    for (final e in who.entries) {
      if (peers.contains(e.key) && ok.contains(e.value) && e.value != me!.u && e.key != skip) {
        by[e.value] = e.key;
      }
    }
    if (netReady) {
      for (final u in ok) {
        if (u != me!.u && !by.containsKey(u) && contacts.containsKey(u) && 'net:$u' != skip) {
          by[u] = 'net:$u';
        }
      }
    }
    return by.values.toList();
  }

  void post(String c, {String? t, String? img, String? aud}) {
    final m = Msg(c, me!.u, '${me!.u}${DateTime.now().microsecondsSinceEpoch}', t: t, img: img, aud: aud);
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
      setState(() => contacts[u] = Prof(u, j['n'], a: old?.a, k: pk, bio: j['b'] as String?));
      save();
      sendCerts(id);
      if (groups[me!.u]?.m.contains(u) ?? false) sendGroup(id);
      for (final s in stories.where((s) => s.live && s.from == me!.u)) {
        pushStory(id, s);
      }
      syncSocial(id, u);
      return;
    }
    final u = uOf(id);
    if (u == null) return;
    if (k == 'f') {
      (fq[id] ??= []).add(j);
    } else if (k == 'm') {
      recv(id, j, t: j['t']);
    } else if (k == 'c') {
      await mergeCerts(j['l']);
    } else if (k == 's') {
      if (j['ip'] != null) {
        final b = await cloud.download(j['ip'] as String);
        if (b != null) {
          final d = await getApplicationDocumentsDirectory();
          final pth = '${d.path}/sn_${DateTime.now().microsecondsSinceEpoch}.jpg';
          await File(pth).writeAsBytes(b);
          setState(() => stories.add(Story(u, img: pth)));
        }
      } else {
        setState(() => stories.add(Story(u, text: j['t'])));
      }
      save();
    } else if (k == 'nf') {
      try {
        final b = await cloud.download(j['p'] as String);
        if (b == null) return;
        final plain = await aes.decrypt(SecretBox.fromConcatenation(b, nonceLength: 12, macLength: 16),
            secretKey: SecretKey(base64Decode(j['kk'] as String)));
        final h = Map.from(j['h'] as Map);
        final d = await getApplicationDocumentsDirectory();
        final path = '${d.path}/n_${DateTime.now().microsecondsSinceEpoch}.${h['x'] == 'a' ? 'm4a' : 'jpg'}';
        await File(path).writeAsBytes(plain);
        fileDone(id, h, path);
      } catch (_) {}
    } else if (k == 'fs') {
      setState(() {
        if (j['f'] == true) {
          followers.add(u);
        } else {
          followers.remove(u);
        }
      });
      save();
      sendJ(id, {'k': 'st', 'fr': followers.length, 'fg': following.length});
      if (j['f'] == true) {
        final mine = posts.where((x) => x.from == me!.u).toList()..sort((a, b) => b.at.compareTo(a.at));
        for (final x in mine.take(30)) {
          sendJ(id, postMeta(x));
        }
      }
    } else if (k == 'st') {
      setState(() => stats[u] = [(j['fr'] ?? 0) as int, (j['fg'] ?? 0) as int]);
      save();
    } else if (k == 'po' && j['f'] == u) {
      gotPost(id, u, j);
    } else if (k == 'pr') {
      final p = posts.where((x) => x.id == j['i'] && x.from == me!.u && x.img != null).firstOrNull;
      if (p != null) sendFile(id, {'k': 'f', 'w': 'p', 'i': p.id}, p.img!);
    } else if (k == 'pl') {
      final p = posts.where((x) => x.id == j['i'] && x.from == me!.u).firstOrNull;
      if (p != null) {
        setState(() {
          if (j['v'] == true) {
            p.likes.add(u);
          } else {
            p.likes.remove(u);
          }
        });
        save();
      }
    } else if (k == 'rx') {
      gotReact(id, u, j);
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
    final u = uOf(id);
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
          if (who[t2] != s) sendItem(t2, Msg(c, s, i, t: t, img: img, aud: aud));
        }
      }
    }
    setState(() => msgs.add(Msg(c, s, i, t: t, img: img, aud: aud)));
    save();
  }

  void upd(String id, PayloadTransferUpdate t) => q(id, () => upd2(id, t));

  Future<void> upd2(String id, PayloadTransferUpdate t) async {
    if (t.status != PayloadStatus.SUCCESS || !pending.containsKey(t.id)) return;
    final e = pending.remove(t.id)!;
    final h = e['h'] as Map;
    final d = await getApplicationDocumentsDirectory();
    final path = '${d.path}/${t.id}.${h['x'] == 'a' ? 'm4a' : 'jpg'}';
    await Nearby().copyFileAndDeleteOriginal(e['u'], path);
    final u = who[id];
    if (!mounted || u == null) return;
    if (h['w'] == 'a') {
      setState(() => contacts[u] = Prof(u, prof(u).n, a: path, k: prof(u).k, bio: prof(u).bio));
    } else if (h['w'] == 's') {
      setState(() => stories.add(Story(u, img: path)));
    } else if (h['w'] == 'p') {
      final p = posts.where((x) => x.id == h['i'] && x.from == u).firstOrNull;
      if (p != null) setState(() => p.img = path);
    } else if (h['w'] == 'm') {
      if (h['x'] == 'a') {
        recv(id, h, aud: path);
      } else {
        recv(id, h, img: path);
      }
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
    final oldM = {...g.m};
    setState(() => g.m = sel.toList());
    for (final id in peers) {
      sendGroup(id);
    }
    for (final u in {...oldM, ...sel}) {
      if (!isNear(u)) sendUser(u, {'k': 'g', 'o': g.o, 'n': g.n, 'm': g.m});
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

  Future<void> publish(Story s) async {
    for (final id in peers) {
      pushStory(id, s);
    }
    setState(() => stories.add(s));
    save();
    if (!netReady) return;
    Map? m;
    if (s.img != null) {
      if (await cloud.ensure()) {
        final pth = 's/${cloud.uid}_${DateTime.now().microsecondsSinceEpoch}.jpg';
        if (await cloud.upload(pth, await File(s.img!).readAsBytes(), 'image/jpeg')) {
          m = {'k': 's', 'ip': pth};
        }
      }
    } else {
      m = {'k': 's', 't': s.text};
    }
    if (m != null) {
      for (final u in followers.toList()) {
        if (!isNear(u)) sendUser(u, m);
      }
    }
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active
                  ? LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: AlignmentDirectional.topEnd,
                      end: AlignmentDirectional.bottomStart)
                  : null,
              border: active ? null : Border.all(color: cs.outlineVariant, width: 2),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surface),
              child: child,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 62,
            child: Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ),
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
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
  final sCtl = TextEditingController(), bCtl = TextEditingController();
  final following = <String>{}, followers = <String>{}, myLikes = <String>{};
  final posts = <Post>[];
  final stats = <String, List<int>>{};
  final rec = AudioRecorder();
  final player = AudioPlayer();
  bool recording = false;
  int recSecs = 0;
  Timer? recTimer;
  String? playing, recPath;
  String profU = '', back = 'home';
  static const reacts = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  void dispose() {
    recTimer?.cancel();
    poll?.cancel();
    rec.dispose();
    player.dispose();
    super.dispose();
  }

  void openProfile() {
    uCtl.text = me!.u;
    nCtl.text = me!.n;
    tmpAv = me!.a;
    bCtl.text = me!.bio ?? '';
    setState(() => editing = true);
  }

  void goHome() => setState(() {
        view = 'home';
        cur = null;
      });

  Widget logo({double size = 22}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: size * 0.3),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => LinearGradient(colors: [cs.primary, cs.tertiary]).createShader(r),
        child: Text('ORX',
            style: TextStyle(
                fontSize: size, fontWeight: FontWeight.w900, letterSpacing: size * 0.3, color: Colors.white)),
      ),
    );
  }

  Widget chatHead() {
    final c = cur!;
    const bold = TextStyle(fontWeight: FontWeight.w700, fontSize: 17);
    final online = c.startsWith('p:') && who.containsValue(c.substring(2));
    final title = c.startsWith('p:') ? nm(c.substring(2), chatTitle(c), st: bold) : Text(chatTitle(c), style: bold);
    String? sub;
    if (online) {
      sub = 'متصل الآن';
    } else if (c.startsWith('g:')) {
      sub = '${(groups[c.substring(2)]?.m.length ?? 0) + 1} أعضاء';
    }
    return GestureDetector(
      onTap: c.startsWith('p:') ? () => openProf(c.substring(2)) : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        title,
        if (sub != null)
          Text(sub,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: online ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  void openProf(String u) => setState(() {
        if (view != 'profile') back = view;
        view = 'profile';
        profU = u;
      });

  void goBack() => setState(() {
        if (view == 'profile' && back != 'profile') {
          view = back;
        } else {
          view = 'home';
          cur = null;
        }
      });

  Widget navBar() {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: cs.surfaceContainer,
          elevation: 6,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 64,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: cs.primaryContainer,
            selectedIndex: view == 'feed' ? 1 : (view == 'near' ? 2 : (view == 'profile' ? 3 : 0)),
            onDestinationSelected: (i) => setState(() {
              back = 'home';
              if (i == 3) {
                view = 'profile';
                profU = me!.u;
              } else {
                view = const ['home', 'feed', 'near'][i];
              }
            }),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: 'المحادثات'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'المنشورات'),
              NavigationDestination(
                  icon: Icon(Icons.bluetooth_searching),
                  selectedIcon: Icon(Icons.bluetooth_connected),
                  label: 'القريبة'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    if (me == null || editing) return setup();
    final cs = Theme.of(c).colorScheme;
    final inChat = view == 'chat';
    final otherProf = view == 'profile' && profU != me!.u;
    final owner = inChat && cur == 'g:${me!.u}';
    return PopScope(
      canPop: view == 'home',
      onPopInvokedWithResult: (d, _) {
        if (!d) goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: inChat
              ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: goHome)
              : (otherProf
                  ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: goBack)
                  : IconButton(
                      tooltip: 'المظهر', icon: const Icon(Icons.palette_outlined), onPressed: appearance)),
          title: inChat
              ? chatHead()
              : (otherProf
                  ? nm(profU, '@$profU', st: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))
                  : Row(mainAxisSize: MainAxisSize.min, children: [logo(), badge(me!.u)])),
          actions: [
            if (view == 'home')
              IconButton(
                  tooltip: 'إضافة صديق',
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  onPressed: findFriend),
            if (owner)
              IconButton(
                  tooltip: 'أعضاء المجموعة', icon: const Icon(Icons.group_add_outlined), onPressed: manage),
          ],
        ),
        body: view == 'home'
            ? home()
            : (view == 'feed'
                ? feed()
                : (view == 'near' ? near() : (view == 'profile' ? profileView(profU) : chat()))),
        bottomNavigationBar: (inChat || otherProf) ? null : navBar(),
      ),
    );
  }

  Widget empty(IconData i, String t, String s, {Widget? action}) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
            child: Icon(i, size: 40, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(s, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          if (action != null) ...[const SizedBox(height: 16), action],
        ]),
      ),
    );
  }

  Widget tile(String c, String title, String? a, IconData i) {
    final cs = Theme.of(context).colorScheme;
    final last = msgs.where((m) => m.c == c).lastOrNull;
    final online = c.startsWith('p:') && who.containsValue(c.substring(2));
    const bold = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    final sub = last == null ? 'ابدأ المحادثة' : '${last.s == me!.u ? 'أنت: ' : ''}${last.t ?? (last.aud != null ? '🎤 رسالة صوتية' : '📷 صورة')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: c.startsWith('p:') ? () => contactMenu(c.substring(2)) : null,
          onTap: () => setState(() {
            cur = c;
            view = 'chat';
          }),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Stack(children: [
                av(a, r: 26, icon: i),
                if (online)
                  PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surfaceContainerLow, width: 2.5),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  c.startsWith('p:') ? nm(c.substring(2), title, st: bold) : Text(title, style: bold),
                  const SizedBox(height: 3),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget home() {
    final cs = Theme.of(context).colorScheme;
    final qs = sCtl.text.trim().toLowerCase();
    bool hit(String s) => qs.isEmpty || s.toLowerCase().contains(qs);
    final gl = groups.values.where((g) => hit(g.n)).toList();
    final pl = contacts.values.where((p) => p.u != me!.u && (hit(p.n) || hit(p.u))).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      storiesBar(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: TextField(
          controller: sCtl,
          onChanged: (_) => setState(() {}),
          decoration: fld(context, hint: 'ابحث في المحادثات', icon: Icons.search).copyWith(
            suffixIcon: qs.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      sCtl.clear();
                      setState(() {});
                    }),
          ),
        ),
      ),
      if (groups[me!.u] == null && qs.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Material(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: newGroup,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  CircleAvatar(
                      radius: 24,
                      backgroundColor: cs.primary,
                      child: Icon(Icons.group_add, color: cs.onPrimary)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('إنشاء مجموعتي',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                      const SizedBox(height: 2),
                      Text('أنت فقط اللي بتضيف الأعضاء', style: TextStyle(color: cs.onPrimaryContainer)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      for (final g in gl) tile('g:${g.o}', g.n, null, Icons.group),
      for (final p in pl) tile('p:${p.u}', p.n, p.a, Icons.person),
      if (gl.isEmpty && pl.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: empty(
            qs.isEmpty ? Icons.forum_outlined : Icons.search_off,
            qs.isEmpty ? 'مفيش محادثات لسه' : 'مفيش نتائج',
            qs.isEmpty ? 'دوّر على أجهزة قريبة منك وابدأ أول محادثة' : 'جرّب كلمة تانية',
            action: qs.isEmpty
                ? FilledButton.icon(
                    onPressed: () => setState(() => view = 'near'),
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('الأجهزة القريبة'))
                : null,
          ),
        ),
    ]);
  }

  Widget near() {
    final cs = Theme.of(context).colorScheme;
    Widget sec(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        );
    Widget card(Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(20), child: child),
        );
    const bold = TextStyle(fontWeight: FontWeight.w700);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
              colors: [cs.primary, cs.tertiary],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(on ? Icons.radar : Icons.bluetooth_searching, size: 36, color: cs.onPrimary),
          const SizedBox(height: 12),
          Text('الأجهزة القريبة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onPrimary)),
          const SizedBox(height: 4),
          Text('اتصل بأصحابك القريبين منك من غير إنترنت',
              style: TextStyle(color: cs.onPrimary.withAlpha(220))),
          const SizedBox(height: 16),
          if (on)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  minHeight: 6, color: cs.onPrimary, backgroundColor: cs.onPrimary.withAlpha(60)),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: cs.onPrimary, foregroundColor: cs.primary),
              onPressed: start,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('ابدأ البحث'),
            ),
          if (on) ...[
            const SizedBox(height: 8),
            Text('جاري البحث عن أجهزة قريبة...', style: TextStyle(color: cs.onPrimary)),
          ],
        ]),
      ),
      if (who.isNotEmpty) ...[
        sec('متصل الآن'),
        for (final u in who.values)
          card(ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: av(prof(u).a),
            title: nm(u, '${prof(u).n} (@$u)', st: bold),
            subtitle: const Text('متصل'),
            onTap: () => openProf(u),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          )),
      ],
      if (found.isNotEmpty) ...[
        sec('أجهزة متاحة'),
        for (final e in found.entries)
          card(ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('@${e.value}', style: bold),
            trailing: FilledButton.tonal(onPressed: () => connect(e.key), child: const Text('اتصال')),
          )),
      ],
      if (on && who.isEmpty && found.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: empty(Icons.wifi_tethering, 'مفيش أجهزة لسه', 'اتأكد إن التاني فاتح ORX وعامل بحث'),
        ),
    ]);
  }

  void openImg(String p) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
            body: Center(child: InteractiveViewer(child: Image.file(File(p)))),
          ),
        ),
      );

  // ---------- internet (Supabase) ----------
  final cloud = Cloud();
  final x25 = X25519();
  final aes = AesGcm.with256bits();
  SimpleKeyPair? xkp;
  final cprof = <String, Map>{}, avSeen = <String, String>{};
  final netRetry = <int, int>{};
  final outbox = <MapEntry<String, Map>>[];
  bool netReady = false, netBusy = false, netFatal = false, polling = false;
  String netMsg = '';
  String? cavSrc, cav;
  int lastMsgId = 0;
  Timer? poll;

  String? uOf(String id) => who[id] ?? (id.startsWith('net:') ? id.substring(4) : null);

  bool isNear(String u) => who.entries.any((e) => e.value == u && peers.contains(e.key));

  /// send to a user: Bluetooth/Wi-Fi Direct if nearby, otherwise through the internet
  void sendUser(String u, Map j) {
    for (final e in who.entries) {
      if (e.value == u && peers.contains(e.key)) {
        sendJ(e.key, j);
        return;
      }
    }
    if (netReady) cloudSend(u, j);
  }

  Future<SimpleKeyPair> xpair() async {
    if (xkp != null) return xkp!;
    final h = await Sha256().hash([...base64Decode(me!.sd!), ...utf8.encode('orx-x25519')]);
    return xkp = await x25.newKeyPairFromSeed(h.bytes);
  }

  Future<String> xpub() async => base64Encode((await (await xpair()).extractPublicKey()).bytes);

  Future<SecretKey> skey(String xk) async {
    final sh = await x25.sharedSecretKey(
        keyPair: await xpair(),
        remotePublicKey: SimplePublicKey(base64Decode(xk), type: KeyPairType.x25519));
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(secretKey: sh, nonce: utf8.encode('orx-e2e'));
  }

  Future<String> encTo(String xk, List<int> d) async =>
      base64Encode((await aes.encrypt(d, secretKey: await skey(xk))).concatenation());

  Future<List<int>> decFrom(String xk, String b) async => aes.decrypt(
      SecretBox.fromConcatenation(base64Decode(b), nonceLength: 12, macLength: 16),
      secretKey: await skey(xk));

  Future<Map?> cloudProfile(String u, {bool fresh = false}) async {
    if (!fresh && cprof[u] != null) return cprof[u];
    if (!await cloud.ensure()) return null;
    final r = await cloud.rest('GET', '/rest/v1/profiles?u=eq.${Uri.encodeComponent(u)}&select=*');
    if (r.$1 != 200 || r.$2 is! List || (r.$2 as List).isEmpty) return null;
    final row = Map.from((r.$2 as List).first as Map);
    try {
      if (!await check('xk|$u|${row['xk']}', row['xs'] as String, row['pk'] as String)) return null;
    } catch (_) {
      return null;
    }
    final old = contacts[u];
    if (old?.k != null && old!.k != row['pk']) {
      snack('تحذير: @$u بيستخدم مفتاح مختلف عن اللي نعرفه');
      return null;
    }
    cprof[u] = row;
    var av = old?.a;
    final rav = row['av'] as String?;
    if (rav != null && avSeen[u] != rav) {
      final b = await cloud.download(rav);
      if (b != null) {
        final d = await getApplicationDocumentsDirectory();
        final pth = '${d.path}/av_${u}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(pth).writeAsBytes(b);
        av = pth;
        avSeen[u] = rav;
      }
    }
    if (mounted) {
      setState(() => contacts[u] = Prof(u, (row['n'] ?? u) as String, a: av, k: row['pk'] as String, bio: row['bio'] as String?));
    }
    save();
    return row;
  }

  Future<bool> registerCloud() async {
    netFatal = false;
    if (!await cloud.ensure()) {
      netMsg = cloud.err;
      return false;
    }
    final xk = await xpub();
    final xs = await sign('xk|${me!.u}|$xk');
    String? av;
    final loc = me!.a;
    if (loc != null && File(loc).existsSync()) {
      if (cavSrc == loc && cav != null) {
        av = cav;
      } else {
        final p = 'a/${cloud.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        if (await cloud.upload(p, await File(loc).readAsBytes(), 'image/jpeg')) {
          cavSrc = loc;
          cav = p;
          av = p;
        }
      }
    }
    final r = await cloud.rest('POST', '/rest/v1/profiles?on_conflict=u',
        headers: {'Prefer': 'resolution=merge-duplicates,return=minimal'},
        body: {'u': me!.u, 'n': me!.n, 'bio': me!.bio, 'av': av, 'pk': me!.k, 'xk': xk, 'xs': xs});
    if (r.$1 == 200 || r.$1 == 201 || r.$1 == 204) {
      netMsg = '';
      return true;
    }
    if (r.$1 == 401 || r.$1 == 403 || r.$1 == 409) {
      netFatal = true;
      netMsg = 'اسم المستخدم @${me!.u} مستخدم على الإنترنت من حساب تاني';
    } else {
      netMsg = r.$1 == -1 ? 'مفيش اتصال بالإنترنت' : 'تعذر التسجيل على الإنترنت (${r.$1})';
    }
    return false;
  }

  Future<void> initNet() async {
    if (me == null || me!.sd == null || netBusy) return;
    netBusy = true;
    try {
      final ok = await registerCloud();
      if (!mounted) return;
      setState(() => netReady = ok);
      if (ok) {
        startNet();
      } else {
        if (netMsg.isNotEmpty && netFatal) snack(netMsg);
        if (!netFatal) {
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted && !netReady) initNet();
          });
        }
      }
    } finally {
      netBusy = false;
    }
  }

  void startNet() {
    poll?.cancel();
    poll = Timer.periodic(const Duration(seconds: 4), (_) => pollNet());
    pollNet();
  }

  Future<void> cloudSend(String u, Map j) async {
    final p = await cloudProfile(u);
    if (p == null) {
      if (!await cloud.ensure()) {
        if (outbox.length < 200) outbox.add(MapEntry(u, j));
      } else {
        snack('@$u مش متاح على الإنترنت');
      }
      return;
    }
    try {
      final body = await encTo(p['xk'] as String, utf8.encode(jsonEncode(j)));
      final r = await cloud.rest('POST', '/rest/v1/msgs',
          headers: {'Prefer': 'return=minimal'},
          body: {'from_u': me!.u, 'to_uid': p['uid'], 'body': body});
      if ((r.$1 == -1 || r.$1 >= 500) && outbox.length < 200) outbox.add(MapEntry(u, j));
    } catch (_) {}
  }

  Future<void> cloudFile(String u, Map h, String path) async {
    final p = await cloudProfile(u);
    if (p == null || !File(path).existsSync()) return;
    final key = await aes.newSecretKey();
    final box = await aes.encrypt(await File(path).readAsBytes(), secretKey: key);
    final name = 'm/${cloud.uid}_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}';
    if (!await cloud.upload(name, box.concatenation(), 'application/octet-stream')) {
      snack('تعذر رفع الملف');
      return;
    }
    await cloudSend(u, {'k': 'nf', 'h': h, 'p': name, 'kk': base64Encode(await key.extractBytes())});
  }

  void fileDone(String id, Map h, String path) {
    final u = uOf(id);
    if (!mounted || u == null) return;
    if (h['w'] == 'a') {
      setState(() => contacts[u] = Prof(u, prof(u).n, a: path, k: prof(u).k, bio: prof(u).bio));
    } else if (h['w'] == 's') {
      setState(() => stories.add(Story(u, img: path)));
    } else if (h['w'] == 'p') {
      final p = posts.where((x) => x.id == h['i'] && x.from == u).firstOrNull;
      if (p != null) setState(() => p.img = path);
    } else if (h['w'] == 'm') {
      if (h['x'] == 'a') {
        recv(id, h, aud: path);
      } else {
        recv(id, h, img: path);
      }
    }
    save();
  }

  Future<bool> handleNet(Map row) async {
    final fu = row['from_u'] as String;
    final p = await cloudProfile(fu);
    if (p == null) return false;
    try {
      final plain = utf8.decode(await decFrom(p['xk'] as String, row['body'] as String));
      final j = jsonDecode(plain) as Map;
      final id = 'net:$fu';
      q(id, () => onJson(id, j));
    } catch (_) {}
    return true;
  }

  Future<void> pollNet() async {
    if (polling || !netReady || me == null) return;
    polling = true;
    try {
      if (!await cloud.ensure()) return;
      if (outbox.isNotEmpty) {
        final l = List<MapEntry<String, Map>>.of(outbox);
        outbox.clear();
        for (final e in l) {
          await cloudSend(e.key, e.value);
        }
      }
      final r = await cloud.rest(
          'GET', '/rest/v1/msgs?to_uid=eq.${cloud.uid}&id=gt.$lastMsgId&order=id.asc&limit=100');
      if (r.$1 == 200 && r.$2 is List) {
        final rows = r.$2 as List;
        for (final row in rows) {
          final m = Map.from(row as Map);
          final rid = m['id'] as int;
          if (!await handleNet(m)) {
            final n = (netRetry[rid] ?? 0) + 1;
            netRetry[rid] = n;
            if (n < 4) break;
          }
          lastMsgId = rid;
        }
        if (rows.isNotEmpty) save();
      }
    } catch (_) {
    } finally {
      polling = false;
    }
  }

  Future<void> findFriend() async {
    if (!netReady) return snack(netMsg.isEmpty ? 'الإنترنت لسه بيتجهز، جرّب بعد ثواني' : netMsg);
    final t = TextEditingController();
    var res = <Map>[];
    var busy = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, st) {
          Future<void> go() async {
            final q0 = t.text.trim().toLowerCase().replaceAll('@', '');
            if (q0.length < 2) return;
            st(() => busy = true);
            final r = await cloud.rest('GET',
                '/rest/v1/profiles?u=ilike.${Uri.encodeComponent('$q0*')}&select=u,n&limit=20');
            st(() {
              busy = false;
              res = (r.$1 == 200 && r.$2 is List) ? [for (final e in (r.$2 as List)) Map.from(e as Map)] : <Map>[];
            });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(c).viewInsets.bottom + 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('إضافة صديق', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: t,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => go(),
                decoration: fld(c, hint: 'ابحث باسم المستخدم', icon: Icons.search),
              ),
              if (busy) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final e in res)
                    if (e['u'] != me!.u)
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text((e['n'] ?? '') as String),
                        subtitle: Text('@${e['u']}'),
                        trailing: const Icon(Icons.add),
                        onTap: () async {
                          Navigator.pop(c);
                          final u = e['u'] as String;
                          final p = await cloudProfile(u, fresh: true);
                          if (p == null) {
                            snack('تعذر إضافة @$u');
                          } else {
                            openProf(u);
                          }
                        },
                      ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ---------- voice ----------
  String fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> startRec() async {
    final st = await Permission.microphone.request();
    if (!st.isGranted) return snack('اسمح للتطبيق باستخدام المايك');
    try {
      final d = await getApplicationDocumentsDirectory();
      recPath = '${d.path}/v_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 22050),
          path: recPath!);
      setState(() {
        recording = true;
        recSecs = 0;
      });
      recTimer?.cancel();
      recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => recSecs++);
        if (recSecs >= 120) stopRec(send: true);
      });
    } catch (_) {
      snack('تعذر بدء التسجيل');
    }
  }

  Future<void> stopRec({required bool send}) async {
    recTimer?.cancel();
    String? p;
    try {
      p = await rec.stop();
    } catch (_) {}
    final secs = recSecs;
    if (mounted) setState(() => recording = false);
    if (p == null) return;
    if (send && secs >= 1 && cur != null) {
      post(cur!, aud: p);
    } else {
      try {
        await File(p).delete();
      } catch (_) {}
    }
  }

  Future<void> togglePlay(Msg m) async {
    if (m.aud == null) return;
    await player.stop();
    if (playing == m.i) {
      setState(() => playing = null);
      return;
    }
    setState(() => playing = m.i);
    try {
      await player.play(DeviceFileSource(m.aud!));
    } catch (_) {
      if (mounted) setState(() => playing = null);
    }
  }

  // ---------- reactions ----------
  void react(Msg m, String e) {
    final had = m.r[me!.u];
    setState(() {
      if (had == e) {
        m.r.remove(me!.u);
      } else {
        m.r[me!.u] = e;
      }
    });
    save();
    final pay = {'k': 'rx', 'i': m.i, 'e': m.r[me!.u]};
    for (final id in targets(m.c)) {
      sendJ(id, pay);
    }
  }

  void gotReact(String id, String u, Map j) {
    final m = msgs.where((x) => x.i == j['i']).firstOrNull;
    if (m == null) return;
    var by = u;
    if (m.c.startsWith('g:')) {
      final g = groups[m.c.substring(2)];
      if (g == null) return;
      final ok = {...g.m, g.o};
      if (u == g.o && j['o'] is String) by = j['o'] as String;
      if (!ok.contains(by) || !ok.contains(u)) return;
      if (g.o == me!.u) {
        for (final t2 in targets(m.c, skip: id)) {
          sendJ(t2, {...j, 'o': by});
        }
      }
    } else if (m.c != 'p:$u') {
      return;
    }
    final e = j['e'] as String?;
    setState(() {
      if (e == null) {
        m.r.remove(by);
      } else {
        m.r[by] = e;
      }
    });
    save();
  }

  void msgMenu(Msg m) => showModalBottomSheet(
        context: context,
        builder: (c) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (final e in reacts)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.pop(c);
                      react(m, e);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: m.r[me!.u] == e
                          ? BoxDecoration(shape: BoxShape.circle, color: Theme.of(c).colorScheme.primaryContainer)
                          : null,
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
              ]),
            ),
            if (m.t != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('نسخ'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: m.t!));
                  Navigator.pop(c);
                },
              ),
          ]),
        ),
      );

  // ---------- social: follow / posts / likes / share ----------
  Map postMeta(Post p) => {
        'k': 'po',
        'i': p.id,
        'f': p.from,
        't': p.text,
        'a': p.at.millisecondsSinceEpoch,
        'l': p.likes.toList(),
        'im': p.im,
        'ip': p.ip,
      };

  void syncSocial(String id, String u) {
    sendJ(id, {'k': 'fs', 'f': following.contains(u)});
    final mine = posts.where((p) => p.from == me!.u).toList()..sort((a, b) => b.at.compareTo(a.at));
    for (final p in mine.take(30)) {
      sendJ(id, postMeta(p));
    }
  }

  Future<void> gotPost(String id, String u, Map j) async {
    final pid = j['i'] as String;
    final lk = Set<String>.from((j['l'] as List?) ?? []);
    final mineLike = myLikes.contains(pid);
    final had = lk.contains(me!.u);
    if (mineLike) {
      lk.add(me!.u);
    } else {
      lk.remove(me!.u);
    }
    if (mineLike && !had) sendJ(id, {'k': 'pl', 'i': pid, 'v': true});
    if (!mineLike && had) sendJ(id, {'k': 'pl', 'i': pid, 'v': false});
    Post post;
    final ex = posts.where((x) => x.id == pid).firstOrNull;
    if (ex == null) {
      post = Post(pid, u,
          text: j['t'] as String?,
          im: j['im'] == true,
          at: DateTime.fromMillisecondsSinceEpoch(j['a'] as int),
          likes: lk);
      posts.add(post);
    } else {
      post = ex;
      post.likes = lk;
    }
    setState(() {});
    save();
    if (post.im && (post.img == null || !File(post.img!).existsSync())) {
      final ipath = j['ip'] as String?;
      if (ipath != null) {
        final b = await cloud.download(ipath);
        if (b != null) {
          final d = await getApplicationDocumentsDirectory();
          final pth = '${d.path}/pi_${DateTime.now().microsecondsSinceEpoch}.jpg';
          await File(pth).writeAsBytes(b);
          post.ip = ipath;
          if (mounted) setState(() => post.img = pth);
          save();
        }
      } else {
        sendJ(id, {'k': 'pr', 'i': pid});
      }
    }
  }

  void toggleFollow(String u) {
    setState(() {
      if (!following.remove(u)) following.add(u);
    });
    save();
    sendUser(u, {'k': 'fs', 'f': following.contains(u)});
  }

  void toggleLike(Post p) {
    final v = !myLikes.contains(p.id);
    setState(() {
      if (v) {
        myLikes.add(p.id);
        p.likes.add(me!.u);
      } else {
        myLikes.remove(p.id);
        p.likes.remove(me!.u);
      }
    });
    save();
    if (p.from != me!.u) sendUser(p.from, {'k': 'pl', 'i': p.id, 'v': v});
  }

  Future<void> publishPost(String? text, String? img) async {
    final p = Post('${me!.u}${DateTime.now().microsecondsSinceEpoch}', me!.u,
        text: text, img: img, im: img != null);
    setState(() => posts.add(p));
    save();
    for (final id in peers.where((id) => who.containsKey(id))) {
      sendJ(id, postMeta(p));
    }
    if (!netReady) return;
    if (img != null && await cloud.ensure()) {
      final pth = 'p/${cloud.uid}_${DateTime.now().microsecondsSinceEpoch}.jpg';
      if (await cloud.upload(pth, await File(img).readAsBytes(), 'image/jpeg')) {
        p.ip = pth;
        save();
      }
    }
    for (final u in followers.toList()) {
      if (!isNear(u)) sendUser(u, postMeta(p));
    }
  }

  void delPost(Post p, bool inSheet) {
    setState(() => posts.remove(p));
    save();
    if (inSheet) Navigator.pop(context);
  }

  Future<void> newPost() async {
    String? img;
    final t = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, st) {
          final cs = Theme.of(c).colorScheme;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(c).viewInsets.bottom + 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('منشور جديد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 75);
                  if (f == null) return;
                  final k = await keep(f.path);
                  st(() => img = k);
                },
                child: Container(
                  height: 170,
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(20)),
                  child: img == null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 36, color: cs.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text('أضف صورة (اختياري)', style: TextStyle(color: cs.onSurfaceVariant)),
                        ])
                      : Image.file(File(img!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: t, maxLines: 4, maxLength: 500, decoration: fld(c, hint: 'اكتب تعليق...')),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نشر'))),
              ]),
            ]),
          );
        },
      ),
    );
    final im = img, txt = t.text.trim();
    if (ok == true && (im != null || txt.isNotEmpty)) {
      publishPost(txt.isEmpty ? null : txt, im);
      snack('تم النشر');
    }
  }

  void sendShare(String c, Post p) {
    final cap = (p.text ?? '').trim();
    post(c, t: '📤 منشور من @${p.from}${cap.isEmpty ? '' : '\n$cap'}');
    if (p.img != null && File(p.img!).existsSync()) post(c, img: p.img);
    if (targets(c).isNotEmpty) snack('تمت المشاركة');
  }

  void sharePost(Post p) {
    final items = <MapEntry<String, String>>[
      for (final g in groups.values) MapEntry('g:${g.o}', g.n),
      for (final x in contacts.values.where((x) => x.u != me!.u)) MapEntry('p:${x.u}', x.n),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('مشاركة في محادثة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            Flexible(
              child: items.isEmpty
                  ? const Padding(padding: EdgeInsets.all(32), child: Text('مفيش محادثات تشارك فيها لسه'))
                  : ListView(shrinkWrap: true, children: [
                      for (final e in items)
                        ListTile(
                          leading: Icon(e.key.startsWith('g:') ? Icons.group : Icons.person),
                          title: Text(e.value),
                          trailing: const Icon(Icons.send),
                          onTap: () {
                            Navigator.pop(c);
                            sendShare(e.key, p);
                          },
                        ),
                    ]),
            ),
          ]),
        ),
      ),
    );
  }

  void showUsers(String title, Iterable<String> us) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              Flexible(
                child: us.isEmpty
                    ? const Padding(padding: EdgeInsets.all(32), child: Text('لا أحد هنا لسه'))
                    : ListView(shrinkWrap: true, children: [
                        for (final u in us)
                          ListTile(
                            leading: av(prof(u).a),
                            title: nm(u, prof(u).n),
                            subtitle: Text('@$u'),
                            onTap: () {
                              Navigator.pop(c);
                              openProf(u);
                            },
                          ),
                      ]),
              ),
            ]),
          ),
        ),
      );

  void appearance() => showModalBottomSheet(
        context: context,
        builder: (c) => StatefulBuilder(
          builder: (c, st) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('المظهر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                const Text('لون التطبيق'),
                const SizedBox(height: 12),
                Wrap(spacing: 14, runSpacing: 14, children: [
                  for (var i = 0; i < accents.length; i++)
                    GestureDetector(
                      onTap: () {
                        accentIdx.value = i;
                        save();
                        st(() {});
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: accents[i],
                        child: accentIdx.value == i ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    ),
                ]),
                const SizedBox(height: 20),
                const Text('الوضع'),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                    ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
                  ],
                  selected: {themeMode.value},
                  onSelectionChanged: (s) {
                    themeMode.value = s.first;
                    save();
                    st(() {});
                  },
                ),
              ]),
            ),
          ),
        ),
      );

  Widget postCard(Post p, {VoidCallback? refresh}) {
    final cs = Theme.of(context).colorScheme;
    final pr = prof(p.from);
    final liked = myLikes.contains(p.id);
    final ok = p.img != null && File(p.img!).existsSync();
    final cap = (p.text ?? '').trim();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: refresh == null ? () => openProf(p.from) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              av(pr.a, r: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  nm(p.from, pr.n, st: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(ago(p.at), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ]),
              ),
              if (p.from == me!.u)
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => delPost(p, refresh != null)),
            ]),
          ),
        ),
        if (p.im)
          (ok
              ? GestureDetector(
                  onTap: () => openImg(p.img!),
                  child: Image.file(File(p.img!), width: double.infinity, fit: BoxFit.cover),
                )
              : Container(
                  height: 180,
                  width: double.infinity,
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.image_outlined, size: 36, color: cs.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text('الصورة بتتحمل لما تتصل بصاحبها', style: TextStyle(color: cs.onSurfaceVariant)),
                  ]),
                ))
        else if (cap.isNotEmpty)
          Container(
            width: double.infinity,
            color: p.color,
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(minHeight: 160),
            alignment: Alignment.center,
            child: Text(cap,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(children: [
            IconButton(
              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : null),
              onPressed: () {
                toggleLike(p);
                refresh?.call();
              },
            ),
            Text('${p.likes.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => sharePost(p)),
          ]),
        ),
        if (p.im && cap.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${pr.n}  ', style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: cap),
            ])),
          )
        else
          const SizedBox(height: 8),
      ]),
    );
  }

  void showPost(Post p) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => StatefulBuilder(
          builder: (c, st) => SafeArea(
            child: SingleChildScrollView(child: postCard(p, refresh: () => st(() {}))),
          ),
        ),
      );

  Widget feed() {
    final cs = Theme.of(context).colorScheme;
    final l = posts.where((p) => p.from == me!.u || following.contains(p.from)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final sug = contacts.values.where((p) => p.u != me!.u && !following.contains(p.u)).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Material(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: newPost,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                av(me!.a, r: 18),
                const SizedBox(width: 12),
                Expanded(child: Text('اكتب منشور جديد...', style: TextStyle(color: cs.onSurfaceVariant))),
                Icon(Icons.add_photo_alternate_outlined, color: cs.primary),
                const SizedBox(width: 6),
              ]),
            ),
          ),
        ),
      ),
      if (sug.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('اقتراحات للمتابعة', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: [for (final p in sug) ring(p.n, av(p.a), () => openProf(p.u), true)],
          ),
        ),
      ],
      if (l.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: empty(Icons.dynamic_feed_outlined, 'مفيش منشورات لسه',
              'تابع ناس من ملفاتهم الشخصية أو انشر أول منشور ليك',
              action: FilledButton.icon(
                  onPressed: newPost,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('منشور جديد'))),
        ),
      for (final p in l) postCard(p),
    ]);
  }

  Widget stat(String label, int n, VoidCallback? onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );

  Widget thumb(Post x) {
    final ok = x.img != null && File(x.img!).existsSync();
    return GestureDetector(
      onTap: () => showPost(x),
      child: ok
          ? Image.file(File(x.img!), fit: BoxFit.cover)
          : Container(
              color: x.color,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              child: x.im
                  ? const Icon(Icons.image_outlined, color: Colors.white70)
                  : Text(x.text ?? '',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
    );
  }

  Widget profileView(String u) {
    final cs = Theme.of(context).colorScheme;
    final mine = u == me!.u;
    final p = prof(u);
    final ps = posts.where((x) => x.from == u).toList()..sort((a, b) => b.at.compareTo(a.at));
    final nFollowers = mine ? followers.length : (stats[u]?[0] ?? 0);
    final nFollowing = mine ? following.length : (stats[u]?[1] ?? 0);
    final isFol = following.contains(u);
    return ListView(padding: const EdgeInsets.only(bottom: 16), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                shape: BoxShape.circle, gradient: LinearGradient(colors: [cs.primary, cs.tertiary])),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surface),
              child: av(p.a, r: 42),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(children: [
              stat('منشورات', ps.length, null),
              stat('متابعون', nFollowers, mine ? () => showUsers('المتابعون', followers) : null),
              stat('يتابع', nFollowing, mine ? () => showUsers('يتابع', following) : null),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          nm(u, p.n, st: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('@$u', style: TextStyle(color: cs.onSurfaceVariant)),
          if ((p.bio ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text(p.bio!)],
          if (mine) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(netReady ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 16, color: netReady ? Colors.green : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                    netReady ? 'متصل بالإنترنت' : (netMsg.isEmpty ? 'جاري الاتصال بالإنترنت...' : netMsg),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ),
            ]),
          ],
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: mine
            ? Row(children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                      onPressed: openProfile,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تعديل الملف')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                      onPressed: newPost,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('منشور جديد')),
                ),
              ])
            : Row(children: [
                Expanded(
                  child: isFol
                      ? FilledButton.tonal(onPressed: () => toggleFollow(u), child: const Text('إلغاء المتابعة'))
                      : FilledButton(onPressed: () => toggleFollow(u), child: const Text('متابعة')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      cur = 'p:$u';
                      view = 'chat';
                    }),
                    child: const Text('رسالة'),
                  ),
                ),
              ]),
      ),
      const Divider(height: 1),
      if (ps.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: empty(Icons.photo_library_outlined, 'مفيش منشورات',
              mine ? 'انشر أول منشور ليك' : 'لسه ما نشرش حاجة'),
        )
      else
        Padding(
          padding: const EdgeInsets.all(2),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final x in ps) thumb(x)],
          ),
        ),
    ]);
  }

  // ---------- chat ----------
  Widget recBar(ColorScheme cs) => Row(children: [
        IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error), onPressed: () => stopRec(send: false)),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(28)),
            child: Row(children: [
              Icon(Icons.fiber_manual_record, color: cs.error, size: 14),
              const SizedBox(width: 8),
              Text(fmt(recSecs), style: TextStyle(fontWeight: FontWeight.w700, color: cs.onErrorContainer)),
              const Spacer(),
              Text('جاري التسجيل...', style: TextStyle(color: cs.onErrorContainer)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.send),
          onPressed: () => stopRec(send: true),
        ),
      ]);

  Widget inputBar(ColorScheme cs) {
    final empty = input.text.trim().isEmpty;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(28)),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.image_outlined), onPressed: sendImg),
            Expanded(
              child: TextField(
                controller: input,
                minLines: 1,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: Icon(empty ? Icons.mic : Icons.send),
        onPressed: empty ? startRec : sendText,
      ),
    ]);
  }

  Widget chat() {
    final cs = Theme.of(context).colorScheme;
    final l = msgs.where((m) => m.c == cur).toList();
    return Column(children: [
      Expanded(
        child: l.isEmpty
            ? empty(Icons.waving_hand_outlined, 'ابدأ المحادثة', 'ابعت أول رسالة 👋')
            : ListView(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                children: [for (final m in l.reversed) bubble(m)],
              ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: recording ? recBar(cs) : inputBar(cs),
        ),
      ),
    ]);
  }

  Widget voice(Msg m, Color fg) {
    final on = playing == m.i;
    final sd0 = m.i.codeUnits.fold(0, (a, b) => a + b);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        customBorder: const CircleBorder(),
        onTap: () => togglePlay(m),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(on ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36, color: fg),
        ),
      ),
      const SizedBox(width: 6),
      for (var i = 0; i < 22; i++)
        Container(
          width: 3,
          height: 6 + ((sd0 * (i + 3)) % 17).toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
              color: fg.withAlpha(on ? 255 : 150), borderRadius: BorderRadius.circular(2)),
        ),
      const SizedBox(width: 8),
      Icon(Icons.mic, size: 16, color: fg.withAlpha(180)),
    ]);
  }

  Widget bubble(Msg m) {
    final cs = Theme.of(context).colorScheme;
    final mine = m.s == me!.u;
    final img = m.img != null;
    final fg = mine ? cs.onPrimary : cs.onSurface;
    final counts = <String, int>{};
    for (final e in m.r.values) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: mine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () => msgMenu(m),
              child: Container(
                padding: img ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: mine ? cs.primary : cs.surfaceContainerHigh,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(20),
                    topEnd: const Radius.circular(20),
                    bottomStart: Radius.circular(mine ? 5 : 20),
                    bottomEnd: Radius.circular(mine ? 20 : 5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!mine && cur!.startsWith('g:'))
                      Padding(
                        padding: EdgeInsets.only(bottom: 3, left: img ? 8 : 0, right: img ? 8 : 0, top: img ? 4 : 0),
                        child: nm(m.s, prof(m.s).n,
                            st: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
                      ),
                    if (m.aud != null)
                      voice(m, fg)
                    else if (img)
                      GestureDetector(
                        onTap: () => openImg(m.img!),
                        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(m.img!))),
                      )
                    else
                      Text(m.t ?? '', style: TextStyle(fontSize: 16, height: 1.35, color: fg)),
                  ],
                ),
              ),
            ),
            if (counts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(spacing: 4, children: [
                  for (final e in counts.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text('${e.key}${e.value > 1 ? ' ${e.value}' : ''}', style: const TextStyle(fontSize: 13)),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

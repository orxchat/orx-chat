import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart' show AudioPlayer, DeviceFileSource;
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/widgets.dart' as fw show Text;
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' show AudioEncoder, AudioRecorder, RecordConfig;
import 'package:video_player/video_player.dart';
import 'package:cryptography/cryptography.dart'
    show AesGcm, Ed25519, Hkdf, Hmac, KeyPairType, SecretBox, SecretKey, Sha256, Signature, SimpleKeyPair, SimplePublicKey, X25519;

const svc = 'com.btchat.app';
const strat = Strategy.P2P_CLUSTER;
const seed = Color(0xFF0E7C66);
const ownerPk = '4WViu8FM9l7q8f0JmoawykKzCyzcRWJSFooFcGf88I8=';
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

const kContactEmail = 'orxchat.support@gmail.com';
final langCode = ValueNotifier<String>('ar');
bool get isEn => langCode.value == 'en';

const _en = <String, String>{
  'دردشة بدون إنترنت': 'Chat without internet',
  'مفيش اتصال بالإنترنت': 'No internet connection',
  'فحص الاتصال': 'Check connection',
  'إعادة المحاولة': 'Retry',
  'إغلاق': 'Close',
  'فعّل Anonymous sign-ins من إعدادات Supabase': 'Enable Anonymous sign-ins in the Supabase settings',
  'انتهت جلسة الإنترنت': 'Internet session expired',
  'الآن': 'Now',
  'مجموعة': 'Group',
  'اكتب اسمك، واسم مستخدم 3 حروف أو أكتر (إنجليزي/أرقام)': 'Enter your name and a username of 3+ characters (English letters/numbers)',
  'مفتاح المالك غلط': 'Wrong owner key',
  'الشخص ده لازم يتصل بيك الأول': 'This person must connect with you first',
  'الملف الشخصي': 'Profile',
  'إلغاء التوثيق': 'Remove verification',
  'توثيق الحساب': 'Verify account',
  'حذف الجهة': 'Delete contact',
  'تعديل الملف الشخصي': 'Edit profile',
  'أهلاً بيك في ORX': 'Welcome to ORX',
  'دردشة بدون إنترنت مع الناس القريبين منك': 'Chat without internet with people near you',
  'الاسم': 'Name',
  'اسم المستخدم': 'Username',
  'نبذة عنك': 'About you',
  'مفتاح المالك (للمالك فقط)': 'Owner key (owner only)',
  'حفظ': 'Save',
  'شغّل البلوتوث والموقع (GPS) وجرّب تاني': 'Turn on Bluetooth and location (GPS) and try again',
  'رفض': 'Decline',
  'قبول': 'Accept',
  'تعذر الاتصال': "Couldn't connect",
  'مفيش حد متصل من المحادثة دي دلوقتي': 'No one from this chat is connected right now',
  'اسم مجموعتك': 'Your group name',
  'إلغاء': 'Cancel',
  'إنشاء': 'Create',
  'أعضاء المجموعة': 'Group members',
  'اتصل بأشخاص الأول من "الأجهزة القريبة" وهيظهروا هنا': 'Connect with people first from "Nearby" and they will show up here',
  'قصة نصية': 'Text story',
  'قصة بصورة': 'Photo story',
  'نشر': 'Post',
  'إضافة': 'Add',
  'قصتي': 'My story',
  'متصل الآن': 'Online now',
  'المحادثات': 'Chats',
  'المنشورات': 'Posts',
  'القريبة': 'Nearby',
  'حسابي': 'Me',
  'المظهر': 'Settings',
  'إضافة صديق': 'Add friend',
  'ابدأ المحادثة': 'Start a conversation',
  'ابحث في المحادثات': 'Search chats',
  'إنشاء مجموعتي': 'Create my group',
  'أنت فقط اللي بتضيف الأعضاء': 'Only you can add members',
  'مفيش محادثات لسه': 'No chats yet',
  'مفيش نتائج': 'No results',
  'دوّر على أجهزة قريبة منك وابدأ أول محادثة': 'Look for nearby devices and start your first chat',
  'جرّب كلمة تانية': 'Try another word',
  'الأجهزة القريبة': 'Nearby devices',
  'اتصل بأصحابك القريبين منك من غير إنترنت': 'Connect with friends near you, no internet needed',
  'ابدأ البحث': 'Start searching',
  'جاري البحث عن أجهزة قريبة...': 'Searching for nearby devices...',
  'متصل': 'Connected',
  'أجهزة متاحة': 'Available devices',
  'اتصال': 'Connect',
  'مفيش أجهزة لسه': 'No devices yet',
  'اتأكد إن التاني فاتح ORX وعامل بحث': 'Make sure the other person has ORX open and is searching',
  'تعذر رفع الملف': "Couldn't upload the file",
  'الإنترنت لسه بيتجهز، جرّب بعد ثواني': 'The internet connection is still getting ready, try again in a few seconds',
  'ابحث باسم المستخدم': 'Search by username',
  'اسمح للتطبيق باستخدام المايك': 'Allow the app to use the microphone',
  'تعذر بدء التسجيل': "Couldn't start recording",
  'نسخ': 'Copy',
  'منشور جديد': 'New post',
  'أضف صورة (اختياري)': 'Add a photo (optional)',
  'اكتب تعليق...': 'Write a comment...',
  'تم النشر': 'Posted',
  'تمت المشاركة': 'Shared',
  'مشاركة في محادثة': 'Share in a chat',
  'مفيش محادثات تشارك فيها لسه': 'No chats to share in yet',
  'لا أحد هنا لسه': 'No one here yet',
  'لون التطبيق': 'App color',
  'الوضع': 'Mode',
  'تلقائي': 'Auto',
  'فاتح': 'Light',
  'داكن': 'Dark',
  'الصورة بتتحمل لما تتصل بصاحبها': 'The picture loads when you connect with its owner',
  'اكتب منشور جديد...': 'Write a new post...',
  'اقتراحات للمتابعة': 'Suggested to follow',
  'مفيش منشورات لسه': 'No posts yet',
  'تابع ناس من ملفاتهم الشخصية أو انشر أول منشور ليك': 'Follow people from their profiles or publish your first post',
  'منشورات': 'Posts',
  'متابعون': 'Followers',
  'المتابعون': 'Followers',
  'يتابع': 'Following',
  'متصل بالإنترنت': 'Online',
  'جاري الاتصال بالإنترنت...': 'Connecting to the internet...',
  'تعديل الملف': 'Edit profile',
  'إلغاء المتابعة': 'Unfollow',
  'متابعة': 'Follow',
  'رسالة': 'Message',
  'مفيش منشورات': 'No posts',
  'انشر أول منشور ليك': 'Publish your first post',
  'لسه ما نشرش حاجة': "Hasn't posted anything yet",
  'جاري التسجيل...': 'Recording...',
  'اكتب رسالة': 'Write a message',
  'ابعت أول رسالة 👋': 'Send the first message 👋',
  '🎤 رسالة صوتية': '🎤 Voice message',
  '📷 صورة': '📷 Photo',
  'اللغة': 'Language',
  'سياسة الخصوصية': 'Privacy policy',
  'بالمتابعة أنت توافق على سياسة الخصوصية': 'By continuing you agree to the Privacy Policy',
  'ريل جديد': 'New reel',
  'ريلز': 'Reels',
  'تصوير فيديو': 'Record video',
  'من المعرض': 'From gallery',
  'الفيديو كبير، الحد الأقصى 45 ميجا': 'The video is too large, max 45 MB',
  'تعذر رفع الفيديو': "Couldn't upload the video",
  'تم نشر الريل': 'Reel posted',
  'تعذر نشر الريل': "Couldn't post the reel",
  'مفيش ريلز لسه': 'No reels yet',
  'انشر أول ريل': 'Post the first reel',
  'أصدقائي': 'Friends',
  'اكتشاف': 'Explore',
  'مفيش حاجة للاكتشاف لسه': 'Nothing to explore yet',
  'تعذر النشر على الإنترنت، اتحفظ عندك وهيوصل للقريبين منك':
      "Couldn't post online. Saved on your phone and will reach people near you",
  'تعذر نشر القصة على الإنترنت، اتحفظت للقريبين منك': "Couldn't post the story online. Saved for people near you",
  'تعذر تسجيل الإعجاب': "Couldn't register the like",
  'الدردشة عبر الإنترنت': 'Chat over the internet',
  'لو قفلتها، الرسائل بتتبعت بس لما تكونوا قريبين من بعض (بلوتوث)':
      'If off, messages are sent only when you are near each other (Bluetooth)',
  'بحث عن أجهزة قريبة': 'Find nearby devices',
  'الفيديو مش شغال': "The video can't be played",
  'إبلاغ عن المحتوى': 'Report content',
  'إبلاغ عن المستخدم': 'Report user',
  'حظر المستخدم': 'Block user',
  'إلغاء الحظر': 'Unblock',
  'تم الحظر': 'User blocked',
  'تم إلغاء الحظر': 'User unblocked',
  'محتوى مزعج أو سبام': 'Spam',
  'محتوى غير لائق': 'Inappropriate content',
  'تحرش أو إساءة': 'Harassment or abuse',
  'انتحال شخصية': 'Impersonation',
  'سبب آخر': 'Other',
  'تفاصيل إضافية (اختياري)': 'More details (optional)',
  'إرسال': 'Send',
  'الإبلاغ يحتاج إنترنت': 'Reporting needs internet',
  'تم إرسال البلاغ، شكراً لك': 'Report sent, thank you',
  'تعذر إرسال البلاغ': "Couldn't send the report",
  'الحسابات المحظورة': 'Blocked accounts',
  'مفيش حسابات محظورة': 'No blocked accounts',
  'حذف الحساب': 'Delete account',
  'هيتم حذف حسابك وكل بياناتك نهائياً من السيرفر ومن الجهاز: الملف الشخصي والمنشورات والقصص والتعليقات والرسائل. مينفعش نرجّعها بعد كده.': 'Your account and all your data will be permanently deleted from the server and from this device: profile, posts, stories, comments and messages. This cannot be undone.',
  'حذف نهائي': 'Delete permanently',
  'لازم تكون متصل بالإنترنت عشان تحذف الحساب': 'You must be online to delete your account',
  'تعذر حذف الحساب من السيرفر، جرّب تاني': "Couldn't delete the account from the server, try again",
  'التعليقات': 'Comments',
  'التعليقات بتحتاج إنترنت': 'Comments need internet',
  'تعذر إرسال التعليق': "Couldn't send the comment",
  'مفيش تعليقات لسه': 'No comments yet',
  'كن أول من يعلّق': 'Be the first to comment',
  'إعادة ضبط التطبيق': 'Reset app',
  'إعادة ضبط': 'Reset',
  'هيتمسح كل اللي على الجهاز ده (المحادثات والمفاتيح والإعدادات) وترجع تسجّل من الأول باسم مستخدم جديد. حسابك القديم على السيرفر مش هيتحذف (لو عايز تحذفه استخدم حذف الحساب).': 'Everything on this device (chats, keys, settings) will be erased and you will sign up again with a new username. Your old account on the server is not deleted (use Delete account for that).',
  'حروف إنجليزية وأرقام و _ فقط، ومينفعش تتغيّر بعد كده': 'English letters, digits and _ only. It cannot be changed later',
  'السيرفر مشغول، جرّب بعد شوية': 'The server is busy, try again shortly',
  'الاسم متاح ✓': 'Name is available ✓',
  'بنتأكد من الاسم...': 'Checking the name...',
  'الاسم ده محجوز لشخص تاني، اختار اسم مختلف': 'This username belongs to someone else, choose a different one',
};

final _enPat = <(RegExp, String Function(RegExpMatch))>[
  (RegExp(r'^منذ (\d+) د$'), (m) => '${m[1]}m ago'),
  (RegExp(r'^منذ (\d+) س$'), (m) => '${m[1]}h ago'),
  (RegExp(r'^منذ (\d+) يوم$'), (m) => '${m[1]}d ago'),
  (RegExp(r'^(\d+) أعضاء$'), (m) => '${m[1]} members'),
  (RegExp(r'^@(.+) مش متاح على الإنترنت$'), (m) => "@${m[1]} isn't available online"),
  (RegExp(r'^اتصال مع @(.+)$'), (m) => 'Connect with @${m[1]}'),
  (RegExp(r'^اسم المستخدم @(.+) مستخدم على الإنترنت من حساب تاني$'),
      (m) => 'The username @${m[1]} is already taken online by another account'),
  (RegExp(r'^تحذير: @(.+) بيستخدم مفتاح مختلف عن اللي نعرفه، اتجاهل$'),
      (m) => 'Warning: @${m[1]} is using a different key than the one we know. Ignored'),
  (RegExp(r'^تحذير: @(.+) بيستخدم مفتاح مختلف عن اللي نعرفه$'),
      (m) => 'Warning: @${m[1]} is using a different key than the one we know'),
  (RegExp(r'^تعذر إضافة @(.+)$'), (m) => "Couldn't add @${m[1]}"),
  (RegExp(r'^تعذر التسجيل على الإنترنت \((.+)\)$'), (m) => "Couldn't register online (${m[1]})"),
  (RegExp(r'^تعذر تسجيل الدخول للسيرفر \((.+)\)$'), (m) => "Couldn't sign in to the server (${m[1]})"),
  (RegExp(r'^رمز التأكيد: (.+)\nلازم يكون نفس الرمز عند الطرف التاني$', dotAll: true),
      (m) => 'Confirmation code: ${m[1]}\nBoth devices must show the same code'),
  (RegExp(r'^أنت: (.*)$', dotAll: true), (m) => 'You: ${T(m[1]!)}'),
];

String T(String s) {
  if (!isEn) return s;
  final d = _en[s];
  if (d != null) return d;
  for (final r in _enPat) {
    final m = r.$1.firstMatch(s);
    if (m != null) return r.$2(m);
  }
  return s;
}

class Text extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;
  const Text(this.data,
      {super.key, this.style, this.textAlign, this.maxLines, this.overflow, this.softWrap, this.textDirection});
  @override
  Widget build(BuildContext c) {
    Localizations.localeOf(c);
    return fw.Text(T(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        textDirection: textDirection);
  }
}

const _policyAr = """سياسة الخصوصية لتطبيق ORX
آخر تحديث: 13 أكتوبر 2026

1) من نحن
ORX تطبيق دردشة يعمل عبر البلوتوث والاتصال القريب، وعبر الإنترنت. توضح هذه السياسة المعلومات التي يتعامل معها التطبيق. للتواصل: $kContactEmail

2) المعلومات التي تقدمها
• اسم المستخدم والاسم وصورة الملف ونبذة قصيرة.
• الرسائل والصور والتسجيلات الصوتية والمنشورات والريلز (مقاطع الفيديو القصيرة) والقصص والتعليقات التي ترسلها.
• مفاتيح تشفير تُنشأ على جهازك لإثبات هويتك وتشفير رسائلك.

3) كيف تنتقل الرسائل
• الوضع القريب: تنتقل الرسائل مباشرة بين الجهازين عبر البلوتوث أو الواي فاي المباشر (Google Nearby Connections) ولا تمر عبر خوادمنا.
• وضع الإنترنت: تُشفَّر الرسائل على جهازك قبل رفعها. يخزن الخادم (المستضاف لدى Supabase) الرسالة المشفرة موجهة إلى المعرّف المجهول للمستلم إلى أن يستلمها جهازه. وتُشفَّر الصور والتسجيلات والملفات المرسلة في المحادثات قبل الرفع. لا نستطيع قراءة محتوى رسائلك.
• ما يمكن للخادم رؤيته: المعرّف المجهول للحساب، واسم المرسل، ومعرّف المستلم، ووقت وحجم الرسائل.

4) الملف العام والمحتوى العام
عند استخدام ميزات الإنترنت، تُخزَّن بيانات ملفك (اسم المستخدم، الاسم، النبذة، الصورة، المفاتيح العامة) على الخادم ويمكن لأي شخص العثور عليها بالبحث عن اسم المستخدم. لا تضع معلومات حساسة في ملفك. المنشورات والريلز والقصص والتعليقات وصورها وفيديوهاتها والإعجابات محتوى عام: تُخزَّن على الخادم دون تشفير من طرف إلى طرف ويمكن لمستخدمي التطبيق الآخرين رؤيتها. لا تنشر ما تريد إبقاءه خاصا. يمكنك الإبلاغ عن أي مستخدم أو محتوى وحظر أي مستخدم من داخل التطبيق، وقد نراجع البلاغات ونحذف المحتوى المخالف أو نوقف الحسابات المسيئة. كما نسجّل مشاهداتك للمنشورات والقصص وإعجاباتك على القصص ليرى صاحب المحتوى الأعداد فقط.

5) المعلومات المخزنة على جهازك
تُخزَّن المحادثات وجهات الاتصال والمنشورات والقصص والإعدادات ومفاتيحك الخاصة في مساحة التطبيق الخاصة على هاتفك. عند حذف التطبيق أو مسح بياناته تُحذف من جهازك ولا نستطيع استرجاعها.

6) الأذونات
• البلوتوث والأجهزة القريبة والموقع: يطلبها أندرويد للعثور على الأجهزة القريبة. لا نجمع موقعك ولا نخزنه.
• الميكروفون: فقط لتسجيل الرسائل الصوتية التي تختار إرسالها.
• الصور والملفات: فقط الصور التي تختارها بنفسك.
• الإنترنت: لاستخدام وضع الإنترنت.

7) ما لا نفعله
لا توجد إعلانات، ولا أدوات تحليل أو تتبع، ولا نبيع بياناتك ولا نشاركها مع المعلنين.

8) مزودو الخدمة
تستضيف Supabase قاعدة البيانات والمصادقة المجهولة وتخزين الملفات، وتنطبق سياسة الخصوصية الخاصة بها على معالجتها.

9) الاحتفاظ والحذف
قد تبقى الرسائل والملفات المشفرة على الخادم إلى أن تُحذف، وقد نحذف القديم منها دوريا. يمكنك حذف حسابك وكل بياناتك المخزنة على الخادم (الملف العام والمنشورات والريلز والقصص والتعليقات والرسائل والملفات) في أي وقت من داخل التطبيق: زر المظهر ثم حذف الحساب. ويمكنك أيضا مراسلتنا على البريد أعلاه مع اسم المستخدم.

10) الأمان
نستخدم تشفيرا من طرف إلى طرف لرسائل الإنترنت. لا يوجد نظام آمن بالكامل، فحافظ على حماية هاتفك.

11) الأطفال
التطبيق غير موجه للأطفال دون 13 عاما (أو الحد الأدنى للسن في بلدك).

12) التغييرات
قد نحدّث هذه السياسة، وسيتغير تاريخ آخر تحديث أعلاه.

13) التواصل
$kContactEmail""";

const _policyEn = """ORX Privacy Policy
Last updated: October 13, 2026

1) Who we are
ORX is a chat app that works over Bluetooth / nearby connections and over the internet. This policy explains what information the app handles. Contact: $kContactEmail

2) Information you provide
• Your username, display name, profile photo and short bio.
• Messages, photos, voice messages, posts, reels (short videos), stories and comments you send.
• Cryptographic keys generated on your device to prove your identity and encrypt your messages.

3) How messages travel
• Nearby mode: messages go directly between the two devices over Bluetooth or Wi-Fi Direct (Google Nearby Connections). They do not pass through our servers.
• Internet mode: messages are encrypted on your device before they are uploaded. Our server (hosted by Supabase) stores the encrypted message addressed to the recipient's anonymous ID until their device collects it. Photos, voice messages and files sent in chats are encrypted before upload. We cannot read the content of your messages.
• What the server can see: the anonymous account ID, the sender's username, the recipient's ID, and the time and size of messages.

4) Public profile and public content
When you use internet features, your profile data (username, display name, bio, photo, public keys) is stored on the server and can be found by anyone who searches for your username. Do not put sensitive information in your profile. Posts, reels, stories, comments, their photos and videos, and likes are public content: they are stored on the server without end-to-end encryption and can be seen by other users of the app. Do not publish anything you want to keep private. You can report any user or content and block any user from inside the app. We may review reports and remove violating content or suspend abusive accounts. We also record which posts and stories you view and your likes on stories, so that the content owner can see counts only.

5) Information stored on your device
Chats, contacts, posts, stories, settings and your private keys are kept in the app's private storage on your phone. If you uninstall the app or clear its data they are deleted from your device, and we cannot restore them.

6) Permissions
• Bluetooth / Nearby devices and Location: required by Android to find nearby devices. We do not collect or store your location.
• Microphone: only to record voice messages that you choose to send.
• Photos and files: only the pictures you choose yourself.
• Internet: to use internet mode.

7) What we do not do
No ads, no analytics or tracking tools, and we do not sell or share your data with advertisers.

8) Service providers
Supabase hosts the database, anonymous authentication and file storage. Its own privacy policy applies to its processing.

9) Retention and deletion
Encrypted messages and files may stay on the server until they are deleted, and we may delete old ones periodically. You can delete your account and all your server-side data (public profile, posts, reels, stories, comments, messages and files) at any time from inside the app: the appearance button, then Delete account. You can also email us at the address above with your username.

10) Security
We use end-to-end encryption for internet messages. No system is perfectly secure, so keep your phone protected.

11) Children
The app is not directed at children under 13 (or the minimum age in your country).

12) Changes
We may update this policy; the date above will change.

13) Contact
$kContactEmail""";

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});
  @override
  Widget build(BuildContext c) {
    Localizations.localeOf(c);
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(isEn ? _policyEn : _policyAr, style: const TextStyle(fontSize: 15, height: 1.6)),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final d = await getApplicationDocumentsDirectory();
    final f = File('${d.path}/orx_data2.json');
    if (await f.exists()) {
      final j = jsonDecode(await f.readAsString());
      final a = j['accent'];
      if (a is int && a >= 0 && a < accents.length) accentIdx.value = a;
      final lg = j['lang'];
      if (lg == 'ar' || lg == 'en') langCode.value = lg;
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
    popupMenuTheme: PopupMenuThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
    labelText: label == null ? null : T(label),
    hintText: hint == null ? null : T(hint),
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
  Widget build(BuildContext c) => ValueListenableBuilder<String>(
        valueListenable: langCode,
        builder: (c, lg, _) => ValueListenableBuilder<int>(
          valueListenable: accentIdx,
          builder: (c, ai, _) => ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (c, tm, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'ORX',
              locale: Locale(lg),
              supportedLocales: const [Locale('ar'), Locale('en')],
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
  String err = '', lastEx = '';
  DateTime exp = DateTime.fromMillisecondsSinceEpoch(0);
  String get noNet =>
      'مفيش اتصال بالإنترنت (${lastEx.length > 90 ? lastEx.substring(0, 90) : lastEx})';
  void Function()? onSession;

  Future<(int, dynamic)> rest(String method, String path,
      {Object? body, Map<String, String>? headers, bool auth = true}) async {
    try {
      final r = await hc.openUrl(method, Uri.parse('$sbUrl$path')).timeout(const Duration(seconds: 15));
      r.headers.set('apikey', sbKey);
      if (auth && at != null) r.headers.set('Authorization', 'Bearer $at');
      if (body != null) r.headers.set('Content-Type', 'application/json');
      headers?.forEach((k, v) => r.headers.set(k, v));
      if (body != null) r.add(utf8.encode(jsonEncode(body)));
      final res = await r.close().timeout(const Duration(seconds: 20));
      final txt = await res.transform(utf8.decoder).join();
      dynamic js;
      try {
        js = txt.isEmpty ? null : jsonDecode(txt);
      } catch (_) {
        js = txt;
      }
      return (res.statusCode, js);
    } catch (e) {
      lastEx = e.toString();
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

  Future<bool> uploadFile(String path, File f, String type) async {
    try {
      final r = await hc.openUrl('POST', Uri.parse('$sbUrl/storage/v1/object/orx/$path'));
      r.headers.set('apikey', sbKey);
      r.headers.set('Authorization', 'Bearer $at');
      r.headers.set('Content-Type', type);
      r.contentLength = await f.length();
      await r.addStream(f.openRead());
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
        err = noNet;
        return false;
      }
      if (r.$1 >= 500 || r.$1 == 429) {
        err = 'السيرفر مشغول، جرّب بعد شوية';
        return false;
      }
      at = null;
      rt = null;
      uid = null;
    }
    if (uid == null) {
      final r = await rest('POST', '/auth/v1/signup', body: {'data': {}}, auth: false);
      if (r.$1 == 200 && r.$2 is Map) {
        _ses(r.$2 as Map);
        return true;
      }
      err = r.$1 == -1
          ? noNet
          : (_msg(r.$2).toLowerCase().contains('anonymous')
              ? 'فعّل Anonymous sign-ins من إعدادات Supabase'
              : 'تعذر تسجيل الدخول للسيرفر (${r.$1})');
      return false;
    }
    err = 'انتهت جلسة الإنترنت';
    return false;
  }
}

class ReelPlayer extends StatefulWidget {
  final String url;
  final bool active;
  const ReelPlayer(this.url, this.active, {super.key});
  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late final VideoPlayerController c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool ready = false, failed = false;

  @override
  void initState() {
    super.initState();
    c.initialize().then((_) {
      if (!mounted) return;
      c.setLooping(true);
      setState(() => ready = true);
      if (widget.active) c.play();
    }).catchError((_) {
      if (mounted) setState(() => failed = true);
    });
  }

  @override
  void didUpdateWidget(ReelPlayer o) {
    super.didUpdateWidget(o);
    if (!ready) return;
    if (widget.active) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (failed) return const Center(child: Icon(Icons.error_outline, color: Colors.white54, size: 48));
    if (!ready) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: () => setState(() {
        if (c.value.isPlaying) {
          c.pause();
        } else {
          c.play();
        }
      }),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
        ),
      ),
    );
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
  bool im, srv;
  String kind;
  final DateTime at;
  Set<String> likes;
  Post(this.id, this.from, {this.text, this.img, this.ip, this.im = false, this.srv = false, this.kind = 'post', DateTime? at, Set<String>? likes})
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
        'kd': kind,
        'sv': srv,
        'a': at.millisecondsSinceEpoch,
        'l': likes.toList(),
      };
  factory Post.fromJson(Map j) => Post(j['i'], j['f'],
      text: j['t'],
      img: j['g'],
      im: j['m'] == true,
      ip: j['ip'],
      kind: (j['kd'] ?? 'post') as String,
      srv: j['sv'] == true,
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
  final String? text, img, sid;
  final DateTime at;
  Story(this.from, {this.text, this.img, this.sid, DateTime? at}) : at = at ?? DateTime.now();
  bool get live => DateTime.now().difference(at).inHours < 24;
  Color get color =>
      storyColors[(text ?? '').codeUnits.fold(0, (a, b) => a + b) % storyColors.length];
  Map toJson() => {'f': from, 't': text, 'i': img, 'x': sid, 'a': at.millisecondsSinceEpoch};
  factory Story.fromJson(Map j) =>
      Story(j['f'], text: j['t'], img: j['i'], sid: j['x'], at: DateTime.fromMillisecondsSinceEpoch(j['a']));
}

class StoryView extends StatefulWidget {
  final List<Story> l;
  final String title;
  final void Function(Story)? onSeen;
  final bool Function(Story)? liked;
  final void Function(Story)? onLike;
  final String Function(Story)? stat;
  const StoryView(this.l, this.title, {this.onSeen, this.liked, this.onLike, this.stat, super.key});
  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  int i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.l.isNotEmpty) widget.onSeen?.call(widget.l[0]);
    });
  }

  @override
  Widget build(BuildContext c) {
    final s0 = widget.l[i];
    Widget? bottom;
    if (widget.stat != null && s0.sid != null) {
      bottom = Text(widget.stat!(s0), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700));
    } else if (widget.onLike != null && s0.sid != null) {
      final liked = widget.liked?.call(s0) ?? false;
      bottom = IconButton(
        iconSize: 36,
        icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? Colors.red : Colors.white),
        onPressed: () {
          widget.onLike!(s0);
          setState(() {});
        },
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(widget.title)),
      body: Stack(children: [
        PageView(
          onPageChanged: (k) {
            setState(() => i = k);
            widget.onSeen?.call(widget.l[k]);
          },
          children: [
            for (final s in widget.l)
              GestureDetector(
                onTap: () => Navigator.pop(c),
                child: s.img != null
                    ? Center(child: Image.file(File(s.img!)))
                    : Container(
                        color: s.color,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        child: fw.Text(s.text!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
              ),
          ],
        ),
        if (bottom != null)
          Positioned(left: 0, right: 0, bottom: 28, child: Center(child: bottom)),
      ]),
    );
  }
}

/// calls onSeen once when the child is first built (lazy lists build only what is near the screen)
class ViewMark extends StatefulWidget {
  final VoidCallback onSeen;
  final Widget child;
  const ViewMark({required this.onSeen, required this.child, super.key});
  @override
  State<ViewMark> createState() => _ViewMarkState();
}

class _ViewMarkState extends State<ViewMark> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSeen();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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
        chatNet = j['chatNet'] != false;
        blocked.addAll(List<String>.from((j['blocked'] as List?) ?? []));
        myStoryLikes.addAll(List<String>.from((j['myStoryLikes'] as List?) ?? []));
        viewed.addAll(List<String>.from((j['viewed'] as List?) ?? []));
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
        'chatNet': chatNet,
        'blocked': blocked.toList(),
        'myStoryLikes': myStoryLikes.toList(),
        'viewed': viewed.toList(),
        'lang': langCode.value,
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

  Widget av(String? path, {double r = 22, IconData icon = Icons.person_rounded}) {
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
    if (!editing && await nameTaken(u)) {
      setState(() => nameState = 'taken');
      return snack('الاسم ده محجوز لشخص تاني، اختار اسم مختلف');
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
      children: [Flexible(child: fw.Text(text, style: st, overflow: TextOverflow.ellipsis)), badge(u)]);

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
    sendUser(u, {'k': 'c', 'l': [e]});
    if (netReady) srvInsert('certs', {'p': k, 'u': u, 'r': r, 't': t, 's': e['s']});
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

  void openPolicy() => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPage()));

  Widget setup() {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: editing ? const Text('تعديل الملف الشخصي') : logo(),
        leading: editing
            ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => editing = false))
            : null,
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
        if (!editing) ...[
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () {
                langCode.value = isEn ? 'ar' : 'en';
                save();
              },
              icon: const Icon(Icons.language),
              label: fw.Text(isEn ? 'العربية' : 'English'),
            ),
          ),
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
            onChanged: editing ? null : onNameChanged,
            decoration: fld(context, label: 'اسم المستخدم', icon: Icons.alternate_email).copyWith(
                helperText: editing
                    ? null
                    : (nameState == 'ok'
                        ? T('الاسم متاح ✓')
                        : (nameState == 'checking'
                            ? T('بنتأكد من الاسم...')
                            : T('حروف إنجليزية وأرقام و _ فقط، ومينفعش تتغيّر بعد كده'))),
                errorText: nameState == 'taken' ? T('الاسم ده محجوز لشخص تاني، اختار اسم مختلف') : null,
                suffixIcon: nameState == 'ok' ? const Icon(Icons.check_circle_rounded, color: Colors.green) : null)),
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
        if (!editing)
          TextButton(onPressed: openPolicy, child: const Text('بالمتابعة أنت توافق على سياسة الخصوصية')),
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
    if (netReady && chatNet) {
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
      for (final s in stories.where((s) => s.live && s.from == me!.u && s.sid == null)) {
        pushStory(id, s);
      }
      syncSocial(id, u);
      return;
    }
    final u = uOf(id);
    if (u == null) return;
    if (blocked.contains(u)) return;
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
    if (netReady && await cloud.ensure()) {
      final sid = '${me!.u}${DateTime.now().microsecondsSinceEpoch}';
      String? media;
      var ok = true;
      if (s.img != null) {
        media = 's/${cloud.uid}_${DateTime.now().microsecondsSinceEpoch}.jpg';
        ok = await cloud.upload(media, await File(s.img!).readAsBytes(), 'image/jpeg');
      }
      if (ok && await srvInsert('stories', {'id': sid, 'author': me!.u, 'body': s.text, 'media': media})) {
        setState(() => stories.add(Story(me!.u, text: s.text, img: s.img, sid: sid, at: s.at)));
        save();
        return;
      }
      snack('تعذر نشر القصة على الإنترنت، اتحفظت للقريبين منك');
    }
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
    for (final s in stories.where((s) => s.live && !blocked.contains(s.from))) {
      (by[s.from] ??= []).add(s);
    }
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        children: [
          ring('إضافة', const CircleAvatar(radius: 22, child: Icon(Icons.add_rounded)), addStory, false),
          for (final e in by.entries)
            ring(
              e.key == me!.u ? 'قصتي' : prof(e.key).n,
              av(prof(e.key).a),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => StoryView(
                            e.value,
                            prof(e.key).n,
                            onSeen: (st) => markViewed('story', st.sid, e.key),
                            liked: (st) => st.sid != null && myStoryLikes.contains(st.sid),
                            onLike: e.key == me!.u ? null : (st) => toggleStoryLike(st),
                            stat: e.key == me!.u
                                ? (st) => '👁 ${sviews[st.sid] ?? 0}    ❤ ${slikes[st.sid] ?? 0}'
                                : null,
                          ))),
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
    WidgetsBinding.instance.removeObserver(this);
    recTimer?.cancel();
    poll?.cancel();
    socialTimer?.cancel();
    reelCtl.dispose();
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
    final title = c.startsWith('p:') ? nm(c.substring(2), chatTitle(c), st: bold) : fw.Text(chatTitle(c), style: bold);
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

  void openProf(String u) {
    setState(() {
      if (view != 'profile') back = view;
      view = 'profile';
      profU = u;
    });
    fetchUser(u);
  }

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
    final sel = view == 'feed' ? 1 : (view == 'reels' ? 2 : (view == 'profile' ? 3 : 0));
    final items = <List<Object>>[
      [Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'المحادثات'],
      [Icons.grid_view_outlined, Icons.grid_view_rounded, 'المنشورات'],
      [Icons.smart_display_outlined, Icons.smart_display_rounded, 'ريلز'],
      [Icons.person_outline_rounded, Icons.person_rounded, 'حسابي'],
    ];
    void go(int i) {
      HapticFeedback.selectionClick();
      setState(() {
        back = 'home';
        if (i == 3) {
          view = 'profile';
          profU = me!.u;
        } else {
          view = const ['home', 'feed', 'reels'][i];
        }
      });
      if (i == 1 || i == 2) pullSocial();
      if (i == 3) fetchUser(me!.u);
    }

    Widget item(int i) {
      final active = sel == i;
      final ic = items[i][0] as IconData;
      final sic = items[i][1] as IconData;
      final label = items[i][2] as String;
      return Semantics(
        button: true,
        selected: active,
        label: T(label),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => go(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: active ? 18 : 13, vertical: 11),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.55)!])
                  : null,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(active ? sic : ic, size: 24, color: active ? cs.onPrimary : cs.onSurfaceVariant),
              if (active) ...[
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ]),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(33),
            border: Border.all(color: cs.outlineVariant.withAlpha(90)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(45), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (var i = 0; i < items.length; i++) item(i)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    Localizations.localeOf(c);
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
              ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: goHome)
              : (otherProf
                  ? IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: goBack)
                  : IconButton(
                      tooltip: T('المظهر'), icon: const Icon(Icons.palette_rounded), onPressed: appearance)),
          title: inChat
              ? chatHead()
              : (otherProf
                  ? nm(profU, '\u200e@$profU', st: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))
                  : Row(mainAxisSize: MainAxisSize.min, children: [logo(), badge(me!.u)])),
          actions: [
            if (otherProf) userMenu(profU),
            if (inChat && cur!.startsWith('p:')) userMenu(cur!.substring(2)),
            if (view == 'home')
              IconButton(
                  tooltip: T('بحث عن أجهزة قريبة'),
                  icon: const Icon(Icons.bluetooth_searching_rounded),
                  onPressed: () => setState(() => view = 'near')),
            if (view == 'home')
              IconButton(
                  tooltip: T('إضافة صديق'),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  onPressed: findFriend),
            if (owner)
              IconButton(
                  tooltip: T('أعضاء المجموعة'), icon: const Icon(Icons.group_add_outlined), onPressed: manage),
          ],
        ),
        body: view == 'home'
            ? home()
            : (view == 'feed'
                ? feed()
                : (view == 'reels'
                    ? reelsView()
                    : (view == 'near' ? near() : (view == 'profile' ? profileView(profU) : chat())))),
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
    final sub = last == null
        ? T('ابدأ المحادثة')
        : '${last.s == me!.u ? (isEn ? 'You: ' : 'أنت: ') : ''}${last.t ?? (last.aud != null ? T('🎤 رسالة صوتية') : T('📷 صورة'))}';
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
                  c.startsWith('p:') ? nm(c.substring(2), title, st: bold) : fw.Text(title, style: bold),
                  const SizedBox(height: 3),
                  fw.Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ]),
              ),
              if (last != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(msgTime(last.i), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
    final pl = contacts.values.where((p) => p.u != me!.u && !blocked.contains(p.u) && (hit(p.n) || hit(p.u))).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 12), children: [
      storiesBar(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: TextField(
          controller: sCtl,
          onChanged: (_) => setState(() {}),
          decoration: fld(context, hint: 'ابحث في المحادثات', icon: Icons.search_rounded).copyWith(
            suffixIcon: qs.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
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
                      child: Icon(Icons.group_add_rounded, color: cs.onPrimary)),
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
      for (final g in gl) tile('g:${g.o}', g.n, null, Icons.group_rounded),
      for (final p in pl) tile('p:${p.u}', p.n, p.a, Icons.person_rounded),
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
                    icon: const Icon(Icons.bluetooth_searching_rounded),
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
          Icon(on ? Icons.radar : Icons.bluetooth_searching_rounded, size: 36, color: cs.onPrimary),
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
              icon: const Icon(Icons.bluetooth_searching_rounded),
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
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text('\u200e@${e.value}', style: bold),
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    if (st == AppLifecycleState.resumed) {
      if (netReady) startNet();
    } else if (st == AppLifecycleState.paused) {
      poll?.cancel();
      socialTimer?.cancel();
    }
  }

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
      netMsg = 'اسم المستخدم @${me!.u} مستخدم على الإنترنت من حساب تاني. من المظهر اختار إعادة ضبط التطبيق وسجّل باسم تاني';
    } else {
      netMsg = r.$1 == -1 ? cloud.noNet : 'تعذر التسجيل على الإنترنت (${r.$1})';
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
    socialTimer?.cancel();
    socialTimer = Timer.periodic(const Duration(seconds: 45), (_) => pullSocial());
    pullSocial();
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
    if (blocked.contains(fu)) return true;
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

  Future<String> probe() async {
    final b = StringBuffer();
    for (final h in ['google.com', 'supabase.co', Uri.parse(sbUrl).host]) {
      try {
        final r = await InternetAddress.lookup(h).timeout(const Duration(seconds: 8));
        b.writeln('DNS $h: OK ${r.isNotEmpty ? r.first.address : ''}');
      } catch (e) {
        b.writeln('DNS $h: FAIL $e');
      }
    }
    final r = await cloud.rest('GET', '/auth/v1/health', auth: false);
    b.writeln('HTTP health: ${r.$1} ${r.$1 == -1 ? cloud.lastEx : ''}');
    b.writeln('');
    b.writeln('state: ${cloud.err}');
    return b.toString();
  }

  void netDiag() => showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('فحص الاتصال'),
          content: SingleChildScrollView(
            child: FutureBuilder<String>(
              future: probe(),
              builder: (c, snap) => SelectableText(snap.data ?? '...', textDirection: TextDirection.ltr),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                initNet();
              },
              child: const Text('إعادة المحاولة'),
            ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
          ],
        ),
      );

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
                decoration: fld(c, hint: 'ابحث باسم المستخدم', icon: Icons.search_rounded),
              ),
              if (busy) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
              Flexible(
                child: ListView(shrinkWrap: true, children: [
                  for (final e in res)
                    if (e['u'] != me!.u)
                      ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                        title: Text((e['n'] ?? '') as String),
                        subtitle: Text('\u200e@${e['u']}'),
                        trailing: const Icon(Icons.add_rounded),
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

  // ---------- internet: public posts, reels, stories ----------
  final explore = <Post>[], reelsList = <Post>[];
  final userPosts = <String, List<Post>>{};
  final blocked = <String>{}, myStoryLikes = <String>{}, viewed = <String>{};
  final vcount = <String, int>{}, sviews = <String, int>{}, slikes = <String, int>{};
  final viewQueue = <Map>[];
  Timer? viewTimer, nameTimer;
  String nameState = '';
  final ccount = <String, int>{};
  bool certsPushed = false;
  bool chatNet = true, uploading = false, exploreTab = false, socialBusy = false;
  int reelIdx = 0;
  PageController reelCtl = PageController();
  Timer? socialTimer;

  String pubUrl(String p) => '$sbUrl/storage/v1/object/public/orx/$p';

  Future<bool> srvInsert(String table, Map row) async {
    final r = await cloud.rest('POST', '/rest/v1/$table', headers: {'Prefer': 'return=minimal'}, body: row);
    return r.$1 == 201;
  }

  Post? rowToPost(Map r) {
    try {
      final kind = (r['kind'] ?? 'post') as String;
      final media = r['media'] as String?;
      return Post(r['id'] as String, r['author'] as String,
          text: r['body'] as String?,
          ip: media,
          kind: kind,
          srv: true,
          im: kind == 'post' && media != null,
          at: DateTime.parse(r['created_at'] as String).toLocal());
    } catch (_) {
      return null;
    }
  }

  void mergePost(Post p) {
    final ex = posts.where((x) => x.id == p.id).firstOrNull;
    if (ex == null) {
      posts.add(p);
    } else {
      ex.srv = true;
      ex.ip = p.ip;
    }
  }

  Future<void> syncLikes(List<Post> l) async {
    if (l.isEmpty) return;
    final ids = {for (final p in l) p.id}.toList();
    final rcm = await cloud.rest('GET', '/rest/v1/comments?post_id=in.(${ids.join(',')})&select=post_id&limit=5000');
    if (rcm.$1 == 200 && rcm.$2 is List) {
      final cm = <String, int>{};
      for (final e in (rcm.$2 as List)) {
        final k = e['post_id'] as String;
        cm[k] = (cm[k] ?? 0) + 1;
      }
      for (final p in l) {
        ccount[p.id] = cm[p.id] ?? 0;
      }
    }
    final r = await cloud.rest('GET', '/rest/v1/likes?post_id=in.(${ids.join(',')})&select=post_id,u&limit=5000');
    if (r.$1 != 200 || r.$2 is! List) return;
    final m = <String, Set<String>>{};
    for (final e in (r.$2 as List)) {
      (m[e['post_id'] as String] ??= {}).add(e['u'] as String);
    }
    for (final p in l) {
      p.likes = m[p.id] ?? <String>{};
      if (p.likes.contains(me!.u)) {
        myLikes.add(p.id);
      } else {
        myLikes.remove(p.id);
      }
    }
  }

  Future<void> pullSocial() async {
    if (!netReady || me == null || socialBusy) return;
    socialBusy = true;
    try {
      if (!await cloud.ensure()) return;
      bool mf(String a) => a == me!.u || following.contains(a);
      final r = await cloud.rest('GET', '/rest/v1/posts?select=*&kind=eq.post&order=created_at.desc&limit=80');
      final rr = await cloud.rest('GET', '/rest/v1/posts?select=*&kind=eq.reel&order=created_at.desc&limit=30');
      if (r.$1 == 200 && r.$2 is List) {
        final rows = r.$2 as List;
        final ex = <Post>[];
        final ids = <String>{};
        DateTime oldest = DateTime.fromMillisecondsSinceEpoch(0);
        for (final row in rows) {
          final p = rowToPost(Map.from(row as Map));
          if (p == null || blocked.contains(p.from)) continue;
          ids.add(p.id);
          oldest = p.at;
          if (mf(p.from)) {
            mergePost(p);
          } else {
            ex.add(p);
          }
        }
        if (rows.length < 80) oldest = DateTime.fromMillisecondsSinceEpoch(0);
        posts.removeWhere((p) => p.srv && p.kind == 'post' && !ids.contains(p.id) && !p.at.isBefore(oldest));
        explore
          ..clear()
          ..addAll(ex);
      }
      if (rr.$1 == 200 && rr.$2 is List) {
        final l = <Post>[];
        for (final row in rr.$2 as List) {
          final p = rowToPost(Map.from(row as Map));
          if (p != null && !blocked.contains(p.from)) l.add(p);
        }
        reelsList
          ..clear()
          ..addAll(l);
      }
      await syncLikes(<Post>[...posts.where((p) => p.srv), ...explore, ...reelsList]);

      final since = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
      final rs = await cloud.rest('GET',
          '/rest/v1/stories?select=*&created_at=gt.${Uri.encodeComponent(since)}&order=created_at.asc&limit=100');
      if (rs.$1 == 200 && rs.$2 is List) {
        final dir = await getApplicationDocumentsDirectory();
        for (final row in rs.$2 as List) {
          final m = Map.from(row as Map);
          final a = m['author'] as String;
          final sid = m['id'] as String;
          if (!mf(a) || blocked.contains(a) || stories.any((s) => s.sid == sid)) continue;
          final media = m['media'] as String?;
          String? pth;
          if (media != null) {
            final b = await cloud.download(media);
            if (b == null) continue;
            pth = '${dir.path}/st_$sid.jpg';
            await File(pth).writeAsBytes(b);
          }
          stories.add(Story(a,
              text: m['body'] as String?,
              img: pth,
              sid: sid,
              at: DateTime.parse(m['created_at'] as String).toLocal()));
        }
        stories.removeWhere((s) => !s.live);
      }
      if (isOwner && !certsPushed && certs.isNotEmpty) {
        final rp = await cloud.rest('POST', '/rest/v1/certs',
            headers: {'Prefer': 'return=minimal,resolution=ignore-duplicates'}, body: certs.values.toList());
        if (rp.$1 >= 200 && rp.$1 < 300) certsPushed = true;
      }
      final rc = await cloud.rest('GET', '/rest/v1/certs?select=*&order=t.desc&limit=500');
      if (rc.$1 == 200 && rc.$2 is List) await mergeCerts(rc.$2 as List);
      await pullOwnerStats();
      if (mounted) setState(() {});
      save();
    } catch (_) {
    } finally {
      socialBusy = false;
    }
  }

  Future<void> fetchUser(String u) async {
    if (!netReady || !await cloud.ensure()) return;
    final r = await cloud.rest(
        'GET', '/rest/v1/posts?select=*&author=eq.${Uri.encodeComponent(u)}&order=created_at.desc&limit=60');
    if (r.$1 != 200 || r.$2 is! List) return;
    final l = <Post>[];
    for (final row in r.$2 as List) {
      final p = rowToPost(Map.from(row as Map));
      if (p != null && !blocked.contains(p.from)) l.add(p);
    }
    await syncLikes(l);
    if (mounted) setState(() => userPosts[u] = l);
  }

  void openReels(Post x) {
    var i = reelsList.indexWhere((p) => p.id == x.id);
    if (i < 0) {
      reelsList.insert(0, x);
      i = 0;
    }
    reelCtl.dispose();
    reelCtl = PageController(initialPage: i);
    setState(() {
      reelIdx = i;
      view = 'reels';
    });
  }

  Future<void> newReel() async {
    if (!netReady) return snack(netMsg.isEmpty ? 'الإنترنت لسه بيتجهز، جرّب بعد ثواني' : netMsg);
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: const Text('تصوير فيديو'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.video_library_outlined),
            title: const Text('من المعرض'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (src == null) return;
    final f = await ImagePicker().pickVideo(source: src, maxDuration: const Duration(seconds: 60));
    if (f == null) return;
    final file = File(f.path);
    if (await file.length() > 45 * 1024 * 1024) return snack('الفيديو كبير، الحد الأقصى 45 ميجا');
    if (!mounted) return;
    final t = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ريل جديد'),
        content: TextField(controller: t, maxLength: 200, decoration: InputDecoration(hintText: T('اكتب تعليق...'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('نشر')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => uploading = true);
    try {
      if (!await cloud.ensure()) return;
      final id = '${me!.u}${DateTime.now().microsecondsSinceEpoch}';
      final path = 'r/${cloud.uid}_${DateTime.now().microsecondsSinceEpoch}.mp4';
      if (!await cloud.uploadFile(path, file, 'video/mp4')) return snack('تعذر رفع الفيديو');
      final body = t.text.trim();
      if (await srvInsert('posts', {'id': id, 'author': me!.u, 'kind': 'reel', 'body': body.isEmpty ? null : body, 'media': path})) {
        snack('تم نشر الريل');
        await pullSocial();
      } else {
        snack('تعذر نشر الريل');
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Widget reelPage(Post p, bool active) {
    final pr = prof(p.from);
    final liked = myLikes.contains(p.id);
    final isFol = following.contains(p.from);
    final cap = (p.text ?? '').trim();
    const white = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    return Container(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        ReelPlayer(pubUrl(p.ip ?? ''), active && view == 'reels', key: ValueKey(p.id)),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xB3000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 16,
          end: 84,
          bottom: 24,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => openProf(p.from),
              child: Row(children: [
                av(pr.a, r: 18),
                const SizedBox(width: 8),
                Flexible(child: fw.Text(pr.n, style: white, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (p.from != me!.u) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        visualDensity: VisualDensity.compact),
                    onPressed: () => toggleFollow(p.from),
                    child: fw.Text(T(isFol ? 'إلغاء المتابعة' : 'متابعة')),
                  ),
                ],
              ]),
            ),
            if (cap.isNotEmpty) ...[
              const SizedBox(height: 8),
              fw.Text(cap, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
            ],
          ]),
        ),
        PositionedDirectional(
          end: 8,
          bottom: 24,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? Colors.red : Colors.white, size: 32),
              onPressed: () => toggleLike(p),
            ),
            fw.Text('${p.likes.length}', style: white),
            const SizedBox(height: 8),
            IconButton(
                icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28),
                onPressed: () => showComments(p)),
            fw.Text('${ccount[p.id] ?? 0}', style: white),
            const SizedBox(height: 8),
            IconButton(icon: const Icon(Icons.share_rounded, color: Colors.white, size: 30), onPressed: () => sharePost(p)),
            if (p.from == me!.u)
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30), onPressed: () => delPost(p, false))
            else
              userMenu(p.from, postId: p.id, color: Colors.white),
            if (p.from == me!.u) ...[
              const SizedBox(height: 4),
              const Icon(Icons.visibility_outlined, color: Colors.white, size: 24),
              fw.Text('${vcount[p.id] ?? 0}', style: white),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget reelsView() {
    if (reelsList.isEmpty) {
      return empty(Icons.smart_display_outlined, 'مفيش ريلز لسه', 'انشر أول ريل',
          action: FilledButton.icon(
              onPressed: uploading ? null : newReel,
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('ريل جديد')));
    }
    if (reelIdx >= reelsList.length) reelIdx = 0;
    final cr = reelsList[reelIdx];
    if (cr.srv) markViewed('post', cr.id, cr.from);
    return Stack(children: [
      PageView.builder(
        controller: reelCtl,
        scrollDirection: Axis.vertical,
        itemCount: reelsList.length,
        onPageChanged: (i) => setState(() => reelIdx = i),
        itemBuilder: (c, i) => reelPage(reelsList[i], i == reelIdx),
      ),
      PositionedDirectional(
        top: 8,
        end: 12,
        child: FilledButton.tonalIcon(
          onPressed: uploading ? null : newReel,
          icon: const Icon(Icons.video_call_outlined),
          label: const Text('ريل جديد'),
        ),
      ),
      if (uploading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
    ]);
  }

  // ---------- safety: block, report, delete account, comments ----------
  String msgTime(String id) {
    if (id.length < 16) return '';
    final us = int.tryParse(id.substring(id.length - 16));
    if (us == null) return '';
    final d = DateTime.fromMicrosecondsSinceEpoch(us);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void blockUser(String u) {
    setState(() {
      blocked.add(u);
      following.remove(u);
      followers.remove(u);
      stories.removeWhere((s) => s.from == u);
      if (cur == 'p:$u') cur = null;
      if (view == 'chat' && cur == null) view = 'home';
      if (view == 'profile' && profU == u) view = 'home';
    });
    save();
    snack('تم الحظر');
  }

  void unblockUser(String u) {
    setState(() => blocked.remove(u));
    save();
    snack('تم إلغاء الحظر');
  }

  Widget userMenu(String u, {String? postId, Color? color}) {
    if (u == me!.u) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: color),
      onSelected: (v) {
        if (v == 'r') {
          reportDialog(u, postId: postId);
        } else if (v == 'b') {
          if (blocked.contains(u)) {
            unblockUser(u);
          } else {
            blockUser(u);
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'r', child: Text(postId != null ? 'إبلاغ عن المحتوى' : 'إبلاغ عن المستخدم')),
        PopupMenuItem(value: 'b', child: Text(blocked.contains(u) ? 'إلغاء الحظر' : 'حظر المستخدم')),
      ],
    );
  }

  Future<void> reportDialog(String target, {String? postId}) async {
    const reasons = ['محتوى مزعج أو سبام', 'محتوى غير لائق', 'تحرش أو إساءة', 'انتحال شخصية', 'سبب آخر'];
    var sel = 0;
    final t = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, st) => AlertDialog(
          title: Text(postId != null ? 'إبلاغ عن المحتوى' : 'إبلاغ عن المستخدم'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < reasons.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(sel == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: Theme.of(c).colorScheme.primary),
                  title: Text(reasons[i]),
                  onTap: () => st(() => sel = i),
                ),
              TextField(
                controller: t,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(hintText: T('تفاصيل إضافية (اختياري)')),
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
    if (!netReady || !await cloud.ensure()) return snack('الإبلاغ يحتاج إنترنت');
    final done = await srvInsert('reports', {
      'reporter': me!.u,
      'target': target,
      'post_id': postId,
      'reason': reasons[sel],
      'details': t.text.trim(),
    });
    snack(done ? 'تم إرسال البلاغ، شكراً لك' : 'تعذر إرسال البلاغ');
  }

  void showBlocked() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (c) => StatefulBuilder(
          builder: (c, st) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('الحسابات المحظورة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                Flexible(
                  child: blocked.isEmpty
                      ? const Padding(padding: EdgeInsets.all(32), child: Text('مفيش حسابات محظورة'))
                      : ListView(shrinkWrap: true, children: [
                          for (final u in blocked.toList())
                            ListTile(
                              leading: av(prof(u).a),
                              title: nm(u, prof(u).n),
                              subtitle: Text('\u200e@$u'),
                              trailing: TextButton(
                                onPressed: () {
                                  unblockUser(u);
                                  st(() {});
                                },
                                child: const Text('إلغاء الحظر'),
                              ),
                            ),
                        ]),
                ),
              ]),
            ),
          ),
        ),
      );

  Future<void> confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
            'هيتم حذف حسابك وكل بياناتك نهائياً من السيرفر ومن الجهاز: الملف الشخصي والمنشورات والقصص والتعليقات والرسائل. مينفعش نرجّعها بعد كده.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(c).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (ok == true) await deleteAccount();
  }

  Future<void> purgeMedia() async {
    try {
      final id = cloud.uid;
      if (id == null) return;
      final names = <String>[];
      for (final f in ['a', 'p', 's', 'r', 'm']) {
        final r = await cloud.rest('POST', '/storage/v1/object/list/orx',
            body: {'prefix': f, 'limit': 1000, 'search': id});
        if (r.$1 == 200 && r.$2 is List) {
          for (final o in (r.$2 as List)) {
            final n = (o as Map)['name'];
            if (n is String && n.contains(id)) names.add('$f/$n');
          }
        }
      }
      if (names.isNotEmpty) await cloud.rest('DELETE', '/storage/v1/object/orx', body: {'prefixes': names});
    } catch (_) {}
  }

  Future<void> deleteAccount() async {
    if (!await cloud.ensure()) return snack('لازم تكون متصل بالإنترنت عشان تحذف الحساب');
    await purgeMedia();
    final r = await cloud.rest('POST', '/rest/v1/rpc/delete_my_account', body: {});
    if (r.$1 < 200 || r.$1 >= 300) return snack('تعذر حذف الحساب من السيرفر، جرّب تاني');
    await wipeLocal();
  }

  Future<void> confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إعادة ضبط التطبيق'),
        content: const Text(
            'هيتمسح كل اللي على الجهاز ده (المحادثات والمفاتيح والإعدادات) وترجع تسجّل من الأول باسم مستخدم جديد. حسابك القديم على السيرفر مش هيتحذف (لو عايز تحذفه استخدم حذف الحساب).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('إعادة ضبط')),
        ],
      ),
    );
    if (ok == true) await wipeLocal();
  }

  Future<void> wipeLocal() async {
    poll?.cancel();
    socialTimer?.cancel();
    try {
      Nearby().stopAllEndpoints();
      Nearby().stopAdvertising();
      Nearby().stopDiscovery();
    } catch (_) {}
    try {
      final d = await getApplicationDocumentsDirectory();
      for (final f in d.listSync()) {
        try {
          f.deleteSync(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
    cloud.at = null;
    cloud.rt = null;
    cloud.uid = null;
    lastMsgId = 0;
    cavSrc = null;
    cav = null;
    xkp = null;
    uCtl.clear();
    nCtl.clear();
    bCtl.clear();
    kCtl.clear();
    nameState = '';
    viewed.clear();
    myStoryLikes.clear();
    if (!mounted) return;
    setState(() {
      contacts.clear();
      msgs.clear();
      groups.clear();
      stories.clear();
      certs.clear();
      posts.clear();
      following.clear();
      followers.clear();
      myLikes.clear();
      blocked.clear();
      stats.clear();
      explore.clear();
      reelsList.clear();
      userPosts.clear();
      cprof.clear();
      avSeen.clear();
      outbox.clear();
      ccount.clear();
      who.clear();
      peers.clear();
      tmpAv = null;
      cur = null;
      view = 'home';
      editing = false;
      on = false;
      netReady = false;
      netMsg = '';
      me = null;
    });
  }

  Future<void> showComments(Post p) async {
    if (!p.srv) return snack('التعليقات بتحتاج إنترنت');
    if (!netReady) return snack(netMsg.isEmpty ? 'الإنترنت لسه بيتجهز، جرّب بعد ثواني' : netMsg);
    final t = TextEditingController();
    var list = <Map>[];
    var loading = true;
    var started = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, st) {
          Future<void> load() async {
            final r = await cloud.rest('GET',
                '/rest/v1/comments?post_id=eq.${Uri.encodeComponent(p.id)}&order=created_at.asc&limit=200');
            if (r.$1 == 200 && r.$2 is List) {
              list = [for (final e in (r.$2 as List)) Map.from(e as Map)];
              ccount[p.id] = list.length;
            }
            if (mounted) {
              st(() => loading = false);
              setState(() {});
            }
          }

          Future<void> send() async {
            final body = t.text.trim();
            if (body.isEmpty) return;
            t.clear();
            final id = '${me!.u}${DateTime.now().microsecondsSinceEpoch}';
            final ok = await srvInsert('comments', {'id': id, 'post_id': p.id, 'author': me!.u, 'body': body});
            if (!ok) snack('تعذر إرسال التعليق');
            await load();
          }

          if (!started) {
            started = true;
            load();
          }
          final shown = list.where((e) => !blocked.contains(e['author'])).toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(c).viewInsets.bottom + 12),
            child: SizedBox(
              height: MediaQuery.of(c).size.height * 0.6,
              child: Column(children: [
                const Text('التعليقات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : (shown.isEmpty
                          ? empty(Icons.mode_comment_outlined, 'مفيش تعليقات لسه', 'كن أول من يعلّق')
                          : ListView(children: [
                              for (final e in shown)
                                ListTile(
                                  leading: av(prof(e['author'] as String).a, r: 16),
                                  title: nm(e['author'] as String, prof(e['author'] as String).n,
                                      st: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  subtitle: fw.Text((e['body'] ?? '') as String),
                                  trailing: e['author'] == me!.u
                                      ? IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded),
                                          onPressed: () async {
                                            await cloud.rest('DELETE',
                                                '/rest/v1/comments?id=eq.${Uri.encodeComponent(e['id'] as String)}');
                                            await load();
                                          },
                                        )
                                      : userMenu(e['author'] as String, postId: p.id),
                                ),
                            ])),
                ),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: t,
                      minLines: 1,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: fld(c, hint: 'اكتب تعليق...').copyWith(counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(icon: const Icon(Icons.send_rounded), onPressed: send),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ---------- views, story likes, username check ----------
  void markViewed(String kind, String? id, String owner) {
    if (id == null || me == null || owner == me!.u || !netReady) return;
    final key = '$kind:$id';
    if (viewed.contains(key)) return;
    viewed.add(key);
    if (viewed.length > 800) viewed.remove(viewed.first);
    viewQueue.add({'kind': kind, 'item_id': id, 'viewer': me!.u});
    viewTimer ??= Timer(const Duration(seconds: 2), flushViews);
  }

  Future<void> flushViews() async {
    viewTimer = null;
    if (viewQueue.isEmpty) return;
    final batch = List<Map>.of(viewQueue);
    viewQueue.clear();
    void undo() {
      for (final b in batch) {
        viewed.remove('${b['kind']}:${b['item_id']}');
      }
    }

    if (!await cloud.ensure()) return undo();
    final r = await cloud.rest('POST', '/rest/v1/views',
        headers: {'Prefer': 'return=minimal,resolution=ignore-duplicates'}, body: batch);
    if (r.$1 < 200 || r.$1 >= 300) undo();
    save();
  }

  Future<void> toggleStoryLike(Story s) async {
    final id = s.sid;
    if (id == null) return;
    final v = !myStoryLikes.contains(id);
    setState(() {
      if (v) {
        myStoryLikes.add(id);
      } else {
        myStoryLikes.remove(id);
      }
    });
    save();
    if (!await cloud.ensure()) return;
    final r = v
        ? await cloud.rest('POST', '/rest/v1/story_likes',
            headers: {'Prefer': 'return=minimal,resolution=ignore-duplicates'},
            body: {'story_id': id, 'u': me!.u})
        : await cloud.rest('DELETE', '/rest/v1/story_likes?story_id=eq.${Uri.encodeComponent(id)}&u=eq.${me!.u}');
    if (r.$1 < 200 || r.$1 >= 300) snack('تعذر تسجيل الإعجاب');
  }

  Future<void> pullOwnerStats() async {
    final pids = <String>{
      for (final p in posts)
        if (p.srv && p.from == me!.u) p.id,
      for (final p in reelsList)
        if (p.from == me!.u) p.id,
      for (final p in (userPosts[me!.u] ?? <Post>[])) p.id,
    }.toList();
    if (pids.isNotEmpty) {
      final r = await cloud.rest('GET', '/rest/v1/views?kind=eq.post&item_id=in.(${pids.join(',')})&select=item_id&limit=10000');
      if (r.$1 == 200 && r.$2 is List) {
        vcount.clear();
        for (final e in (r.$2 as List)) {
          final k = e['item_id'] as String;
          vcount[k] = (vcount[k] ?? 0) + 1;
        }
      }
    }
    final sids = [
      for (final s in stories)
        if (s.from == me!.u && s.sid != null && s.live) s.sid!,
    ];
    if (sids.isNotEmpty) {
      final j = sids.join(',');
      final r1 = await cloud.rest('GET', '/rest/v1/views?kind=eq.story&item_id=in.($j)&select=item_id&limit=10000');
      if (r1.$1 == 200 && r1.$2 is List) {
        sviews.clear();
        for (final e in (r1.$2 as List)) {
          final k = e['item_id'] as String;
          sviews[k] = (sviews[k] ?? 0) + 1;
        }
      }
      final r2 = await cloud.rest('GET', '/rest/v1/story_likes?story_id=in.($j)&select=story_id&limit=10000');
      if (r2.$1 == 200 && r2.$2 is List) {
        slikes.clear();
        for (final e in (r2.$2 as List)) {
          final k = e['story_id'] as String;
          slikes[k] = (slikes[k] ?? 0) + 1;
        }
      }
    }
  }

  Future<bool> nameTaken(String u) async {
    try {
      if (!await cloud.ensure()) return false;
      final r = await cloud.rest('GET', '/rest/v1/profiles?u=eq.${Uri.encodeComponent(u)}&select=u,uid');
      if (r.$1 == 200 && r.$2 is List && (r.$2 as List).isNotEmpty) {
        final row = (r.$2 as List).first as Map;
        return row['uid'] != cloud.uid;
      }
    } catch (_) {}
    return false;
  }

  void onNameChanged(String v) {
    nameTimer?.cancel();
    final u = v.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u)) {
      setState(() => nameState = '');
      return;
    }
    setState(() => nameState = 'checking');
    nameTimer = Timer(const Duration(milliseconds: 600), () async {
      final t = await nameTaken(u);
      if (!mounted || uCtl.text.trim().toLowerCase() != u) return;
      setState(() => nameState = t ? 'taken' : 'ok');
    });
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
    if (p.srv) {
      srvLike(p, v);
    } else if (p.from != me!.u) {
      sendUser(p.from, {'k': 'pl', 'i': p.id, 'v': v});
    }
  }

  Future<void> srvLike(Post p, bool v) async {
    if (!await cloud.ensure()) return;
    final r = v
        ? await cloud.rest('POST', '/rest/v1/likes',
            headers: {'Prefer': 'return=minimal,resolution=ignore-duplicates'},
            body: {'post_id': p.id, 'u': me!.u})
        : await cloud.rest('DELETE', '/rest/v1/likes?post_id=eq.${p.id}&u=eq.${me!.u}');
    if (r.$1 < 200 || r.$1 >= 300) snack('تعذر تسجيل الإعجاب');
  }

  Future<void> publishPost(String? text, String? img) async {
    final p = Post('${me!.u}${DateTime.now().microsecondsSinceEpoch}', me!.u,
        text: text, img: img, im: img != null);
    setState(() => posts.add(p));
    save();
    if (netReady && await cloud.ensure()) {
      String? media;
      var ok = true;
      if (img != null) {
        media = 'p/${cloud.uid}_${DateTime.now().microsecondsSinceEpoch}.jpg';
        ok = await cloud.upload(media, await File(img).readAsBytes(), 'image/jpeg');
      }
      if (ok && await srvInsert('posts', {'id': p.id, 'author': me!.u, 'kind': 'post', 'body': text, 'media': media})) {
        setState(() {
          p.srv = true;
          p.ip = media;
        });
        save();
        return;
      }
      snack('تعذر النشر على الإنترنت، اتحفظ عندك وهيوصل للقريبين منك');
    }
    for (final id in peers.where((id) => who.containsKey(id))) {
      sendJ(id, postMeta(p));
    }
  }

  void delPost(Post p, bool inSheet) {
    setState(() {
      posts.remove(p);
      explore.remove(p);
      reelsList.remove(p);
      for (final l in userPosts.values) {
        l.removeWhere((x) => x.id == p.id);
      }
    });
    save();
    if (p.srv && p.from == me!.u) cloud.rest('DELETE', '/rest/v1/posts?id=eq.${p.id}');
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
                          leading: Icon(e.key.startsWith('g:') ? Icons.group_rounded : Icons.person_rounded),
                          title: fw.Text(e.value),
                          trailing: const Icon(Icons.send_rounded),
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
                            subtitle: Text('\u200e@$u'),
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
                const SizedBox(height: 20),
                const Text('اللغة'),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'ar', label: fw.Text('العربية')),
                    ButtonSegment(value: 'en', label: fw.Text('English')),
                  ],
                  selected: {langCode.value},
                  onSelectionChanged: (s) {
                    langCode.value = s.first;
                    save();
                    st(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الدردشة عبر الإنترنت'),
                  subtitle: const Text('لو قفلتها، الرسائل بتتبعت بس لما تكونوا قريبين من بعض (بلوتوث)'),
                  value: chatNet,
                  onChanged: (v) {
                    setState(() => chatNet = v);
                    save();
                    st(() {});
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('سياسة الخصوصية'),
                  onTap: () {
                    Navigator.pop(c);
                    openPolicy();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.block_rounded),
                  title: const Text('الحسابات المحظورة'),
                  onTap: () {
                    Navigator.pop(c);
                    showBlocked();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('إعادة ضبط التطبيق'),
                  onTap: () {
                    Navigator.pop(c);
                    confirmReset();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_rounded, color: Theme.of(c).colorScheme.error),
                  title: Text('حذف الحساب', style: TextStyle(color: Theme.of(c).colorScheme.error)),
                  onTap: () {
                    Navigator.pop(c);
                    confirmDelete();
                  },
                ),
              ]),
            ),
          ),
        ),
      );

  void openNet(String url) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
            body: Center(child: InteractiveViewer(child: Image.network(url))),
          ),
        ),
      );

  Widget postCard(Post p, {VoidCallback? refresh}) {
    final cs = Theme.of(context).colorScheme;
    final pr = prof(p.from);
    final liked = myLikes.contains(p.id);
    final ok = p.img != null && File(p.img!).existsSync();
    final cap = (p.text ?? '').trim();
    final waiting = Container(
      height: 180,
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.image_rounded, size: 36, color: cs.onSurfaceVariant),
        const SizedBox(height: 6),
        Text('الصورة بتتحمل لما تتصل بصاحبها', style: TextStyle(color: cs.onSurfaceVariant)),
      ]),
    );
    Widget media;
    if (!p.im) {
      media = cap.isEmpty
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              color: p.color,
              padding: const EdgeInsets.all(28),
              constraints: const BoxConstraints(minHeight: 160),
              alignment: Alignment.center,
              child: fw.Text(cap,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            );
    } else if (ok) {
      media = GestureDetector(
        onTap: () => openImg(p.img!),
        child: Image.file(File(p.img!), width: double.infinity, fit: BoxFit.cover),
      );
    } else if (p.ip != null) {
      final url = pubUrl(p.ip!);
      media = GestureDetector(
        onTap: () => openNet(url),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (c, w, pg) => pg == null
              ? w
              : Container(height: 220, alignment: Alignment.center, child: const CircularProgressIndicator()),
          errorBuilder: (c, e, s) => waiting,
        ),
      );
    } else {
      media = waiting;
    }
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
                IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => delPost(p, refresh != null))
              else
                userMenu(p.from, postId: p.id),
            ]),
          ),
        ),
        media,
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Row(children: [
            IconButton(
              icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: liked ? Colors.red : null),
              onPressed: () {
                toggleLike(p);
                refresh?.call();
              },
            ),
            Text('${p.likes.length}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.mode_comment_outlined), onPressed: () => showComments(p)),
            Text('${ccount[p.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => sharePost(p)),
            if (p.from == me!.u) ...[
              const SizedBox(width: 4),
              const Icon(Icons.visibility_outlined, size: 20),
              const SizedBox(width: 4),
              Text('${vcount[p.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
        if (p.im && cap.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: fw.Text.rich(TextSpan(children: [
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
    final l = (exploreTab
        ? explore.where((p) => !blocked.contains(p.from)).toList()
        : posts.where((p) => p.kind == 'post' && !blocked.contains(p.from) && (p.from == me!.u || following.contains(p.from))).toList())
      ..sort((a, b) => b.at.compareTo(a.at));
    final sug = contacts.values.where((p) => p.u != me!.u && !blocked.contains(p.u) && !following.contains(p.u)).toList();
    return RefreshIndicator(
      onRefresh: pullSocial,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text('أصدقائي')),
                ButtonSegment(value: true, label: Text('اكتشاف')),
              ],
              selected: {exploreTab},
              onSelectionChanged: (s) => setState(() => exploreTab = s.first),
            ),
          ),
          if (!exploreTab && sug.isNotEmpty) ...[
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
              child: exploreTab
                  ? empty(Icons.explore_outlined, 'مفيش حاجة للاكتشاف لسه', 'اسحب لتحت للتحديث')
                  : empty(Icons.dynamic_feed_outlined, 'مفيش منشورات لسه',
                      'تابع ناس من ملفاتهم الشخصية أو انشر أول منشور ليك',
                      action: FilledButton.icon(
                          onPressed: newPost,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('منشور جديد'))),
            ),
          for (final p in l)
            ViewMark(
              key: ValueKey('v${p.id}'),
              onSeen: () {
                if (p.srv) markViewed('post', p.id, p.from);
              },
              child: postCard(p),
            ),
        ],
      ),
    );
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
    final plain = Container(
      color: x.color,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: x.kind == 'reel'
          ? const Icon(Icons.play_circle_outline, color: Colors.white, size: 36)
          : (x.im
              ? const Icon(Icons.image_rounded, color: Colors.white70)
              : fw.Text(x.text ?? '',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
    );
    Widget child;
    if (ok) {
      child = Image.file(File(x.img!), fit: BoxFit.cover);
    } else if (x.im && x.ip != null) {
      child = Image.network(pubUrl(x.ip!), fit: BoxFit.cover, errorBuilder: (c, e, s) => plain);
    } else {
      child = plain;
    }
    return GestureDetector(
      onTap: () => x.kind == 'reel' ? openReels(x) : showPost(x),
      child: Stack(fit: StackFit.expand, children: [
        child,
        if (x.kind == 'reel')
          const PositionedDirectional(
              top: 6, end: 6, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22)),
      ]),
    );
  }

  Widget profileView(String u) {
    final cs = Theme.of(context).colorScheme;
    final mine = u == me!.u;
    final p = prof(u);
    final byId = <String, Post>{};
    for (final x in posts.where((x) => x.from == u)) {
      byId[x.id] = x;
    }
    for (final x in (userPosts[u] ?? <Post>[])) {
      byId.putIfAbsent(x.id, () => x);
    }
    final ps = byId.values.toList()..sort((a, b) => b.at.compareTo(a.at));
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
          Text('\u200e@$u', style: TextStyle(color: cs.onSurfaceVariant)),
          if ((p.bio ?? '').isNotEmpty) ...[const SizedBox(height: 6), fw.Text(p.bio!)],
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
            if (!netReady)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: netDiag,
                  icon: const Icon(Icons.network_check, size: 18),
                  label: const Text('فحص الاتصال'),
                ),
              ),
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
                      icon: const Icon(Icons.edit_rounded),
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
            icon: Icon(Icons.delete_outline_rounded, color: cs.error), onPressed: () => stopRec(send: false)),
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
          icon: const Icon(Icons.send_rounded),
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
            IconButton(icon: const Icon(Icons.image_rounded), onPressed: sendImg),
            Expanded(
              child: TextField(
                controller: input,
                minLines: 1,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: T('اكتب رسالة'),
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
        icon: Icon(empty ? Icons.mic_rounded : Icons.send_rounded),
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
      Icon(Icons.mic_rounded, size: 16, color: fg.withAlpha(180)),
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
                  color: mine ? null : cs.surfaceContainerHigh,
                  gradient: mine
                      ? LinearGradient(
                          colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.55)!],
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd)
                      : null,
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
                      fw.Text(m.t ?? '', style: TextStyle(fontSize: 16, height: 1.35, color: fg)),
                    Padding(
                      padding: EdgeInsets.only(top: 2, left: img ? 6 : 0, right: img ? 6 : 0, bottom: img ? 2 : 0),
                      child: fw.Text(msgTime(m.i), style: TextStyle(fontSize: 10, color: fg.withAlpha(170))),
                    ),
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

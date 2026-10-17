"""يتشغّل في الـ workflow بعد Firebase config: يضيف أصوات ORX كـ raw resources،
وينشئ 3 قنوات إشعار بصوت مخصص في MainActivity، ويجعل قناة الرسائل هي الافتراضية لإشعارات FCM.
بيفشل بوضوح لو ما لقاش المكان المطلوب."""
import glob, os, re, shutil, sys

SOUNDS = ['orx_pulse.wav', 'orx_request.wav', 'orx_soft.wav']
for f in SOUNDS:
    if not os.path.exists(f):
        sys.exit('missing sound file: ' + f)

raw = 'android/app/src/main/res/raw'
os.makedirs(raw, exist_ok=True)
for f in SOUNDS:
    shutil.copy(f, os.path.join(raw, f))
# يمنع الـ resource shrinker من حذف الأصوات (بنستخدمها بالاسم من كود Kotlin)
open(os.path.join(raw, 'keep.xml'), 'w', encoding='utf-8').write(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources xmlns:tools="http://schemas.android.com/tools" tools:keep="@raw/orx_*" />\n')
print('raw sounds copied')

acts = glob.glob('android/app/src/main/kotlin/**/MainActivity.kt', recursive=True)
if not acts:
    sys.exit('MainActivity.kt not found')
act = acts[0]
pkg = re.search(r'^package\s+([\w.]+)', open(act, encoding='utf-8').read(), re.M)
if not pkg:
    sys.exit('package line not found in MainActivity.kt')

KT = '''package PKG

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrxChannels()
    }

    private fun soundUri(name: String): Uri =
        Uri.parse(ContentResolver.SCHEME_ANDROID_RESOURCE + "://" + packageName + "/raw/" + name)

    private fun createOrxChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NotificationManager::class.java) ?: return
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val defs = listOf(
            Triple("orx_messages_v1", "الرسائل", "orx_pulse"),
            Triple("orx_requests_v1", "طلبات المتابعة", "orx_request"),
            Triple("orx_activity_v1", "التفاعلات والتعليقات", "orx_soft")
        )
        for ((id, title, sound) in defs) {
            val ch = NotificationChannel(id, title, NotificationManager.IMPORTANCE_HIGH)
            ch.setSound(soundUri(sound), attrs)
            ch.enableVibration(true)
            ch.vibrationPattern = longArrayOf(0, 60, 40, 90)
            nm.createNotificationChannel(ch)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "orx/notif")
            .setMethodCallHandler { call, result ->
                if (call.method == "openChannel") {
                    val id = call.argument<String>("id")
                    val i = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        .putExtra(Settings.EXTRA_CHANNEL_ID, id)
                    try { startActivity(i); result.success(true) } catch (e: Exception) { result.success(false) }
                } else {
                    result.notImplemented()
                }
            }
    }
}
'''.replace('PKG', pkg.group(1))
open(act, 'w', encoding='utf-8').write(KT)
print('MainActivity.kt written for package', pkg.group(1))

man = 'android/app/src/main/AndroidManifest.xml'
s = open(man, encoding='utf-8').read()
if 'default_notification_channel_id' not in s:
    m = re.search(r'<application\b[^>]*>', s, re.S)
    if not m:
        sys.exit('<application> not found in manifest')
    meta = ('\n        <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"'
            ' android:value="orx_messages_v1"/>')
    s = s[:m.end()] + meta + s[m.end():]
    open(man, 'w', encoding='utf-8').write(s)
    print('manifest: default channel set')
else:
    print('manifest: ok')

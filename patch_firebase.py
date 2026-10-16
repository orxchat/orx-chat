"""يتشغّل في الـ workflow بعد patch_gradle.py: يضيف plugin الـ google-services ويضبط أيقونة الإشعار.
آمن لو اتشغّل أكتر من مرة، وبيفشل بوضوح لو ما لقاش المكان المطلوب."""
import os, re, shutil, sys

def edit(path, fn):
    s = open(path, encoding='utf-8').read()
    n = fn(s)
    if n != s:
        open(path, 'w', encoding='utf-8').write(n)
    return n != s

GS_VER = '4.4.2'

# 1) settings.gradle(.kts): نعرّف الـ plugin
settings = next((p for p in ('android/settings.gradle.kts', 'android/settings.gradle') if os.path.exists(p)), None)
if not settings:
    sys.exit('settings.gradle not found')

def add_settings(s):
    if 'com.google.gms.google-services' in s:
        return s
    kts = settings.endswith('.kts')
    line = (f'    id("com.google.gms.google-services") version "{GS_VER}" apply false\n' if kts
            else f'    id "com.google.gms.google-services" version "{GS_VER}" apply false\n')
    m = re.search(r'^[ \t]*id\(?\s*["\']com\.android\.application["\'][^\n]*\n', s, re.M)
    if not m:
        sys.exit('com.android.application plugin line not found in ' + settings)
    return s[:m.end()] + line + s[m.end():]

print('settings:', 'patched' if edit(settings, add_settings) else 'ok')

# 2) app/build.gradle(.kts): نفعّل الـ plugin
app = next((p for p in ('android/app/build.gradle.kts', 'android/app/build.gradle') if os.path.exists(p)), None)
if not app:
    sys.exit('app build.gradle not found')

def add_app(s):
    if 'com.google.gms.google-services' in s:
        return s
    kts = app.endswith('.kts')
    line = ('    id("com.google.gms.google-services")\n' if kts else '    id "com.google.gms.google-services"\n')
    m = re.search(r'^[ \t]*id\(?\s*["\']com\.android\.application["\'][^\n]*\n', s, re.M)
    if not m:
        sys.exit('com.android.application plugin line not found in ' + app)
    return s[:m.end()] + line + s[m.end():]

print('app:', 'patched' if edit(app, add_app) else 'ok')

# 3) أيقونة الإشعار (أبيض شفاف) + تعريفها في الـ manifest
res = 'android/app/src/main/res/drawable'
os.makedirs(res, exist_ok=True)
shutil.copy('ic_notif.png', res + '/ic_notif.png')

man = 'android/app/src/main/AndroidManifest.xml'
def add_man(s):
    if 'default_notification_icon' in s:
        return s
    m = re.search(r'<application\b[^>]*>', s, re.S)
    if not m:
        sys.exit('<application> not found in manifest')
    meta = ('\n        <meta-data android:name="com.google.firebase.messaging.default_notification_icon"'
            ' android:resource="@drawable/ic_notif"/>')
    return s[:m.end()] + meta + s[m.end():]

print('manifest:', 'patched' if edit(man, add_man) else 'ok')

# 4) صلاحية الإشعارات (أندرويد 13+)
def add_perm(s):
    if 'POST_NOTIFICATIONS' in s:
        return s
    m = re.search(r'^[ \t]*<application\b', s, re.M)
    if not m:
        sys.exit('<application> not found in manifest')
    return s[:m.start()] + '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n' + s[m.start():]

print('permission:', 'patched' if edit(man, add_perm) else 'ok')

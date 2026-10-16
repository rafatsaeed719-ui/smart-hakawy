"""بيتشغل في GitHub Actions بعد `flutter create` عشان يظبط مشروع أندرويد."""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent / 'android' / 'app'

# ---------- AndroidManifest ----------
mf = root / 'src' / 'main' / 'AndroidManifest.xml'
s = mf.read_text(encoding='utf-8')
perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
"""
if 'RECORD_AUDIO' not in s:
    s = re.sub(r'(<manifest[^>]*>)', r'\1\n' + perms, s, count=1)
queries = """        <intent>
            <action android:name="android.speech.RecognitionService"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE"/>
        </intent>
"""
if 'RecognitionService' not in s:
    if '<queries>' in s:
        s = s.replace('<queries>', '<queries>\n' + queries, 1)
    else:
        s = s.replace('</manifest>', '    <queries>\n' + queries + '    </queries>\n</manifest>')
s = re.sub(r'android:label="[^"]*"', 'android:label="اسمارت حكاوي"', s, count=1)
mf.write_text(s, encoding='utf-8')

# ---------- build.gradle(.kts) ----------
for name in ('build.gradle.kts', 'build.gradle'):
    g = root / name
    if not g.exists():
        continue
    t = g.read_text(encoding='utf-8')
    t = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', t)
    t = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', t)
    t = re.sub(r'minSdk\s*=\s*\d+', 'minSdk = 24', t)
    g.write_text(t, encoding='utf-8')
    print('patched', g)

print('manifest ok')

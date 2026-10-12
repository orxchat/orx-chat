import os
kts = os.path.exists('android/build.gradle.kts')
f = 'android/build.gradle.kts' if kts else 'android/build.gradle'
s = open(f).read()
if kts:
    blk = '''subprojects {
    afterEvaluate {
        project.extensions.findByName("android")?.let {
            it.withGroovyBuilder { "compileSdkVersion"(36) }
        }
    }
}

'''
else:
    blk = '''subprojects {
    afterEvaluate { p ->
        if (p.hasProperty('android')) { p.android { compileSdkVersion 36 } }
    }
}

'''
i = s.find('subprojects {')
s = s[:i] + blk + s[i:] if i >= 0 else s + '\n' + blk
open(f, 'w').write(s)
print('patched', f)


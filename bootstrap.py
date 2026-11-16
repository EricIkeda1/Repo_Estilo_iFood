"""Gera os runners oficiais usando o Flutter instalado, preservando o app."""
import pathlib
import shutil
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parent
flutter = shutil.which("flutter")
if not flutter:
    raise SystemExit("Instale o Flutter SDK e inclua flutter no PATH.")
with tempfile.TemporaryDirectory() as tmp:
    template = pathlib.Path(tmp) / "eyi_food"
    subprocess.run([flutter, "create", "--no-pub", "--platforms=android,ios,web",
                    "--org", "br.com.ericyikeda", str(template)], check=True)
    for platform in ("android", "ios", "web"):
        dest = root / platform
        if not dest.exists():
            shutil.copytree(template / platform, dest)
    manifest = root / "android/app/src/main/AndroidManifest.xml"
    body = manifest.read_text()
    if "android.permission.INTERNET" not in body:
        manifest.write_text(body.replace("<application", '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1))
subprocess.run([flutter, "pub", "get"], cwd=root, check=True)

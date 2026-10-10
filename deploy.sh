#!/bin/bash

# Bei Fehlern abbrechen
set -e

# Säubert das Script, wenn es unter Windows erstellt wurde
tr -d '\r' < ./lambda.py > ./lambda.py.tmp && mv ./lambda.py.tmp ./lambda.py
tr -d '\r' < ./lyricworkerstack.py > ./lyricworkerstack.py.tmp && mv ./lyricworkerstack.py.tmp ./lyricworkerstack.py

if [ ! -f "./lambda.py" ]; then
    echo "FEHLER: lambda.py wurde nicht gefunden!"
    echo "Lege lambda.py neben dieses Shell-Skript."
    exit 1
fi

# Hier jetzt komplett kleingeschrieben
if [ ! -f "./lyricworkerstack.py" ]; then
    echo "FEHLER: lyricworkerstack.py wurde nicht gefunden!"
    echo "Lege lyricworkerstack.py neben dieses Shell-Skript."
    exit 1
fi

# Absoluten Pfad des Ausgangsverzeichnisses
SOURCE_DIR="$(pwd)"

# Ordnername direkt mit Unterstrichen für Python-Kompatibilität
PROJECT_NAME="mein_cdk_projekt"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# CDK-Projekt nur initialisieren, wenn noch keines existiert
if [ ! -f "cdk.json" ]; then
    cdk init app --language python
fi

# Virtuelle Umgebung aktivieren
source .venv/bin/activate

# CDK-Abhängigkeiten installieren
pip install -r requirements.txt

# Verzeichnis für den Lambda-Code erstellen
mkdir -p lambda_function
cp "$SOURCE_DIR/lambda.py" lambda_function/lambda.py

# Stack-Datei kleingeschrieben in den Projektordner kopieren
cp "$SOURCE_DIR/lyricworkerstack.py" "$PROJECT_NAME/lyricworkerstack.py"

# Layer-Verzeichnis erstellen
mkdir -p lambda_layer/python
if [ ! -f "lambda_layer/python/placeholder.py" ]; then
    echo "# Placeholder fuer spaetere Libraries" > lambda_layer/python/placeholder.py
fi

# app.py mit den exakten Kleinschreibungen erstellen
cat << 'EOF' > app.py
#!/usr/bin/env python3
import aws_cdk as cdk
# Importiert aus datei 'lyricworkerstack.py' die Klasse 'lyricworkerstack'
from mein_cdk_projekt.lyricworkerstack import lyricworkerstack

app = cdk.App()
lyricworkerstack(
    app, 
    "LyricWorkerStack",
)
app.synth()
EOF

# Deploy-Vorbereitungen
export JSII_SILENCE_WARNING_DEPRECATED_NODE_VERSION=1
rm -rf cdk.out

# AWS-Umgebung vorbereiten & deployen
npx aws-cdk bootstrap
npx aws-cdk deploy --require-approval never

echo "Deployment abgeschlossen!"

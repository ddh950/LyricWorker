#!/bin/bash

# Bei Fehlern abbrechen

set -e
# säubert das script wenn es unter Windows erstellt wurde
tr -d '\r' < ./lambda.py > ./lambda.py.tmp && mv ./lambda.py.tmp ./lambda.py
tr -d '\r' < ./lyricWorkerStack.py > ./lyricWorkerStack.py.tmp && mv ./lyricWorkerStack.py.tmp ./lyricWorkerStack.py



if [ ! -f "./lambda.py" ]; then
    echo "FEHLER: lambda.py wurde nicht gefunden!"
    echo "Lege lambda.py neben dieses Shell-Skript."
    exit 1
fi


if [ ! -f "./lyricWorkerStack.py" ]; then
    echo "FEHLER: lyricworkerstack.py wurde nicht gefunden!"
    echo "Lege lyricWorkerStack.py neben dieses Shell-Skript."
    exit 1
fi

# Absoluten Pfad des Ausgangsverzeichnisses
SOURCE_DIR="$(pwd)"

mkdir -p mein-cdk-projekt
cd mein-cdk-projekt

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

# Vorhandene Lambda-Datei kopieren
cp "$SOURCE_DIR/lambda.py" lambda_function/lambda.py


# Vorhandene Stack-Datei kopieren
cp "$SOURCE_DIR/lyricWorkerStack.py" \
   mein_cdk_projekt/lyricWorkerStack.py

# Layer-Verzeichnis erstellen
mkdir -p lambda_layer/python

# Platzhalter nur erstellen, wenn noch nicht vorhanden
if [ ! -f "lambda_layer/python/placeholder.py" ]; then
    echo "# Placeholder fuer spaetere Libraries" \
        > lambda_layer/python/placeholder.py
fi

# app.py 
cat << 'EOF' > app.py
#!/usr/bin/env python3

import aws_cdk as cdk

from mein_cdk_projekt.lyricWorkerStack import lyricworkerstack

app = cdk.App()

LyricWorkerStack(
    app,
    "LyricWorkerStack",
)

app.synth()
EOF

# Deploy

export JSII_SILENCE_WARNING_DEPRECATED_NODE_VERSION=1

# Alten CDK-Build-Cache entfernen
rm -rf cdk.out

# AWS-Umgebung vorbereiten
npx aws-cdk bootstrap

# Infrastruktur deployen
npx aws-cdk deploy --require-approval never

echo "Deployment abgeschlossen!"


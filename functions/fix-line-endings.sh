#!/bin/bash

echo "✅ Correction des fins de ligne (CRLF ➔ LF) dans tous les fichiers..."

# Trouver tous les fichiers .js et .json et corriger les fins de lignes
find . -type f \( -iname "*.js" -o -iname "*.json" \) -exec dos2unix {} \;

echo "✅ Terminé : tous les fichiers sont en format LF (Unix)."

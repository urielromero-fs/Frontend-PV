#!/bin/bash

# 1. Clonar Flutter en una carpeta temporal
git clone https://github.com/flutter/flutter.git -b stable

# 2. Agregar Flutter al PATH del servidor
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Forzar la descarga de las herramientas web
flutter config --enable-web

# 4. Construir el proyecto
flutter build web --release
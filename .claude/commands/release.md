# The Base — Release Checklist

Cada vez que vayas a hacer un release de The Base, sigue estos pasos en orden.

## Paso 1 — Bump de versión en pubspec.yaml

El formato es `version: MAJOR.MINOR.PATCH+BUILD`:
- `+BUILD` es el `versionCode` de Android (entero que sólo sube).
- `MAJOR.MINOR.PATCH` es el `versionName` visible.

Ejemplo: `1.0.0+1` → `1.1.0+2`

Edita `pubspec.yaml`:
```yaml
version: X.Y.Z+N   # incrementa ambos
```

## Paso 2 — Commit del bump

```bash
git add pubspec.yaml
git commit -m "chore: bump version to X.Y.Z"
```

## Paso 3 — Compilar el APK de release

```bash
flutter build apk --release
```

El APK queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Renómbralo antes de subir:
```bash
copy build\app\outputs\flutter-apk\app-release.apk the-base.apk
```

## Paso 4 — Tag de git y push

```bash
git tag vX.Y.Z
git push origin master --tags
```

## Paso 5 — Crear GitHub Release

```bash
gh release create vX.Y.Z the-base.apk \
  --title "The Base vX.Y.Z" \
  --notes "Descripción de los cambios en esta versión."
```

Si `gh` no está disponible, hazlo manualmente en:
https://github.com/TheWiche/the-base/releases/new

- **Tag:** `vX.Y.Z`
- **Title:** `The Base vX.Y.Z`
- **Attach:** `the-base.apk`

## Paso 6 — Verificar el QR y el badge de versión

El landing page (`landing/index.html`) descarga siempre el APK desde
`releases/latest/download/the-base.apk`, así que no necesita cambios.

El badge de versión (`versionBadge`) se actualiza solo desde la API de GitHub.

---

> GitHub repo: https://github.com/TheWiche/the-base  
> Package Android: `com.thebase.app`  
> APK name: `the-base.apk`

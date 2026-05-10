# IBM Fault Analyzer (`IBM.zfaultanalyzer`)

Navigation et analyse des rapports de fautes ABEND (dumps) IBM Fault Analyzer
directement depuis VS Code.

---

## Prérequis

- [Zowe Explorer](zowe-explorer.md) 3.2.0+
- [IBM ADFz Common Component](adfz-common.md) (ADFzCC) 1.10.0+ sur z/OS.
- IBM Fault Analyzer for z/OS **16.1.0 ou supérieur** côté mainframe.
- [IBM Z Open Editor](z-open-editor.md) recommandé (coloration syntaxique des
  sources dans les rapports).
- **TLS :** AT-TLS obligatoire.
- Jeux de caractères supportés : IBM1047 (anglais), IBM939 (japonais).

---

## Premiers pas

Identique à File Manager : clic droit sur le profil Zowe →
**Application Delivery Foundation → Configurer la connexion** →
host et port ADFzCC.

**Paramètre VS Code :** `IBM Fault Analyzer > Language` — langue des
ressources globales (anglais / japonais).

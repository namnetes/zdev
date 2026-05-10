# IBM File Manager (`IBM.zfilemanager`)

Navigation et édition de datasets z/OS depuis VS Code, en remplacement
d'ISPF. Requiert IBM File Manager for z/OS côté mainframe.

---

## Prérequis

- [Zowe Explorer](zowe-explorer.md) 3.2.0+
- [IBM ADFz Common Component](adfz-common.md) (ADFzCC) 1.10.0+ sur z/OS.
- IBM File Manager for z/OS **16.1.0 ou supérieur** côté mainframe.
- **TLS :** AT-TLS obligatoire (z/OS System SSL non supporté).

---

## Premiers pas

1. Clic droit sur un profil Zowe Explorer.
2. Sélectionner **Application Delivery Foundation → Configurer la connexion**.
3. Entrer le host et le port du serveur ADFzCC.

**Paramètre VS Code :** `IBM File Manager > Page Size` — taille du cache
d'édition.

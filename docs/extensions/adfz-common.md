# IBM ADFz Common Component (`IBM.zcommoncomponent`)

Infrastructure partagée (gestion des identifiants, configuration des
connexions) consommée par [File Manager](file-manager.md),
[Fault Analyzer](fault-analyzer.md) et [APA](apa.md). Pas d'interface
utilisateur propre.

---

## Prérequis

[Zowe Explorer](zowe-explorer.md) 3.2.0+.

À installer uniquement si File Manager, Fault Analyzer ou APA est utilisé.

---

## Configuration côté z/OS

Un seul serveur ADFzCC côté z/OS peut servir les trois extensions (File
Manager, Fault Analyzer, APA). La procédure de configuration est identique
pour les trois :

1. Clic droit sur un profil Zowe Explorer.
2. **Application Delivery Foundation → Configurer la connexion**.
3. Entrer le host et le port du serveur ADFzCC.

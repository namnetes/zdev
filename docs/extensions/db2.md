# IBM Db2 Developer Extension (`IBM.db2forzosdeveloperextension`)

Environnement de développement SQL complet pour Db2 on z/OS — écriture,
explication, optimisation et exécution de requêtes SQL. Inclut le pilote
IBM JDBC.

---

## Prérequis

- **Java :** Oracle SDK 8/11 ou OpenJDK 8/11 (versions 17 et 21 supportées).
  Dans `zdev-ide` : Java 21 disponible dans `/opt/java`.
- **Linux :** paquet `libsecret` (`apt-get install libsecret-1-dev`).
- **Licence Db2 Connect** pour la connectivité z/OS :
  - Db2 Connect Enterprise Edition (fichier JAR côté client), **ou**
  - Db2 Connect Unlimited Edition for System z (licence serveur, pas de JAR
    requis).

---

## Paramètres `settings.json`

```json
{
  "db2forzosdeveloperextension.java.home": "/opt/java",
  "db2forzosdeveloperextension.db2sqlservice.dependencies":
    "/home/zdev/.db2/db2jcc_license_cisuz.jar:/home/zdev/.db2/db2jcc4.jar"
}
```

> Le séparateur de chemins est `:` sur Linux/macOS et `;` sur Windows.

**Résolution de Java (ordre de priorité) :** paramètre VS Code →
`JAVA_HOME` env → `PATH`.

---

## Options SQL avancées (licences séparées)

- Db2 Accessories Suite 4.2 + APAR PH42944 pour l'optimisation de workloads.
- Db2 Query Workload Tuner for z/OS 6.1.
- Google Chrome requis pour *Access Path Comparison* et *Visual Explain*.

---

## Premiers pas

1. Ouvrir le panneau *Db2 Connections* dans la barre latérale.
2. Cliquer sur `+` et entrer le host, port, base de données et identifiants.
3. Placer le fichier licence JAR dans un dossier accessible et configurer
   `db2sqlservice.dependencies`.

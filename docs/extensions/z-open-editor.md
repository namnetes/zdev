# IBM Z Open Editor (`IBM.zopeneditor`)

Serveur de langage pour COBOL, PL/I, HLASM, REXX et JCL. Coloration
syntaxique, complétion de code, navigation, refactoring, gestion des
copybooks. Extension principale pour le développement de code mainframe.

---

## Prérequis

- **Java 21 (64 bits) obligatoire** — IBM Semeru Runtime 21, Oracle Java 21
  ou OpenJDK 21. Dans `zdev-ide` : Java 21 est déjà installé dans
  `/opt/java`.
- Zowe CLI 8.0.0+ et Zowe Explorer v3 pour les opérations sur datasets
  distants.

---

## Résolution de Java (ordre de priorité)

1. Paramètre VS Code `zopeneditor.JAVA_HOME`
2. Paramètre VS Code `java.home`
3. Variable d'environnement `JAVA_HOME`
4. `PATH` système
5. Emplacements standard de la plateforme

---

## Paramètres `settings.json`

```json
{
  "zopeneditor.JAVA_HOME": "/opt/java",
  "zopeneditor.server.memoryAllocation": 640
}
```

---

## Fichier de projet `zapp.yaml`

À placer à la racine du workspace. Permet de configurer les chemins de
copybooks, les options de compilation et de déploiement.

```yaml
name: mon-projet-cobol
description: Application de traitement des comptes
version: 1.0.0
author: Equipe z/OS
procLib: MYSITE.PROC.LIB
userLibraries:
  - MYSITE.COBOL.LOAD
```

---

## Fonctions avancées sous licence

Après l'essai de 90 jours automatiquement activé pour les nouveaux
utilisateurs, les fonctions avancées requièrent une licence IDzEE / IDz
Select / ADFz :

- Analyse statique et détection d'impact
- Refactoring avancé
- Navigation dans les structures de données complexes

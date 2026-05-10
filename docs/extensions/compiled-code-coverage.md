# IBM Compiled Code Coverage (`IBM.compiledcodecoverage`)

Affiche les résultats de couverture de code compilé depuis IBM z/OS Debugger.
S'intègre au workflow de débogage Z Open Debug.

---

## Prérequis

- [IBM Z Open Debug](z-open-debug.md) (co-requis — configure automatiquement
  le service si présent).
- **Côté z/OS :** IBM z/OS Debugger RDS **ou** Headless Code Coverage —
  PTF 17.0.3.2 minimum.
- Licence : IDzEE, IDz Select, ADFz ou TAZ.

Utilise le même profil Zowe `zOpenDebug` que l'extension Z Open Debug.

---

## Instrumentation JCL côté z/OS

=== "Mode RDS"

    ```
    TEST(,,,RDS&userid:*)
    ENVAR("EQA_STARTUP_KEY=CC")
    ```

=== "Mode TCPIP"

    ```
    TEST(,,,TCPIP%localhost:*)
    ENVAR("EQA_STARTUP_KEY=CC")
    ```

---

## Premiers pas

1. Ajouter une connexion au service Code Coverage (URL + identifiants).
2. Les résultats apparaissent dans le panneau dédié.
3. Clic droit sur un résultat → **Voir le rapport**.
4. Avec Z Open Debug activé : la connexion est configurée automatiquement.

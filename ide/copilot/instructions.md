# Instructions GitHub Copilot — ZDev VS Code

> **À propos de ce fichier**
> Ce fichier contient les instructions transmises automatiquement à **GitHub Copilot** lors de chaque session dans VS Code. Il définit les conventions de code, les règles de style et les standards appliqués sur ce projet.
>
> Il est lu par l'IA, pas par les utilisateurs. Vous n'avez pas besoin de le lire pour utiliser l'environnement. En revanche, si vous souhaitez modifier le comportement de GitHub Copilot sur ce projet, c'est ici qu'il faut intervenir.
>
> Les règles spécifiques aux langages sont dans `instructions/` :
> - `Mainframe.instructions.md` — COBOL, JCL, z/OS
> - `Open.instructions.md` — Python, TypeScript, Bash

---

# Copilot Instructions

## Mermaid Diagrams

These rules apply to **all** diagrams in the project regardless of the
technology depicted: Python modules, shell pipelines, COBOL batch flows,
data models, API interactions, etc.

### Diagram type — choose the right one

| Situation | Diagram type |
|---|---|
| Step-by-step workflow, algorithm, decision tree | `flowchart TD` (vertical) |
| Data pipeline, ETL, linear processing chain | `flowchart LR` (horizontal) |
| Component / module architecture | `flowchart LR` or `flowchart TD` |
| Sequence of calls between actors or services | `sequenceDiagram` |
| Class structure, inheritance, composition | `classDiagram` |
| Database or data model | `erDiagram` |
| State machine, lifecycle | `stateDiagram-v2` |

Always add a visible title with `title:` at the top of every diagram.

### Background and general rendering

- **White background** — always add the init directive:
  `%%{init: {"theme": "base", "themeVariables": {"background": "#ffffff"}}}%%`
- Colors must be **visible** (sufficient contrast on white) but **not
  garish** — avoid saturated primaries; prefer muted pastels with a darker
  stroke of the same hue.
- Every color must carry a **consistent semantic meaning** across all
  diagrams in the project (see palette below). Never assign a color
  arbitrarily or for purely aesthetic reasons.

### Color palette — semantic rules

The same five classes are used in every diagram. Meaning is fixed
project-wide — do not repurpose a class for a different semantic.

| Class | Fill | Stroke | Meaning — use for |
|---|---|---|---|
| `startStop` | `#e1f5fe` | `#01579b` | Entry point, normal exit, success end |
| `logic` | `#e8eaf6` | `#1a237e` | Processing, computation, decision, control flow |
| `data` | `#fff3e0` | `#e65100` | Data, files, databases, queues, I/O |
| `error` | `#ffebee` | `#c62828` | Error, failure, exception, abort |
| `external` | `#f3e5f5` | `#6a1b9a` | External system, third-party service, API, library |

```
%%{init: {"theme": "base", "themeVariables": {"background": "#ffffff"}}}%%
flowchart TD
    classDef startStop fill:#e1f5fe,stroke:#01579b,color:#000
    classDef logic     fill:#e8eaf6,stroke:#1a237e,color:#000
    classDef data      fill:#fff3e0,stroke:#e65100,color:#000
    classDef error     fill:#ffebee,stroke:#c62828,color:#000
    classDef external  fill:#f3e5f5,stroke:#6a1b9a,color:#000
```

Rules:
- Every `classDef` that is declared **must** be assigned to at least one node.
- Do not define a class that is not used in the diagram.
- Use `color:#000` (black text) on all nodes to ensure legibility on
  pastel backgrounds.

### Node shapes (flowchart only)

- `([ ... ])` : Start / End
- `[ ... ]` : Process, step, action
- `[[ ... ]]` : Call to an external function or service
- `[/ ... /]` : I/O — data read/write, file, queue
- `{ ... }` : Conditional branch (if, switch, while)
- `(( ... ))` : Connector (join point in complex diagrams)

### Legend

Add a legend subgraph whenever the diagram uses 3 or more classes, or
when the diagram may be read by someone unfamiliar with the color code.
Only include the classes actually used in that diagram — one node per class.

```
    subgraph Legend["Legend"]
        direction LR
        L1([Start / End]):::startStop
        L2[Process]:::logic
        L3[/Data · File/]:::data
        L4[[External service]]:::external
        L5([Error / Abort]):::error
    end
```

---

## Writing & Reformulation

- Always write in a politically correct and inclusive manner.
- Use appropriate vocabulary — clear and precise, but not overly sophisticated.
- Prioritize clarity and comprehension over literary style.
- Sentences should be short and accessible to the widest possible audience.
- Avoid jargon, anglicisms, and technical terms unless the context requires them.

---

## Git Commits

Use Conventional Commits format: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`.

Default branch is **`main`** — never `master`.

---

## Project Structure

- `/src` — Python source code and Bash scripts
- `/cobol` — IBM mainframe COBOL programs and JCL
- `/data` — CSV files (semicolon-delimited, UTF-8)
- `pyproject.toml` — source of truth for ruff, pytest, and dependencies

---
applyTo: "**/*.py,**/*.sh,**/*.bash,**/*.ts,**/*.tsx,src/**,scripts/**"
---

# Instructions Python, Bash & TypeScript — GitHub Copilot

> **À propos de ce fichier**
> Ces instructions sont transmises automatiquement à GitHub Copilot lorsque vous éditez des fichiers Python (`.py`), Shell (`.sh`, `.bash`), TypeScript (`.ts`, `.tsx`) ou tout fichier dans `src/` et `scripts/`. Elles définissent les conventions de code, les outils à utiliser et les standards de qualité attendus.
>
> Vous n'avez pas besoin de lire ce fichier pour utiliser l'environnement. Il est destiné aux développeurs qui souhaitent comprendre ou ajuster le comportement de Copilot sur le code open.

---

# Python & Bash Instructions

## Package Manager

- Always use `uv`. Never suggest `pip` or `poetry`.
- Setup: `uv sync`
- Add dependency: `uv add <package>`
- Run script: `uv run <script.py>`
- Run tests: `uv run pytest`
- Lint/fix: `uv run ruff check . --fix`

---

## Python Standards

- Python version: **3.12+**.
- Line length: **88 characters** maximum (Ruff/Black style).
- Type hints required on **all** function and method signatures (parameters
  and return type).
- f-strings for all string formatting; no `%` formatting, no `.format()`.
- `pathlib.Path` for all file-system paths; never `os.path`.
- `logging` module for all output in production code; `print()` only in
  one-off scripts or CLI entry points.
- Specific exceptions only — never bare `except:` or `except Exception:`.

### Naming conventions

| Element | Convention | Example |
|---|---|---|
| Variable / function | `snake_case` | `record_count`, `read_csv_file` |
| Class | `PascalCase` | `CsvReader`, `SortKey` |
| Constant (module-level) | `UPPER_SNAKE_CASE` | `DEFAULT_DELIMITER` |
| Private helper | `_leading_underscore` | `_parse_header` |

### Documentation — accessibility first

**Goal: every source file must be readable and understandable by a beginner
with no prior context.** Assume the reader knows Python basics but nothing
about the business domain or z/OS.

#### Module docstring (mandatory on every `.py` file)

```python
"""
Short one-line summary of what this module does.

Longer description if needed: explain the purpose, the inputs it expects,
the outputs it produces, and any important limitation or assumption.

Example:
    uv run script.py --input data/customers.csv
"""
```

#### Function / method docstring — Google Style (mandatory on all public
functions; strongly recommended on private helpers > 5 lines)

```python
def compute_balance(
    debit: Decimal,
    credit: Decimal,
    initial: Decimal = Decimal("0"),
) -> Decimal:
    """Calculate the net balance after applying debit and credit.

    Positive result means credit exceeds debit. The function does not
    raise on negative balances — callers must validate the result if
    a negative balance is not allowed in the business context.

    Args:
        debit: Total amount debited (must be >= 0).
        credit: Total amount credited (must be >= 0).
        initial: Starting balance before this transaction. Defaults to 0.

    Returns:
        Net balance as a Decimal: initial + credit - debit.

    Raises:
        ValueError: If debit or credit is negative.
    """
```

Rules:
- `Args` section required as soon as there is at least one parameter.
- `Returns` section required unless the function returns `None`.
- `Raises` section required for every exception the function can raise.
- Write in plain, jargon-free language. Spell out abbreviations on first use.
- Include a short usage `Example:` block for any non-trivial public function.

#### Inline comments

- Use inline comments **only** for logic that is not self-evident from the
  code itself — explain *why*, not *what*.
- Write in complete sentences, starting with a capital letter.
- Keep them short; if an explanation needs more than 2 lines, move it to
  the docstring.

```python
# Good — explains a non-obvious business rule
credit_limit = base_limit * 1.10  # 10 % grace margin per policy ref. FIN-42

# Bad — restates the code
credit_limit = base_limit * 1.10  # multiply base_limit by 1.10
```

---

## Shell / Bash Standards

- Line length: **80 characters** maximum.
- Always start scripts with `set -euo pipefail`.
- Use `\` for line continuation to respect the 80-char limit.

---

## Data Handling (FR locale)

- CSV delimiter: `;` (semicolon).
- Encoding: UTF-8.
- Always specify `sep=';'` or `delimiter=';'` in Pandas/Polars IO calls.
- Use `.` as decimal separator for raw data.

---

## VS Code Extension Development

### Language and tooling

- TypeScript is mandatory — never plain JavaScript.
- Node.js LTS + `npm` for dependency management in extension projects
  (not `uv` — these are TypeScript/Node projects).
- Scaffold new extensions with `yo code` (Yeoman VS Code generator).
- Bundle for production with **esbuild** (preferred) or webpack; never
  publish unbundled source (activation latency is unacceptable).
- Package and publish with `@vscode/vsce`; also publish to the
  Open VSX Registry with `ovsx` (for VSCodium / Gitpod users).

### TypeScript configuration

Enable strict mode in `tsconfig.json` — non-negotiable:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2022",
    "lib": ["ES2022"],
    "strict": true,
    "noImplicitAny": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "outDir": "out",
    "sourceMap": true
  }
}
```

**Naming conventions:**

| Element | Convention | Example |
|---|---|---|
| Variable / function | `camelCase` | `recordCount`, `readFile` |
| Class / interface / type | `PascalCase` | `CobolProvider`, `ParseResult` |
| Constant (module-level) | `UPPER_SNAKE_CASE` | `DEFAULT_TIMEOUT` |
| Private member | `_camelCase` or `#camelCase` | `_disposables` |
| Enum member | `PascalCase` | `Status.Active` |

- No `any` type — use `unknown` + type guards, or proper generic types.
- Prefer `interface` over `type` for object shapes; use `type` for
  unions, intersections, and mapped types.
- Line length: **120 characters** maximum (VS Code codebase convention).

### Extension manifest (`package.json`)

Every manifest must declare:

```json
{
  "name": "my-extension",
  "displayName": "My Extension",
  "description": "One clear sentence describing what this extension does.",
  "version": "1.0.0",
  "publisher": "publisher-id",
  "engines": { "vscode": "^1.90.0" },
  "categories": ["Other"],
  "activationEvents": [],
  "main": "./out/extension.js",
  "contributes": {},
  "scripts": {
    "compile": "tsc -p ./",
    "watch": "tsc -watch -p ./",
    "package": "vsce package",
    "lint": "eslint src --ext ts"
  }
}
```

Rules:
- `engines.vscode` — pin to the **oldest VS Code version** you have tested
  against; do not use `*`.
- `activationEvents` — use specific events (see below); never `"*"`.
- `main` — points to the **compiled** JS file, never to TypeScript source.
- `description` — one sentence, no trailing period, no marketing language.
- Keep `CHANGELOG.md` up to date using [Keep a Changelog] format;
  VS Code Marketplace renders it automatically.

### Activation events — performance rules

Activation events control when the extension is loaded. Lazy activation is
critical: a slow extension degrades the entire editor.

| Event | Use when |
|---|---|
| `onCommand:myext.cmd` | Extension only needed when a specific command runs |
| `onLanguage:cobol` | Extension provides language features for a specific language |
| `onView:myext.treeview` | Extension provides a view container |
| `workspaceContains:**/*.cbl` | Activate when workspace has relevant files |
| `onStartupFinished` | Activate after startup — for background tasks only |
| `*` | **Never use** — activates on every window open |

Since VS Code 1.74 `activationEvents` can be **omitted** for commands and
views declared in `contributes` — the runtime infers them automatically.
Remove explicit `onCommand` entries for commands already listed in
`contributes.commands`.

### Extension entry point

```typescript
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext): void {
    // All disposables must be pushed to context.subscriptions.
    // They are automatically disposed when the extension is deactivated.
    const disposable = vscode.commands.registerCommand(
        'myext.helloWorld',
        async () => {
            try {
                await doWork();
            } catch (err) {
                const message = err instanceof Error ? err.message : String(err);
                vscode.window.showErrorMessage(`myext: ${message}`);
            }
        }
    );
    context.subscriptions.push(disposable);
}

export function deactivate(): void {
    // Release resources not tracked by context.subscriptions.
    // If nothing to release, this function can be omitted.
}
```

Rules:
- **Never** perform long synchronous work in `activate()` — the editor is
  blocked until it returns.
- Wrap async `activate()` in a try/catch and surface errors via
  `vscode.window.showErrorMessage`.
- Every `Disposable` **must** be pushed to `context.subscriptions` or stored
  and disposed manually. Memory and listener leaks are the #1 extension bug.

### Commands

```typescript
// Register
const cmd = vscode.commands.registerCommand('myext.parse', async (uri?: vscode.Uri) => {
    await vscode.window.withProgress(
        { location: vscode.ProgressLocation.Notification, title: 'Parsing…', cancellable: true },
        async (progress, token) => {
            token.onCancellationRequested(() => { /* cancel work */ });
            progress.report({ increment: 0 });
            await parseFile(uri);
            progress.report({ increment: 100 });
        }
    );
});
context.subscriptions.push(cmd);
```

Rules:
- Always wrap command handlers in try/catch.
- Use `vscode.window.withProgress` for any operation > ~300 ms.
- Respect `CancellationToken` in long-running operations.
- Declare all commands in `contributes.commands` with a human-readable
  `title` and an optional `icon`.

### Configuration settings

```typescript
// Read — never cache; read fresh on each use to respect live changes.
function getConfig(): vscode.WorkspaceConfiguration {
    return vscode.workspace.getConfiguration('myext');
}

const timeout = getConfig().get<number>('timeout', 5000);

// React to changes
context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration(e => {
        if (e.affectsConfiguration('myext')) {
            // re-read and apply
        }
    })
);
```

Declare all settings in `contributes.configuration` with `type`, `default`,
`markdownDescription`. Never hard-code values that belong in settings.

### File system — prefer VS Code APIs

```typescript
// Correct — works in remote (SSH, WSL, Codespaces) and virtual FS
const bytes = await vscode.workspace.fs.readFile(uri);
const text = Buffer.from(bytes).toString('utf8');
await vscode.workspace.fs.writeFile(uri, Buffer.from(content, 'utf8'));

// Avoid — breaks in remote / virtual FS scenarios
import * as fs from 'fs/promises';  // ← not portable
```

Always use `vscode.Uri` objects for paths. Build URIs with
`vscode.Uri.joinPath(base, 'relative/path')`, never string concatenation.

### TreeView / TreeDataProvider

```typescript
class MyTreeProvider implements vscode.TreeDataProvider<MyItem> {
    private readonly _onDidChangeTreeData =
        new vscode.EventEmitter<MyItem | undefined | null | void>();
    readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

    refresh(): void {
        this._onDidChangeTreeData.fire(undefined); // undefined = refresh all
    }

    getTreeItem(element: MyItem): vscode.TreeItem {
        return element;
    }

    async getChildren(element?: MyItem): Promise<MyItem[]> {
        return element ? element.children : this.getRoots();
    }
}

const provider = new MyTreeProvider();
context.subscriptions.push(
    vscode.window.registerTreeDataProvider('myext.view', provider)
);
```

### WebviewPanel — security rules

Every webview **must** define a strict Content Security Policy (CSP).
Failure to do so allows arbitrary script injection.

```typescript
function getWebviewContent(webview: vscode.Webview, extensionUri: vscode.Uri): string {
    const scriptUri = webview.asWebviewUri(
        vscode.Uri.joinPath(extensionUri, 'media', 'main.js')
    );
    const nonce = getNonce(); // cryptographically random string

    return /* html */ `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Security-Policy"
          content="default-src 'none';
                   script-src 'nonce-${nonce}';
                   style-src ${webview.cspSource} 'unsafe-inline';">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <script nonce="${nonce}" src="${scriptUri}"></script>
</body>
</html>`;
}

function getNonce(): string {
    let text = '';
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < 32; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
}
```

Security rules:
- **Never** use `'unsafe-inline'` in `script-src` — always use nonces.
- **Never** call `eval()` or `new Function()` inside a webview.
- Always set `localResourceRoots` to the minimum necessary set of URIs.
- Use `webview.postMessage()` / `window.addEventListener('message', …)` for
  all communication between extension host and webview.
- Sanitize every value received from the webview before acting on it.

### Output channels and logging

```typescript
// Create once in activate(), dispose via context.subscriptions
const output = vscode.window.createOutputChannel('My Extension', { log: true });
context.subscriptions.push(output);

// Use structured log levels (VS Code 1.74+)
output.info('Extension activated');
output.warn('Configuration missing, using defaults');
output.error('Failed to connect', err);
```

- Use `vscode.window.showErrorMessage` for errors the user must act on.
- Use `vscode.window.showWarningMessage` for recoverable problems.
- Use `vscode.window.showInformationMessage` sparingly — avoid notification spam.
- Route diagnostic details to the output channel, not to notifications.

### Diagnostics (linting / error reporting)

```typescript
const collection = vscode.languages.createDiagnosticCollection('myext');
context.subscriptions.push(collection);

function updateDiagnostics(document: vscode.TextDocument): void {
    const diagnostics: vscode.Diagnostic[] = [];
    // build Diagnostic objects with range + message + severity
    collection.set(document.uri, diagnostics);
}

// Clear diagnostics when the document is closed
context.subscriptions.push(
    vscode.workspace.onDidCloseTextDocument(doc => collection.delete(doc.uri))
);
```

### Testing

Use `@vscode/test-cli` (recommended from VS Code 1.87+) with Mocha:

```bash
npm install --save-dev @vscode/test-cli @vscode/test-electron
```

```typescript
// .vscode-test.mjs
import { defineConfig } from '@vscode/test-cli';
export default defineConfig({ files: 'out/test/**/*.test.js' });
```

```typescript
// src/test/extension.test.ts
import * as assert from 'assert';
import * as vscode from 'vscode';

suite('Extension Test Suite', () => {
    suiteSetup(async () => {
        await vscode.extensions.getExtension('publisher.myext')!.activate();
    });

    test('Command is registered', async () => {
        const commands = await vscode.commands.getCommands(true);
        assert.ok(commands.includes('myext.helloWorld'));
    });
});
```

Rules:
- Test the **activated extension** — not internal implementation details.
- For pure logic (parsers, validators), use `vitest` without extension host:
  faster feedback, no VS Code startup overhead.
- Always test the error path: what happens when a command throws?

### ESLint configuration

```json
// .eslintrc.json
{
  "root": true,
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/naming-convention": [
      "warn",
      { "selector": "variable", "format": ["camelCase", "UPPER_CASE"] }
    ],
    "no-throw-literal": "warn"
  }
}
```

### Publishing checklist

Before `vsce publish`:
1. `engines.vscode` pinned to a real version (not `*`).
2. `README.md` explains features, requirements, and usage with screenshots.
3. `CHANGELOG.md` entry for the new version.
4. `icon` field set to a 256×256 PNG (required for Marketplace).
5. `.vscodeignore` excludes `src/`, `node_modules/`, test files, and all
   source maps from the published package.
6. Bundle size verified (`vsce ls` to list packaged files).
7. Extension tested locally with `vsce package` + manual install.

```
# .vscodeignore
.vscode/**
src/**
test/**
out/test/**
node_modules/**
*.map
tsconfig.json
.eslintrc.json
```

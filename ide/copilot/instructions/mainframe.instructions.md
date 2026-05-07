---
applyTo: "**/*.cbl,**/*.cpy,**/*.jcl,**/*.proc,cobol/**"
---

# Instructions Mainframe IBM — GitHub Copilot

> **À propos de ce fichier**
> Ces instructions sont transmises automatiquement à GitHub Copilot lorsque vous éditez des fichiers COBOL (`.cbl`, `.cpy`), JCL (`.jcl`, `.proc`) ou tout fichier du dossier `cobol/`. Elles définissent les conventions IBM Enterprise COBOL 6.5 et JCL z/OS JES2 à respecter.
>
> Vous n'avez pas besoin de lire ce fichier pour utiliser l'environnement. Il est destiné aux développeurs qui souhaitent comprendre ou ajuster le comportement de Copilot sur le code mainframe.

---

# IBM Mainframe Instructions

---

## IBM z/OS Product Naming

When referencing any IBM product or subsystem in a z/OS context, always use
its full official product name including the **"for z/OS"** qualifier and the
version number when known. Never use informal short names alone.

| Short name (avoid alone) | Full name to use |
|---|---|
| VSAM | VSAM for z/OS |
| DB2 | IBM Db2 for z/OS 13 |
| CICS | IBM CICS Transaction Server for z/OS 6.2 |
| MQ / WMQ | IBM MQ for z/OS 9.4 |
| IMS | IBM IMS for z/OS 15.4 |
| File Manager | IBM File Manager for z/OS |
| RACF | IBM RACF for z/OS |
| RRS | z/OS Resource Recovery Services (RRS) |
| JES | z/OS JES2 (default) or z/OS JES3 |
| DFSMS | IBM DFSMS for z/OS |
| z/OSMF | IBM z/OS Management Facility |
| SMP/E | IBM SMP/E for z/OS |
| SDSF | IBM Spool Display and Search Facility (SDSF) for z/OS |

When the version is unknown, omit the version number but keep the
"for z/OS" qualifier (e.g. "IBM Db2 for z/OS").

---

## IBM Enterprise COBOL

The COBOL context is exclusively **IBM Enterprise COBOL 6.5 under z/OS 3.2**.
Never suggest GnuCOBOL, MicroFocus COBOL, or any non-IBM COBOL dialect.
Any `.cbl` file is an IBM mainframe COBOL source program. Any `.cpy` file is
an IBM mainframe COBOL copybook.

---

### Source format — fixed columns (mandatory)

IBM Enterprise COBOL 6.5 uses **fixed-format source** by default. Every
generated or analysed line must respect column boundaries:

```
Cols 1–6   : Sequence number (ignored by compiler, often blank or 000010…)
Col  7     : Indicator area
               ' ' (space)  — normal code line
               '*'          — comment line (prints but not compiled)
               '/'          — comment + page eject in listing
               '-'          — continuation of previous line
               'D'          — debug line (compiled only with DEBUG option)
               '*>'         — floating comment indicator (usable inline)
Cols 8–11  : Area A — DIVISION/SECTION headers, FD/SD entries,
                      level 01 and 77 data items, paragraph names,
                      DECLARATIVES and END DECLARATIVES
Cols 12–72 : Area B — all other statements, clauses, continuation
Cols 73–80 : Identification (ignored by compiler, historical only)
```

Never generate free-format COBOL (columns 1–255) unless the program
explicitly contains `>>SOURCE FORMAT FREE` or the SOURCEFORMAT(FREE)
compiler option.

**Continuation lines:** place `-` in column 7; open the literal with a
quote on the continuation line; close with quote + space on the last line
only. DBCS literals cannot be continued across lines.

**Scope terminators:** always use explicit terminators (`END-IF`,
`END-EVALUATE`, `END-PERFORM`, `END-READ`, `END-WRITE`, `END-REWRITE`,
`END-CALL`, `END-STRING`, `END-UNSTRING`, `END-DIVIDE`, etc.). Never rely on
a period `.` as the sole terminator inside a PROCEDURE DIVISION paragraph
body — use `.` only at the end of a paragraph.

---

### COBOL program structure

Every program must contain the four standard divisions in this order:

```cobol
000100 IDENTIFICATION DIVISION.
000200 PROGRAM-ID. program-name.
000300 AUTHOR.     author-name.
000400*
000500 ENVIRONMENT DIVISION.
000600 CONFIGURATION SECTION.
000700 SOURCE-COMPUTER.  IBM-MAINFRAME.
000800 OBJECT-COMPUTER.  IBM-MAINFRAME.
000900 INPUT-OUTPUT SECTION.
001000 FILE-CONTROL.
001100*    (SELECT … ASSIGN … clauses here)
001200*
001300 DATA DIVISION.
001400 FILE SECTION.
001500*    (FD entries here)
001600 WORKING-STORAGE SECTION.
001700*    (persistent data items here)
001800 LOCAL-STORAGE SECTION.
001900*    (re-initialized at each invocation — use for reentrant progs)
002000 LINKAGE SECTION.
002100*    (parameters passed by CALL or CICS COMMAREA)
002200*
002300 PROCEDURE DIVISION [USING …].
```

**Program end marker** — `END PROGRAM program-name.` is mandatory when the
source unit contains nested programs. Never omit it in that case.

**Nested programs:** a program without `COMMON` attribute is accessible only
by its direct container. Declare `COMMON` to make it accessible by the
container and all programs nested within that container.

**Header comment block** — every program must open with a comment block:
```cobol
      *================================================================*
      * PROGRAM   : <name>                                             *
      * AUTHOR    : <author>                                           *
      * DATE      : YYYY-MM-DD                                        *
      * PURPOSE   : <one-line description>                            *
      * INPUTS    : <list of input files / parameters>                *
      * OUTPUTS   : <list of output files / return values>            *
      * CHANGES   : YYYY-MM-DD <ticket> <author> - <description>     *
      *================================================================*
```

---

### DATA DIVISION — naming conventions

| Section | Prefix | Example |
|---|---|---|
| WORKING-STORAGE | `WS-` | `WS-RECORD-COUNT` |
| LOCAL-STORAGE | `LS-` | `LS-WORK-BUFFER` |
| LINKAGE SECTION | `LK-` | `LK-INPUT-PARM` |
| FILE SECTION records | `FD-` | `FD-CUSTOMER-REC` |

**Naming rules:**
- Use UPPER-CASE hyphenated names; minimum 8 characters for clarity.
- Suffix `-FLAG` for boolean indicators, `-COUNT` for counters,
  `-CODE` for status/return codes, `-STATUS` for FILE STATUS fields.
- Paragraphs and sections: numeric prefix + verb + subject —
  `1000-READ-CUSTOMER`, `2000-VALIDATE-AMOUNT`, `9000-CLOSE-FILES`,
  `9900-ABEND`. This makes the call hierarchy visible at a glance.
- Never use single-letter, numeric-only, or generic names (X, Y, FIELD1).

---

### Data types and internal representation

| COBOL clause | IBM internal format | Storage | Use case |
|---|---|---|---|
| `PIC 9(n) COMP` | Binary (halfword/fullword/dword) | 2/4/8 bytes | Binary integers — prefer COMP-5 instead |
| `PIC 9(n) COMP-3` | Packed decimal (BCD) | ⌈(n+1)/2⌉ bytes | **Financial amounts, all decimal data** |
| `PIC 9(n) COMP-4` | Binary, exact synonym for COMP | 2/4/8 bytes | Synonym — prefer COMP-5 instead |
| `PIC 9(n) COMP-5` | Native binary, TRUNC-independent | 2/4/8 bytes | **Indexes, subscripts, counters, return codes** |
| `USAGE IS INDEX` | Internal displacement (bytes) | System-defined | OCCURS table index with SET/SEARCH |
| `PIC 9(n)` | Zoned decimal (EBCDIC) | n bytes | Display fields, printable output, I/O boundaries |
| `PIC X(n)` | EBCDIC character string | n bytes | Alphanumeric fields |
| `PIC G(n)` | DBCS (double-byte) | 2×n bytes | Kanji / DBCS national characters |
| `COMP-1` | Short floating-point | 4 bytes | Scientific — never for business/finance |
| `COMP-2` | Long floating-point | 8 bytes | Scientific — never for business/finance |

**Rule — never do arithmetic on DISPLAY (PIC 9) items.** The compiler
inserts silent EBCDIC-to-packed conversions. Declare computation fields as
`COMP-3` from the start.

**Rule — always use `S` (sign) on numeric items** that can be negative or
participate in arithmetic, to avoid implicit sign-conversion overhead.

#### COMP-5 for all binary counters and indexes

Use `PIC S9(9) COMP-5` (fullword) or `PIC S9(4) COMP-5` (halfword) for
every loop counter, table subscript, record count, length field, and return
code. COMP-5 is native binary with no nibble truncation regardless of the
`TRUNC` compiler option. Never use COMP or COMP-4 — their truncation
behaviour depends on TRUNC and can produce silent wrong results.

```cobol
       05  WS-IDX          PIC S9(9) COMP-5 VALUE 0.  *> table subscript
       05  WS-REC-COUNT    PIC S9(9) COMP-5 VALUE 0.  *> record counter
       05  WS-LENGTH       PIC S9(9) COMP-5 VALUE 0.  *> buffer length
       05  WS-RC           PIC S9(4) COMP-5 VALUE 0.  *> return code (≤9999)
```

#### COMP-3 must always have an odd digit count

COMP-3 (PACKED-DECIMAL) stores 2 digits per nibble; the rightmost byte holds
1 digit + the sign nibble. Storage = ⌈(n+1)/2⌉ bytes. With an **even** digit
count the high nibble of the **leftmost** byte is wasted (zero-padded). IBM
Enterprise COBOL 6.5 Programming Guide (Chapter 3) states explicitly:

> *"This format is most efficient when you code an **odd** number of digits
> in the PICTURE description, so that the leftmost byte is fully used."*

Always declare an **odd** number of digits; if the business range requires an
even count, add 1 digit.

```cobol
*> ✗ Even — high nibble of leftmost byte wasted
       05  WS-AMOUNT-BAD   PIC S9(6)V99 COMP-3.   *> 8 digits → 5 bytes
       05  WS-CODE-BAD     PIC S9(4)    COMP-3.   *> 4 digits → 3 bytes

*> ✓ Odd — leftmost byte fully used, no waste
       05  WS-AMOUNT-OK    PIC S9(7)V99 COMP-3.   *> 9 digits → 5 bytes
       05  WS-CODE-OK      PIC S9(5)    COMP-3.   *> 5 digits → 3 bytes
       05  WS-TOTAL        PIC S9(13)V99 COMP-3.  *> 15 digits → 8 bytes
```

#### REDEFINES

- The redefining item must be the same length in bytes as the redefined item.
- Never code a `VALUE` clause on a `REDEFINES` entry.
- Always use `REDEFINES` for format-conversion overlays only; prefer separate
  variables and explicit `MOVE` when it aids readability.
- Document every `REDEFINES` with a comment explaining the overlay purpose.

```cobol
       05  WS-DATE-NUM     PIC 9(8).
       05  WS-DATE-PARTS   REDEFINES WS-DATE-NUM.
           10  WS-YEAR     PIC 9(4).
           10  WS-MONTH    PIC 9(2).
           10  WS-DAY      PIC 9(2).
```

---

### 88-level condition names

Always define 88-level condition names for every field that carries a
meaningful code. Never test raw literals directly in PROCEDURE DIVISION:

```cobol
       05  WS-RETURN-CODE     PIC S9(4) COMP-5.
           88  RC-OK           VALUE 0.
           88  RC-NOT-FOUND    VALUE 4.
           88  RC-ERROR        VALUE 8 THRU 99.

       05  WS-FILE-STATUS     PIC XX.
           88  FS-OK           VALUE '00'.
           88  FS-EOF          VALUE '10'.
           88  FS-DUP-KEY      VALUE '22'.
           88  FS-NOT-FOUND    VALUE '23'.
```

Usage: `IF RC-OK`, `SET RC-OK TO TRUE`, `EVALUATE TRUE WHEN RC-NOT-FOUND`.

---

### Structured programming patterns

#### EVALUATE (mandatory over nested IF for multi-branch logic)

- Always cover `WHEN OTHER` to trap unexpected values.
- Order `WHEN` clauses from the **most frequent** to the least frequent.

```cobol
* ── EVALUATE (preferred over nested IF) ────────────────────────────
           EVALUATE WS-TRANSACTION-TYPE
               WHEN 'INS'
                   PERFORM 1000-INSERT-RECORD
               WHEN 'UPD'
                   PERFORM 2000-UPDATE-RECORD
               WHEN 'DEL'
                   PERFORM 3000-DELETE-RECORD
               WHEN OTHER
                   PERFORM 9000-INVALID-TYPE-ERROR
           END-EVALUATE

* ── EVALUATE TRUE for complex multi-condition logic ─────────────────
           EVALUATE TRUE
               WHEN RC-OK
                   PERFORM 3000-PROCESS-RECORD
               WHEN RC-NOT-FOUND
                   PERFORM 9100-HANDLE-NOTFOUND
               WHEN OTHER
                   PERFORM 9900-ABEND
           END-EVALUATE
```

#### IF

- Use at most 3 levels of nesting. Beyond that, extract inner logic into a
  named paragraph and PERFORM it.
- Always use `END-IF`. Never use the period `.` as the sole IF terminator.
- Use 88-level names in conditions, never raw literals.

#### PERFORM

- Always use explicit `END-PERFORM`.
- Use `TEST AFTER` when the loop body must execute at least once (do-while).

```cobol
* ── Exit paragraph pattern ─────────────────────────────────────────
       2000-READ-FILE.
           READ INPUT-FILE
               AT END SET FS-EOF TO TRUE
           END-READ.
       2000-READ-FILE-EXIT.
           EXIT.

* ── PERFORM VARYING (for-loop) ────────────────────────────────────
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-MAX
               PERFORM 2000-PROCESS-ENTRY
           END-PERFORM

* ── PERFORM UNTIL with TEST AFTER (do-while) ──────────────────────
           PERFORM UNTIL WS-DONE = 'Y'
               WITH TEST AFTER
               PERFORM 2100-READ-NEXT
           END-PERFORM
```

**Avoid `GO TO`** except for the canonical paragraph-exit pattern
(`PERFORM … THRU …-EXIT`). Never use `ALTER`.

#### CALL — static vs dynamic

| | Static `CALL 'LITERAL'` | Dynamic `CALL variable` |
|---|---|---|
| Linkage | Link-edit time | Runtime load |
| Performance | Better | Overhead of dynamic load |
| Allowed for | **IBM modules only** | **All user programs** |

**Rule — dynamic calls for user programs, static calls for IBM modules only:**

- **Always** use `CALL variable` (dynamic) to call user-written programs.
  The program name is stored in a `PIC X(8)` WORKING-STORAGE field.
- **Only** use `CALL 'literal'` (static) for IBM-supplied modules:
  `'CBLTDLI'`, `'XMLINIT'`, `'CEE3DMP'`, `'CEE3ABD'`, etc.

```cobol
* ── Correct: dynamic call to a user program ─────────────────────────
       01  WS-PGM-NAME     PIC X(8) VALUE 'CUSTVAL '.

           CALL WS-PGM-NAME USING WS-INPUT-DATA WS-RETURN-CODE
           IF WS-RETURN-CODE NOT = 0
               PERFORM 9900-CALL-ERROR
           END-IF

* ── Correct: static call to an IBM module ───────────────────────────
           CALL 'CBLTDLI' USING DLI-GU PCB-MASK IO-AREA SSA-1.

* ── Forbidden: static call to a user program ────────────────────────
*          CALL 'CUSTVAL' USING ...   ← never do this
```

---

### PROCEDURE DIVISION — structure rules

- Organise in named SECTIONS; each section has a single logical responsibility.
- Keep paragraphs to **≤ 50 lines**; if longer, extract into a sub-paragraph.
- Naming: numeric prefix + verb + subject (`1000-READ-CUSTOMER`).
- Every batch program terminates with `STOP RUN`. Every subprogram terminates
  with `GOBACK`. Never use `STOP RUN` in CICS programs.
- Set `RETURN-CODE` before `STOP RUN`:
  - `0` = success
  - `4` = warnings (job continues)
  - `8` = errors (downstream steps should check condition)
  - `12`/`16` = severe/abend
- Display processing statistics before `STOP RUN` in batch programs.

---

### LOCAL-STORAGE vs WORKING-STORAGE

| Section | Re-initialized | Thread-safe | Use when |
|---|---|---|---|
| `WORKING-STORAGE` | Once at load | No | Single-threaded batch, static tables loaded once at startup |
| `LOCAL-STORAGE` | Each CALL/invocation | Yes | **CICS**, reentrant programs, multithreaded env |

Use `LOCAL-STORAGE` for all programs compiled with `RENT` (required under
CICS Transaction Server for z/OS). Do not place large static tables in
LOCAL-STORAGE (copied at every invocation = performance penalty).

---

### Arithmetic — error handling

Always code `ON SIZE ERROR` on every `DIVIDE` and on every arithmetic
operation where overflow is possible. Pre-check divisors for zero before
dividing.

```cobol
           IF WS-COUNT = ZERO
               PERFORM 9200-DIVISION-BY-ZERO
           ELSE
               DIVIDE WS-TOTAL BY WS-COUNT
                   GIVING WS-AVERAGE
                   ON SIZE ERROR
                       PERFORM 9200-OVERFLOW-ERROR
               END-DIVIDE
           END-IF
```

Code `ON OVERFLOW` on `STRING` and `UNSTRING` to guard against buffer overflow.

---

### Tables (OCCURS) — rules and patterns

**Declaration:**

```cobol
       01  WS-CUSTOMER-TABLE.
           05  WS-CUST-ENTRY OCCURS 1000 TIMES
                             ASCENDING KEY IS WS-CUST-KEY
                             INDEXED BY WS-CUST-IDX.
               10  WS-CUST-KEY     PIC X(8).
               10  WS-CUST-NAME    PIC X(40).
               10  WS-CUST-BALANCE PIC S9(13)V99 COMP-3.
```

- Always declare `INDEXED BY` on tables used with SEARCH / SEARCH ALL.
- For variable-length tables: use `OCCURS n TIMES DEPENDING ON data-name`
  (ODO); always update the ODO variable before accessing the table; always
  bound the maximum size.

**Search:**

| Need | Verb | Prerequisite |
|---|---|---|
| Small table (< 50), unsorted | `SEARCH` | `SET idx TO 1` before each search |
| Large table, sorted | `SEARCH ALL` | `ASCENDING/DESCENDING KEY IS` on OCCURS |

```cobol
* ── Serial search ──────────────────────────────────────────────────
           SET WS-CUST-IDX TO 1
           SEARCH WS-CUST-ENTRY
               AT END
                   MOVE 'N' TO WS-FOUND
               WHEN WS-CUST-KEY(WS-CUST-IDX) = WS-SEARCH-KEY
                   MOVE 'Y' TO WS-FOUND
           END-SEARCH

* ── Binary search (table must be sorted by WS-CUST-KEY) ─────────────
           SEARCH ALL WS-CUST-ENTRY
               AT END
                   MOVE 'N' TO WS-FOUND
               WHEN WS-CUST-KEY(WS-CUST-IDX) = WS-SEARCH-KEY
                   MOVE 'Y' TO WS-FOUND
                   MOVE WS-CUST-BALANCE(WS-CUST-IDX) TO WS-RESULT
           END-SEARCH
```

---

### File handling — QSAM (sequential files)

**Do not declare `FILE STATUS IS` on the SELECT clause for sequential
files.** Use `AT END` / `NOT AT END` on `READ` for EOF detection and a
record counter for empty-file detection.

**Other rules:**
- Always code `BLOCK CONTAINS 0 RECORDS` in every FD: DFSMS chooses the
  optimal block size automatically.
- Use `READ … INTO` and `WRITE … FROM` to keep the FD record area as a pure
  I/O buffer; do business logic on WORKING-STORAGE copies.
- For variable-length records (FORMAT V): JCL LRECL must be 4 bytes greater
  than the maximum COBOL record length.

```cobol
* ── SELECT — no FILE STATUS for sequential files ───────────────────
       SELECT INPUT-FILE
           ASSIGN TO INFILE
           ORGANIZATION IS SEQUENTIAL.

       FD  INPUT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 100 CHARACTERS.
       01  IN-RECORD   PIC X(100).

* ── WORKING-STORAGE ─────────────────────────────────────────────────
       01  WS-IN-RECORD    PIC X(100).
       01  WS-REC-COUNT    PIC S9(9) COMP-5 VALUE 0.
       01  WS-EOF-FLAG     PIC X VALUE 'N'.
           88  WS-EOF      VALUE 'Y'.

* ── PROCEDURE DIVISION ──────────────────────────────────────────────
       1000-INIT.
           OPEN INPUT INPUT-FILE
           PERFORM 2100-READ-NEXT.

       2000-PROCESS.
           PERFORM UNTIL WS-EOF
               PERFORM 2200-PROCESS-RECORD
               PERFORM 2100-READ-NEXT
           END-PERFORM
           IF WS-REC-COUNT = 0
               PERFORM 9100-EMPTY-FILE-ERROR   *> file was empty
           END-IF.

       2100-READ-NEXT.
           READ INPUT-FILE INTO WS-IN-RECORD
               AT END
                   SET WS-EOF TO TRUE
               NOT AT END
                   ADD 1 TO WS-REC-COUNT
           END-READ.
```

---

### File handling — VSAM for z/OS

```cobol
* ── KSDS (Key-Sequenced Data Set) ──────────────────────────────────
       SELECT CUSTOMER-FILE
           ASSIGN TO AS-CUSTFILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS CUST-ID
           ALTERNATE RECORD KEY IS CUST-NAME WITH DUPLICATES
           FILE STATUS IS WS-CUST-STATUS WS-VSAM-STATUS.

* ── ESDS (Entry-Sequenced Data Set) ────────────────────────────────
       SELECT AUDIT-FILE
           ASSIGN TO AS-AUDITFL
           ORGANIZATION IS SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS WS-AUDIT-STATUS WS-VSAM-AUD-STATUS.

* ── RRDS (Relative Record Data Set) ────────────────────────────────
       SELECT TABLE-FILE
           ASSIGN TO AS-TABLEFL
           ORGANIZATION IS RELATIVE
           ACCESS MODE IS RANDOM
           RELATIVE KEY IS WS-REL-KEY
           FILE STATUS IS WS-TABLE-STATUS WS-VSAM-TBL-STATUS.
```

**Double FILE STATUS for VSAM (mandatory):** the second 6-byte field gives
the detailed VSAM diagnostic codes (RETURN code, FUNCTION code, FEEDBACK
code) that are essential for diagnosing failures.

```cobol
       01  WS-CUST-STATUS     PIC X(2).         *> standard COBOL code
           88  VSAM-OK         VALUE '00'.
           88  VSAM-DUPLICATE  VALUE '22'.
           88  VSAM-NOT-FOUND  VALUE '23'.
           88  VSAM-EOF        VALUE '10'.

       01  WS-VSAM-STATUS.                       *> VSAM detail code
           05  WS-VSAM-RETURN   PIC S9(4) COMP-5.
           05  WS-VSAM-FUNC     PIC S9(1) COMP-5.
           05  WS-VSAM-FEEDBACK PIC S9(3) COMP-5.
```

Always check FILE STATUS after every READ, WRITE, REWRITE, DELETE,
START, and OPEN/CLOSE. Use 88-level condition names on the status field.

**VSAM FILE STATUS codes to handle:**

| Code | Meaning |
|---|---|
| `00` | Success |
| `02` | Success with duplicate on alternate key |
| `10` | End-of-file |
| `21` | Key sequence error (sequential write) |
| `22` | Duplicate primary key |
| `23` | Record not found |
| `24` | Out of bounds (RRDS) or disk full (KSDS) |
| `35` | File not found or unavailable |
| `39` | Attribute conflict (RECFM/LRECL/KEY mismatch with FD) |
| `49` | REWRITE without OPEN I-O |
| `92` | DELETE without prior READ (sequential access) |

**VSAM performance rules:**
- Load a KSDS with `OPEN OUTPUT` + `ACCESS IS SEQUENTIAL`.
- Sequential access > dynamic > random.
- Code `BUFND` and `BUFNI` in the JCL AMP parameter when performance is
  critical.
- Sequential DELETE: always `READ` the record first, then `DELETE`.
- In multithreading: always open and close a VSAM file from the **same thread**.

---

### SORT and MERGE

#### Preferred approach — DFSORT in JCL (new code)

**Do not code internal SORT (COBOL SORT verb) in new programs.**
Invoke DFSORT directly in JCL whenever the sort can be expressed as a
standalone step: cleaner separation of concerns, better performance.

```jcl
//SORTMAIN EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=INPUT.FILE,DISP=SHR
//SORTOUT  DD DSN=OUTPUT.FILE,DISP=(NEW,CATLG),
//            SPACE=(CYL,(10,5)),DCB=RECFM=FB
//SORTWK01 DD UNIT=SYSDA,SPACE=(CYL,(5,2))
//SORTWK02 DD UNIT=SYSDA,SPACE=(CYL,(5,2))
//SORTWK03 DD UNIT=SYSDA,SPACE=(CYL,(5,2))
//SYSIN    DD *
  SORT FIELDS=(1,10,CH,A)
/*
```

#### Rules when COBOL SORT is unavoidable

- Always check `SORT-RETURN` after every `SORT`/`MERGE` statement:
  `0` = success, `16` = failure.
- Always code `FASTSRT` compiler option.
- Declare `SORTWK01`, `SORTWK02`, `SORTWK03` DD statements in JCL.
- **Absolute ban** in programs compiled with `THREAD`.
- **Absolute ban** under CICS for FORMAT 1 SORT (with USING/GIVING).

```cobol
      *> Acceptable only when DFSORT in JCL is not feasible
           SORT SORT-FILE
               ON ASCENDING KEY SORT-KEY
               USING  INPUT-FILE
               GIVING OUTPUT-FILE
           IF SORT-RETURN NOT = 0
               DISPLAY 'SORT FAILED RC=' SORT-RETURN
               PERFORM 9900-ABEND
           END-IF
```

---

### z/OS subsystem integration

**IBM Db2 for z/OS 13 (embedded SQL)**

```cobol
       WORKING-STORAGE SECTION.
           EXEC SQL INCLUDE SQLCA END-EXEC.         *> SQL Comm. Area
           EXEC SQL INCLUDE DCLCUSTOMER END-EXEC.   *> table DCLGEN

       PROCEDURE DIVISION.
           EXEC SQL
               SELECT CUST_NAME, CUST_BALANCE
               INTO   :WS-CUST-NAME, :WS-BALANCE
               FROM   CUSTOMER
               WHERE  CUST_ID = :WS-CUST-ID
           END-EXEC
           EVALUATE SQLCODE
               WHEN 0      CONTINUE
               WHEN 100    PERFORM 9100-NOT-FOUND
               WHEN OTHER  PERFORM 9900-SQL-ERROR
           END-EVALUATE.
```

Rules: always `INCLUDE SQLCA`, check `SQLCODE` after every SQL statement,
use `DCLGEN`-generated host variable declarations.

**IBM CICS Transaction Server for z/OS 6.2 (embedded commands)**

```cobol
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05  CA-KEY    PIC X(8).
           05  CA-DATA   PIC X(100).

       PROCEDURE DIVISION.
           EXEC CICS HANDLE ABEND LABEL(9900-CICS-ABEND) END-EXEC.
           EXEC CICS RECEIVE MAP('MAPNAME') MAPSET('MAPSETNA')
                     INTO(WS-MAP-DATA) END-EXEC.
           EXEC CICS RETURN TRANSID('TRNI')
                     COMMAREA(DFHCOMMAREA) END-EXEC.
```

Rules: use `LOCAL-STORAGE` (not `WORKING-STORAGE`) for all working
variables; compile with `RENT`; never use `STOP RUN`; always handle abends.

**IBM IMS for z/OS 15.4 (DL/I calls)**

```cobol
           CALL 'CBLTDLI' USING DLI-GU
                                PCB-MASK
                                IO-AREA
                                SSA-1.
```

---

### XML and JSON parsing on z/OS

Never use the built-in COBOL `XML PARSE`, `XML GENERATE`, `JSON PARSE`, or
`JSON GENERATE` statements for production code. Always prefer a dedicated
z/OS parser.

**XML — preferred parsers**

| Parser | Product / availability | When to use |
|---|---|---|
| **IBM XML Toolkit for z/OS** | 5655-J51 — also free SMP/E download | Full-featured: SAX2, DOM, XPath 1.0, XSLT 1.0, XSD validation |
| **z/OS XML System Services** | Part of z/OS base (no extra product) | Lightweight streaming (SAX-like) for high-throughput batch XML |

**JSON — preferred parsers and integration methods**

| Method | Context | When to use |
|---|---|---|
| **IBM z/OS Connect** | REST API integration | All external REST/JSON APIs |
| **CICS DFHJSON service** | IBM CICS TS for z/OS 6.2 | Within CICS transactions |
| **IBM Db2 for z/OS 13 JSON SQL functions** | DB2 context | `JSON_TABLE`, `JSON_VALUE`, `JSON_QUERY` in SQL |
| **YAJL for z/OS** | Batch / UNIX SS | Dynamic or schema-less JSON in batch |

```cobol
*> ── DB2 for z/OS 13: parse JSON in SQL, no COBOL parsing needed ────
           EXEC SQL
               SELECT J.CUST_NAME, J.BALANCE
               INTO   :WS-CUST-NAME, :WS-BALANCE
               FROM   JSON_TABLE(
                          :WS-JSON-DOC FORMAT JSON,
                          'lax $.customers[*]'
                          COLUMNS (
                              CUST_NAME VARCHAR(50) PATH '$.name',
                              BALANCE   DECIMAL(13,2) PATH '$.balance'
                          )
                      ) AS J
           END-EXEC.
```

**When the built-in statements are acceptable**

| Statement | Acceptable only when |
|---|---|
| `XML PARSE` | Unit tests, one-off utilities, trivial structure, no validation required |
| `JSON PARSE` / `JSON GENERATE` | Simple fixed-structure messages, prototyping |

Always add a comment explaining why the built-in statement is used instead
of the preferred parser, and document the known limitations.

---

### Compiler options

**Development (DEV/TEST) baseline:**

```cobol
       PROCESS RENT,RMODE(ANY),AMODE(31),OFFSET,NODYNAM,
               DATA(31),OPT(0),SSRANGE,TEST(SOURCE),TRAP(ON).
      *PROCESS SQL,CICS.   ← add when needed
```

**Production baseline:**

```cobol
       PROCESS RENT,RMODE(ANY),AMODE(31),OFFSET,NODYNAM,
               DATA(31),OPT(2),ARCH(10),TUNE(10),FASTSRT,
               HGPR(PRESERVE),NUMPROC(PFD),TRUNC(BIN),TRAP(ON).
      *PROCESS SQL,CICS.   ← add when needed
```

| Option | Effect | Environment |
|---|---|---|
| `RENT` | Reentrant code — required for CICS and multithreaded | Always |
| `RMODE(ANY)` | Residence above 16 MB line | Default |
| `AMODE(31)` | 31-bit addressing | Standard |
| `DATA(31)` | Data storage above 16 MB line | Always for new programs |
| `NODYNAM` | Static CALL linkage — better performance | Default |
| `DYNAM` | Dynamic CALL resolution at runtime | When called modules may be replaced |
| `OFFSET` | Offset listing for debugging | Always |
| `OPT(2)` | Maximum compiler optimisation | Production |
| `OPT(0)` | No optimisation — better debug symbols | DEV/TEST |
| `ARCH(10)` / `TUNE(10)` | z/Architecture instructions and tuning | Production |
| `FASTSRT` | Delegate SORT I/O to DFSORT | Production |
| `HGPR(PRESERVE)` | Preserve high general-purpose registers | Production (DFSORT) |
| `NUMPROC(PFD)` | Skip sign-fix on DISPLAY fields — faster | Production |
| `TRUNC(BIN)` | No truncation on binary fields | With COMP-5 |
| `SSRANGE` | Validate table subscripts and reference modification | DEV/TEST only |
| `TEST(SOURCE)` | Debug symbols for IBM Debug Tool | DEV/TEST |
| `TRAP(ON)` | Intercept runtime conditions | Always |
| `SQL` | Activate DB2 precompiler pass | DB2 programs |
| `CICS` | Activate CICS translator pass | CICS programs |

---

### Copybooks

- Any `.cpy` file is an IBM mainframe COBOL copybook.
- Include with the `COPY` statement; the library is resolved via the
  `SYSLIB` DD in the compile JCL.
- Use `REPLACING` to prefix data names and avoid collisions.

```cobol
* ── Simple inclusion ────────────────────────────────────────────────
           COPY CUSTDATA.

* ── Inclusion with prefix replacement ──────────────────────────────
           COPY CUSTDATA REPLACING ==:CUST:== BY ==WS-CUSTOMER==.

* ── DCLGEN copybook (IBM Db2 for z/OS) ─────────────────────────────
       EXEC SQL INCLUDE DCLCUSTOMER END-EXEC.
```

---

### Refactoring — code smells and corrective actions

| Code smell | Corrective action |
|---|---|
| Paragraphs > 50 lines | Extract sub-paragraphs; each unit does one thing |
| Cascade IF/ELSE > 3 levels | Replace with `EVALUATE` |
| Same logic duplicated in ≥ 2 paragraphs | Extract into a shared paragraph or subprogram |
| Raw literals in PROCEDURE DIVISION | Replace with 88-level condition names or named constants |
| `FILE STATUS IS` on a sequential file SELECT | Remove it; use `AT END`/`NOT AT END` on READ |
| FILE STATUS never checked (VSAM / indexed files) | Add double FILE STATUS and check after every I/O verb |
| Cryptic names (X, Y, AA, BB) | Rename with descriptive hyphenated names + section prefix |
| WORKING-STORAGE in a CICS/RENT program | Move work areas to LOCAL-STORAGE |
| COMP or COMP-4 for counters/indexes | Replace with COMP-5 |
| Even digit count on COMP-3 items | Adjust to odd (add 1 digit) |
| `GO TO` jumping to distant labels | Refactor to structured `PERFORM … UNTIL` |
| Missing `END-IF` / `END-EVALUATE` / `END-PERFORM` | Add explicit scope terminators |
| Arithmetic without `ON SIZE ERROR` | Add size-error handler; pre-check divisors |
| COBOL SORT verb in a new program | Replace with a DFSORT step in JCL |
| SORT without `SORT-RETURN` check | Add check immediately after SORT/MERGE |
| `CALL 'literal'` to a user program | Replace with `CALL variable` (dynamic) |
| Single FILE STATUS for VSAM | Add double FILE STATUS (standard + VSAM detail) |

---

### Intrinsic functions — IBM Enterprise COBOL 6.5

Use `FUNCTION` keyword; no `USING` clause required.

**Date and time**

| Function | Returns | Notes |
|---|---|---|
| `FUNCTION CURRENT-DATE` | `PIC X(21)` | `YYYYMMDDHHMMSSCChh mm` |
| `FUNCTION WHEN-COMPILED` | `PIC X(21)` | Fixed at compile time |
| `FUNCTION INTEGER-OF-DATE(yyyymmdd)` | Integer day | Days since 31 Dec 1600 |
| `FUNCTION INTEGER-OF-DAY(yyyyddd)` | Integer day | From Julian date |
| `FUNCTION DATE-OF-INTEGER(int)` | `PIC 9(8)` YYYYMMDD | Reverse of INTEGER-OF-DATE |
| `FUNCTION DAY-OF-INTEGER(int)` | `PIC 9(7)` YYYYDDD | Reverse of INTEGER-OF-DAY |
| `FUNCTION FORMATTED-DATE(fmt, int)` | Formatted string | e.g. `'YYYY-MM-DD'` |
| `FUNCTION FORMATTED-TIME(fmt, secs, offset)` | Formatted string | e.g. `'hh:mm:ss'` |
| `FUNCTION FORMATTED-DATETIME(fmt, int, secs, offset)` | Formatted string | Combined date+time |

**Validation**

| Function | Returns | Notes |
|---|---|---|
| `FUNCTION TEST-DATE-YYYYMMDD(n)` | Integer | 0 = valid, >0 = error position |
| `FUNCTION TEST-NUMVAL(str)` | Integer | 0 = valid numeric string |
| `FUNCTION TEST-NUMVAL-C(str, sym)` | Integer | 0 = valid currency string |
| `FUNCTION TEST-NUMVAL-F(str)` | Integer | 0 = valid floating-point string |

**String manipulation**

| Function | Returns | Notes |
|---|---|---|
| `FUNCTION UPPER-CASE(str)` | Same length | EBCDIC-aware uppercase |
| `FUNCTION LOWER-CASE(str)` | Same length | EBCDIC-aware lowercase |
| `FUNCTION REVERSE(str)` | Same length | Reverses character order |
| `FUNCTION TRIM(str [LEADING\|TRAILING])` | Variable | Removes spaces |
| `FUNCTION LENGTH(item)` | Integer | Length in characters |
| `FUNCTION STORED-CHAR-LENGTH(item)` | Integer | IBM extension: excludes trailing spaces |
| `FUNCTION SUBSTITUTE(src, from, to)` | String | Replace all occurrences (6.3+) |
| `FUNCTION SUBSTITUTE-CASE(src, from, to)` | String | Case-insensitive replace (6.3+) |
| `FUNCTION CONCATENATE(a, b, …)` | String | IBM extension |
| `FUNCTION HEX-OF(item)` | `PIC X(2n)` | IBM extension: hex representation |
| `FUNCTION HEX-TO-CHAR(hex-str)` | `PIC X(n/2)` | IBM extension: hex to characters |
| `FUNCTION UUID4` | `PIC X(36)` | UUID v4 string (IBM extension, 6.3+) |

**Numeric**

| Function | Returns | Notes |
|---|---|---|
| `FUNCTION ABS(n)` | Numeric | Absolute value |
| `FUNCTION INTEGER(n)` | Integer | Floor (toward −∞) |
| `FUNCTION INTEGER-PART(n)` | Integer | Truncation toward zero |
| `FUNCTION MAX(a, b, …)` | Same type | Maximum of list |
| `FUNCTION MIN(a, b, …)` | Same type | Minimum of list |
| `FUNCTION MOD(n, m)` | Numeric | Modulus (always non-negative) |
| `FUNCTION REM(n, m)` | Numeric | Remainder (sign follows dividend) |
| `FUNCTION SQRT(n)` | Numeric | Square root |

**Conversion (string ↔ numeric)**

| Function | Returns | Notes |
|---|---|---|
| `FUNCTION NUMVAL(str)` | Numeric | Parses `'  123.45 '` |
| `FUNCTION NUMVAL-C(str, sym)` | Numeric | Parses `'$1,234.56'` |
| `FUNCTION NUMVAL-F(str)` | Float | Parses `'1.23E+04'` |

---

## JCL (z/OS JES2)

- Context is exclusively **z/OS JES2** (JES3 only if explicitly stated).
- Always use `//` in columns 1–2. Statement length max 71 chars (cols 3–71);
  continue on next line with `//` in cols 1–2 and at least one space.
- DD names must not exceed 8 characters; step names and procedure names
  follow the same 8-character limit.
- Always code `MSGLEVEL=(1,1)` and `REGION=0M` (or explicit value) on
  the `JOB` card.
- Code `COND=EVEN` or use `IF/THEN/ELSE/ENDIF` constructs — never rely on
  default condition handling.
- Use `SYSOUT=*` for standard print output; `SYSOUT=X` for held output.
- STEPLIB / JOBLIB must reference authorized libraries only when APF
  authorization is required; document the reason in a `//` comment.
- Never hard-code DSN with volume serial numbers unless absolutely required
  by the site configuration.
- For every SORT step include at minimum `SORTWK01`, `SORTWK02`, `SORTWK03`
  DD statements.
- `BLOCK CONTAINS 0 RECORDS` in FD + no explicit `BLKSIZE` on DD: DFSMS
  determines the optimal block size automatically.

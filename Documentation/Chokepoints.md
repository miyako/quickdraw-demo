# Engineering notes: building QuickDraw Lab

Everything below was observed in this repository on macOS 25.x (arm64),
4D 21 R5 build 100175, `quickdraw` component 0.1.3 / CLI protocol 0.1.0,
with the skills snapshot pinned as the `.agents` submodule.

## 1. `Get 4D folder` returns an HFS path on macOS

The first interpreted run produced:

```
tool4d.FiFo [3] A valid posix path was expected.
tool4d.4DRT [-10716] Object or Collection Expected.
```

`Lab`'s constructor built folders like this:

```4d
This.samplesFolder:=Folder(Get 4D folder(Current resources folder)+"Samples"; fk platform path)
```

On macOS `Get 4D folder` returns `Macintosh HD:private:tmp:…:Resources:`, while
`fk platform path` expects POSIX. `Folder()` therefore returned Null, and every
later `.folder()` / `.exists` access cascaded into `-10716` / `-55` errors.

Fix — branch on platform:

```4d
$resources:=Convert path system to POSIX(Get 4D folder(Current resources folder))
This.samplesFolder:=Folder($resources+"Samples"; fk posix path)
```

(Windows keeps `fk platform path`.) This is not covered by the current
`4dcli` "Path Arguments" section, which discusses `File()`/`Folder()` for
**paths you pass in**, not paths 4D itself returns.

## 2. `inspect` and `convert` accept different options

`Converter.md` lists `inspect(input; options)` with container selection,
budgets, data fork and resource ID. `fidelity` and `font-map` belong to
`convert`. Passing them to `inspect` fails as an argument error:

```
argument: invalid_argument — Unsupported option for inspect: fidelity
```

This is easy to get wrong when writing a demo around "inspect the picture,
then convert it": the strict/approximate decision is exclusively a conversion
decision, so the UI's Inspect button must not forward the fidelity dropdown.

## 3. `version()` / `capabilities()` return the process envelope

```json
{"ok":true,"stdout":"{\"protocol\":1,\"version\":\"0.1.0\"}\n","stderr":"","exitCode":0,
 "value":{"protocol":1,"version":"0.1.0"}}
```

The docs describe the payload; the class returns the envelope for **every**
public call, including these two zero-argument ones. `Lab_Load` unwraps `.value`
and keeps defaults when `ok` is false.

## 4. tool4d runs On Startup before `--startup-method`

A headless run initially printed:

```
tool4d.HDLS (Open form window)…  ()
tool4d.HDLS (DIALOG)…  ()
```

`onStartup` calls the startup pattern, which opens the Lab window; tool4d has no
window server, so those commands fail before `Lab_SelfCheck` gets far. The
`4dcli` skill documents `--skip-onstartup`; using it is mandatory here.

## 5. Dependency manager vs stage `Components/`

`tool4d` reports:

```
PackageManager Dependency 'quickdraw' cannot be found
```

for the committed github+tag declaration. Two runs are therefore different:

* **IDE run** — real `dependencies.json`, Dependencies panel installs 0.1.3.
* **Headless run** — stage `Components/quickdraw.4dbase` and rewrite
  `dependencies.json` to `{}` in a scratch copy (`tools/run_selfcheck.sh`).

Do not commit the staged `Components/` folder or the empty declaration.

## 6. Object-based dropdowns: `index` first, `currentValue` is a placeholder

After setting `values` and `currentValue`, reading `currentValue` returns the
original placeholder even when the user picked another row. Selection must be
resolved as:

```4d
$value:=$drop.values[$drop.index]   // fall back to currentValue only when index is missing
```

`README` of the demo previously showed `currentValue` as the selection; the
class now centralises this in `Lab.choice()`.

## 7. Form schema traps (`4dform`)

* `multiline` must be `"automatic"`, `"yes"` or `"no"` — a JSON Boolean is
  rejected by the schema.
* The input watermark key is `placeholder`, not `placeholderText`.
* Group box captions use `text`.
* Listbox columns need `resizingMode: "legacy"`, `truncateMode: "none"` and a
  `rowHeight` string such as `"22px"`; collection listboxes need
  `listboxType: "collection"` + `dataSource: "Form.rows"`.

## 8. Two smaller ones

* `Generate digest` inside a helper raised a runtime `[59]` while the folder
  paths were still Null; after the folder fix and an explicit `Blob` variable
  the same call works. No isolated reproducer was retained — treat the message
  as "fix the earlier type error first", not as a digest API bug.
* `tool4d` interprets a missing `Project/Sources/dependencies.json` as a modal
  import prompt. Every project opened headlessly must ship the file first
  (already true in this repo).

## Proposed edits to `miyako/skills`

1. **`4dcli` → new subsection "Paths 4D returns"**: `Get 4D folder(*)` yields
   an HFS path on macOS; wrap with `Convert path system to POSIX` before
   `Folder(…; fk posix path)`. Include the `[3]` / `-10716` symptom pair.
2. **`4dcli` → "Compiling with a Component Dependency"**: add the headless
   recipe used here — stage `Components/`, copy the project to scratch, and
   replace `dependencies.json` with `{}`; keep the github+tag declaration in
   the repository. Mention `--skip-onstartup` in the same paragraph, because a
   host demo usually opens a window On Startup.
3. **`4dform`**: add a short "object dropdown" note (`currentValue` is the
   placeholder; read `index`), and keep `multiline`/`placeholder` in the
   property tables.
4. **`4dcomponent`/`quickdraw` docs are external to this repo** — no edit
   proposed beyond reporting the inspect-vs-convert option split, which the
   component's own documentation already implies but does not contrast.

## Review round: defects found by exercising the UI paths

The original 11 checks only drove the class, so these shipped unnoticed:

* **`Value type(...)=Is number`** (six places). `Is number` is not what
  `Value type` returns; object numbers are `Is real` (`4dlang` pitfalls). Effects:
  the dropdown `index` was never used (selections fell back to the write-once
  `currentValue`), error `offset`/`opcode` were dropped from every message, and
  `Select document` (which returns Text) made `Open…` a no-op.
* **`"0x"+String(opcode; "&x")`** printed `0x0x0051`: the `&x` format already
  includes the prefix.
* **Inputs on `On After Edit`** read the pre-edit value and ran a CLI call per
  keystroke; they now use `On Data Change`. Container, data-fork and resource-ID
  changes also refresh the preview, not just the inspection.
* **No-clobber experiment** used the visible options; on the default strict
  `poster.pict` the first write was rejected as `unsupported`, so exit 3 was never
  shown. It now forces approximate fidelity.
* **State leaks**: switching samples kept the previous data-fork/container;
  Reset cleared `resource-id` (making `drawing.rsrc` ambiguous) and the font map;
  Rescan dropped a file chosen with `Open…`; invalid numeric text was silently
  ignored (now named in the status line).
* **Inspect** showed an empty `selection:` (property is `resource_id`, not
  `selected_resource`), and several `For each` variables were undeclared.
* Form-dependent project methods were visible in Run Method; they are now
  `invisible`. `.gitignore` tool entries are anchored per `4dproject`.
* **`File.extension` keeps its dot and `File.name` drops the extension.**
  `samples()` compared against `"pict"`, so the Sample dropdown was empty on
  open and Inspect/Preview never ran; found only by opening the form in 4D.
  Status lines used `.name` and lost the extension (`fullName` now).
* **A Null Object parameter still has `Value type` `Is object`**, so previews
  without a conversion claimed "the strict conversion above was rejected".
* `FORM SCREENSHOT` captures of this form are transparent in dark appearance;
  composite over `#1E1E1E` before judging layout (see `4dform`
  screenshot-rendering).


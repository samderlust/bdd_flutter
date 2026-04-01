# MCP Server Implementation Plan for bdd_flutter

## Overview

Add an `mcp` command to the existing CLI that starts an MCP server over **stdio**. AI agents can then parse features, generate tests, validate syntax, and get a syntax guide — all through MCP tools.

## New Dependency

```yaml
# pubspec.yaml
dependencies:
  dart_mcp: ^0.1.0  # or use raw JSON-RPC over stdin/stdout (zero deps)
```

> If `dart_mcp` is too heavy or unstable, we can implement the MCP protocol manually with just `dart:io` + `dart:convert` (stdin/stdout JSON-RPC). It's ~200 lines of boilerplate.

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/src/presentation/mcp/bdd_mcp_server.dart` | **New** | MCP server class, registers tools |
| `lib/src/presentation/cli/bbd_cli.dart` | **Edit** | Add `mcp` command to switch statement |
| `bin/bdd_flutter.dart` | No change | Already delegates to CLI |
| `pubspec.yaml` | **Edit** | Add MCP dependency (if using a package) |

## MCP Tools to Expose

### 1. `bdd_parse_feature`
- **Input**: `{ "file_path": "test/login/login.feature" }` or `{ "content": "Feature: Login\n..." }`
- **Output**: JSON representation of the parsed Feature model (scenarios, steps, decorators)
- **Uses**: `FeatureParser.parseFeature()` — already exists

### 2. `bdd_build_tests`
- **Input**: `{ "file_path": "test/login/login.feature", "force": false }`
- **Output**: Success message with paths of generated files
- **Uses**: `BDDController.generateFeatureTestCases()` — already exists

### 3. `bdd_validate_feature`
- **Input**: `{ "content": "Feature: Login\n..." }` or `{ "file_path": "..." }`
- **Output**: List of errors/warnings (missing Feature:, empty scenarios, etc.)
- **Uses**: New lightweight validation on top of `FeatureParser`

### 4. `bdd_preview_generated_code`
- **Input**: `{ "content": "Feature: Login\n..." }` or `{ "file_path": "..." }`
- **Output**: The generated `.bdd_scenarios.dart` and `.bdd_test.dart` content (without writing files)
- **Uses**: `ScenariosFileBuilder` + `TestFileBuilder` — already exist

### 5. `bdd_get_syntax_guide`
- **Input**: none
- **Output**: Gherkin syntax guide with bdd_flutter-specific decorators and examples
- **Uses**: Returns a static string (embedded documentation)

## Architecture

```
bin/bdd_flutter.dart
  → BDDCLI.run(['mcp'])
    → BDDMcpServer.start()          # NEW
      ├─ listens on stdin (JSON-RPC)
      ├─ registers 5 tools
      └─ responds on stdout
```

The server reuses existing classes — no duplication of parsing/building logic.

## How Users Configure It

**In Claude Code** (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "bdd_flutter": {
      "command": "dart",
      "args": ["run", "bdd_flutter", "mcp"]
    }
  }
}
```

Or per-project in `.claude/settings.local.json` (same format).

> **Note**: The server runs in the current working directory by default (usually the project root). If needed, you can add `"cwd": "/path/to/project"` to override.

## How an AI Agent Uses It

Once configured, Claude (or any MCP-compatible agent) can:

```
1. User: "Write a BDD test for user registration"

2. Agent calls bdd_get_syntax_guide → learns the .feature syntax

3. Agent writes a .feature file:
   Feature: User Registration
     Scenario: Successful registration
       Given I am on the registration page
       When I enter valid credentials
       Then I should see the dashboard

4. Agent calls bdd_preview_generated_code with the content
   → sees the generated scenario class + test file

5. Agent calls bdd_build_tests to generate the actual files

6. Agent fills in the TODO stubs in the .bdd_scenarios.dart file
```

## Estimated Effort

- **1 new file** (~150-250 lines): `bdd_mcp_server.dart`
- **2 small edits**: CLI + pubspec
- The protocol handling is the only new code; all domain logic is reused

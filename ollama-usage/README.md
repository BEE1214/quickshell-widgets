# ollama-usage

Bar chip for the iNiR shell showing local Ollama status: total size of loaded
models (or `idle` / `off`), with a hover popup listing each model, GPU share and
time until unload. Polls `http://127.0.0.1:11434/api/ps` every 10 s.

Install like `claude-usage/inir`: `OllamaUsage.qml` → `services/`,
`OllamaUsageBar.qml` → `modules/bar/`, register both in the `qmldir` files, add an
`ollamaUsage` component in `BarContent.qml` and `ollamaUsage` to `bar.layout.right`.

Ollama Cloud limits are not included yet (no documented usage API).

## Server URL

The URL is read from `bar.ollama.host` (default `http://127.0.0.1:11434`). iNiR's
config is a fixed schema, so the key must be declared in `modules/common/Config.qml`
inside the `bar` object, before `weather`:

```qml
property JsonObject ollama: JsonObject {
    property string host: "http://127.0.0.1:11434"
}
```

Unknown keys in `config.json` are silently dropped on the next save.

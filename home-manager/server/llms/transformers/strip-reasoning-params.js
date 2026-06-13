// Claude Code always sends a `reasoning_effort` (and sometimes `thinking` /
// `enable_thinking`) field based on its global `effortLevel` setting, even
// for non-Claude models. Ollama's /v1/chat/completions rejects these with
// "<model> does not support thinking" for models with no thinking mode
// (e.g. qwen3-coder:30b). Strip them before the request reaches Ollama.
// https://github.com/musistudio/claude-code-router/issues/972
class StripReasoningParams {
  constructor(options) {
    this.options = options;
    this.name = "strip-reasoning-params";
  }

  async transformRequestIn(request) {
    delete request.reasoning_effort;
    delete request.reasoning;
    delete request.thinking;
    delete request.enable_thinking;
    return request;
  }
}

module.exports = StripReasoningParams;

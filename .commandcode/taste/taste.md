# Taste (Continuously Learned by [CommandCode][cmd])

[cmd]: https://commandcode.ai/

# daisy-chain
- For the handoff daisy-chain loop: run.sh should open cmd directly in a new visible terminal per task, not hide it in a subprocess. Kill the terminal when done, start a new one for the next task. Confidence: 0.80
- Keep the daisy-chain loop simple: open cmd, paste prompt, wait for completion, kill terminal, start next. Avoid wrapper scripts, base64 encoding, complex quoting. Confidence: 0.70
- Do not improvise or add complexity beyond what was explicitly requested. Execute instructions literally and minimally. Confidence: 0.70
- Between ticker iterations in the daisy-chain loop, run 'git add .', then 'git commit -m \"added (ticker)\"', then 'git push'. Only proceed to the next ticker after git push finishes. Confidence: 0.70

# data-flow
- For the handoff data pipeline: AI should write findings to temporary files (urls_temp.sh, last-result.json), then scripts append those to main files (download_reports.sh, result-log.json). Confidence: 0.85


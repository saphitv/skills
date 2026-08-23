---
name: upload-file
description: Use when a user asks to upload, publish, share, preview, or host a generated or existing file so another person, tool, or agent can open it by URL.
---

# Upload File

Upload one local file with the installed `upload` command. The command does return a URL that let everyone that has it to view the uploaded file.

## Upload

1. Resolve the exact local path and confirm that it is a file.
2. Run exactly one command:

   ```sh
   upload "/absolute/path/to/file"
   ```

3. Return the URL printed on stdout. Do not expose the upload token.

If the command or either setting is missing, report what must be installed or configured. 

## Guardrails

- Upload only the file the user identified or that the current task produced.
- Ask before uploading sensitive or private material when the user's intent to publish it is unclear.

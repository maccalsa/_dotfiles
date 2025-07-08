#!/bin/bash
LANG="$1"

case "$LANG" in
  python)
    snippet="import asyncio\n\nasync def my_async_func():\n    pass\n\nasyncio.run(my_async_func())"
    ;;
  java|kotlin)
    snippet="// CompletableFuture example\nCompletableFuture.runAsync(() -> {\n    // async task\n});"
    ;;
  typescript)
    snippet="async function myAsyncFunc() {\n    await asyncTask();\n}"
    ;;
  go)
    snippet="// Use goroutine\ngo func() {\n    // async task\n}()"
    ;;
  *)
    zenity --error --text="Unsupported language"; exit 1 ;;
esac

echo -e "$snippet"

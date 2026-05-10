#!/usr/bin/env python3
"""Render pi --mode json JSONL stream as streaming terminal output.

Reads JSONL from stdin, writes human-readable output to stdout.
Shows thinking content (dimmed) and text content streamed in real-time.

Flags:
  --text-only    Only output the final text content (for programmatic capture).
"""

import json
import os
import sys

PI_SHOW_THINKING = os.environ.get("PI_SHOW_THINKING", "true").lower() not in (
    "false",
    "0",
    "no",
)
TEXT_ONLY = "--text-only" in sys.argv

DIM = "\033[90m"
RESET = "\033[0m"


def render_stream(infile, outfile):
    in_thinking = False
    thinking_shown = False
    turns = 0
    text_started = False
    last_text_end_content = None

    for line in infile:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        event_type = event.get("type", "")

        if event_type == "turn_start":
            if turns > 0 and not TEXT_ONLY:
                outfile.write("\n")
                outfile.flush()
            turns += 1

        elif event_type == "message_update":
            msg_event = event.get("assistantMessageEvent") or {}
            inner_type = msg_event.get("type", "")

            if inner_type == "thinking_start":
                in_thinking = True
                if PI_SHOW_THINKING and not TEXT_ONLY:
                    outfile.write(DIM)
                    outfile.flush()

            elif inner_type == "thinking_delta":
                if PI_SHOW_THINKING and not TEXT_ONLY:
                    delta = msg_event.get("delta", "")
                    outfile.write(delta)
                    outfile.flush()
                    thinking_shown = True

            elif inner_type == "thinking_end":
                in_thinking = False
                if thinking_shown and not TEXT_ONLY:
                    outfile.write(RESET + "\n\n")
                    outfile.flush()
                    thinking_shown = False

            elif inner_type == "text_start":
                # End thinking mode when text content begins
                if in_thinking and thinking_shown and not TEXT_ONLY:
                    outfile.write(RESET + "\n\n")
                    outfile.flush()
                    thinking_shown = False
                    in_thinking = False

            elif inner_type == "text_delta":
                if not TEXT_ONLY:
                    text_started = True
                    delta = msg_event.get("delta", "")
                    outfile.write(delta)
                    outfile.flush()

            elif inner_type == "text_end":
                content = msg_event.get("content", "")
                if TEXT_ONLY:
                    last_text_end_content = content
                elif text_started:
                    if content and not content.endswith("\n"):
                        outfile.write("\n")
                    outfile.flush()

        elif event_type == "tool_execution_start" and not TEXT_ONLY:
            tool_name = event.get("toolName", "tool")
            args = event.get("args", {})
            summary = ""
            if "command" in args:
                summary = args["command"]
            elif "path" in args:
                summary = args["path"]
            if summary:
                outfile.write(f"\n{DIM}  \U0001f527 {tool_name}: {summary}{RESET}\n")
            else:
                outfile.write(f"\n{DIM}  \U0001f527 {tool_name}{RESET}\n")
            outfile.flush()

    # In text-only mode, emit the last text content at the end
    if TEXT_ONLY and last_text_end_content is not None:
        outfile.write(last_text_end_content)
        if not last_text_end_content.endswith("\n"):
            outfile.write("\n")
        outfile.flush()

    # Ensure we end with a newline in streaming mode
    if not TEXT_ONLY:
        outfile.write("\n")
        outfile.flush()


if __name__ == "__main__":
    try:
        render_stream(sys.stdin, sys.stdout)
    except BrokenPipeError:
        devnull = os.open(os.devnull, os.O_WRONLY)
        os.dup2(devnull, sys.stdout.fileno())
        sys.exit(0)
    except KeyboardInterrupt:
        sys.exit(130)

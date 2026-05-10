#!/usr/bin/env python3
"""Render pi --mode json JSONL stream as streaming terminal output.

Reads JSONL from stdin, writes human-readable output to stdout.
Shows thinking content (dimmed) and text content streamed in real-time.

Flags:
  --text-only    Only output the final text content (for programmatic capture).
"""

import json
import os
import shutil
import subprocess
import sys
import threading

PI_SHOW_THINKING = os.environ.get("PI_SHOW_THINKING", "true").lower() not in (
    "false",
    "0",
    "no",
)
TEXT_ONLY = "--text-only" in sys.argv
GLOW_BIN = shutil.which("glow")


def _detect_glow_style():
    """Pick glow style based on terminal background color."""
    colorfgbg = os.environ.get("COLORFGBG", "")
    if colorfgbg:
        try:
            bg = int(colorfgbg.split(";")[-1])
            return "light" if bg >= 8 else "dark"
        except (ValueError, IndexError):
            pass
    return "light"


GLOW_STYLE = _detect_glow_style()

DIM = "\033[90m"
RESET = "\033[0m"
SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
SPINNER_LABEL = " Working ..."


class Spinner:
    """Background spinner animation shown while waiting for stream data."""

    def __init__(self, outfile):
        self.outfile = outfile
        self._stop = threading.Event()
        self._thread = None
        self.active = False
        self.label = SPINNER_LABEL

    def start(self):
        if self.active or TEXT_ONLY:
            return
        self.active = True
        self._stop.clear()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def _run(self):
        i = 0
        while not self._stop.wait(0.08):
            frame = SPINNER_FRAMES[i % len(SPINNER_FRAMES)]
            self.outfile.write(f"\r\033[94m{frame}{self.label}{RESET}")
            self.outfile.flush()
            i += 1

    def stop(self):
        if not self.active:
            return
        self._stop.set()
        if self._thread:
            self._thread.join()
            self._thread = None
        self.active = False
        self.outfile.write("\r\033[K")
        self.outfile.flush()


def _render_markdown(content):
    """Render markdown content via glow, falling back to plain text."""
    if not GLOW_BIN:
        return content
    try:
        result = subprocess.run(
            [GLOW_BIN, "-s", GLOW_STYLE],
            input=content,
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return content


def render_stream(infile, outfile):
    in_thinking = False
    thinking_shown = False
    thinking_buffer = ""
    turns = 0
    text_started = False
    text_buffer = ""
    last_text_end_content = None
    spinner = Spinner(outfile)
    spinner.start()

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
                spinner.stop()
                in_thinking = True
                if PI_SHOW_THINKING and not TEXT_ONLY:
                    if GLOW_BIN:
                        spinner.label = " Thinking ..."
                        spinner.start()
                    else:
                        outfile.write(DIM)
                        outfile.flush()

            elif inner_type == "thinking_delta":
                if PI_SHOW_THINKING and not TEXT_ONLY:
                    delta = msg_event.get("delta", "")
                    if GLOW_BIN:
                        thinking_buffer += delta
                    else:
                        outfile.write(delta)
                        outfile.flush()
                    thinking_shown = True

            elif inner_type == "thinking_end":
                in_thinking = False
                if thinking_shown and not TEXT_ONLY:
                    if GLOW_BIN and thinking_buffer:
                        spinner.stop()
                        spinner.label = SPINNER_LABEL
                        rendered = _render_markdown(thinking_buffer)
                        outfile.write(DIM + rendered + RESET + "\n")
                        thinking_buffer = ""
                    else:
                        outfile.write(RESET + "\n\n")
                    outfile.flush()
                    thinking_shown = False
                spinner.start()

            elif inner_type == "text_start":
                spinner.stop()
                # End thinking mode when text content begins
                if in_thinking and thinking_shown and not TEXT_ONLY:
                    if GLOW_BIN and thinking_buffer:
                        spinner.stop()
                        rendered = _render_markdown(thinking_buffer)
                        outfile.write(DIM + rendered + RESET + "\n\n")
                        thinking_buffer = ""
                    else:
                        outfile.write(RESET + "\n\n")
                    outfile.flush()
                    thinking_shown = False
                    in_thinking = False
                # Show receiving indicator when buffering for glow
                if GLOW_BIN and not TEXT_ONLY:
                    spinner.label = " Receiving ..."
                    spinner.start()

            elif inner_type == "text_delta":
                if not TEXT_ONLY:
                    text_started = True
                    delta = msg_event.get("delta", "")
                    if GLOW_BIN:
                        text_buffer += delta
                    else:
                        outfile.write(delta)
                        outfile.flush()

            elif inner_type == "text_end":
                content = msg_event.get("content", "")
                if TEXT_ONLY:
                    last_text_end_content = content
                elif text_started:
                    if GLOW_BIN and text_buffer:
                        spinner.stop()
                        spinner.label = SPINNER_LABEL
                        rendered = _render_markdown(text_buffer)
                        outfile.write(rendered)
                        if not rendered.endswith("\n"):
                            outfile.write("\n")
                        text_buffer = ""
                    elif content and not content.endswith("\n"):
                        outfile.write("\n")
                    outfile.flush()
                spinner.start()

        elif event_type == "tool_execution_start" and not TEXT_ONLY:
            spinner.stop()
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
            spinner.start()

    spinner.stop()

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

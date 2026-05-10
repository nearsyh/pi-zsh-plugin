#!/usr/bin/env python3
"""Render pi --mode json JSONL stream as streaming terminal output.

Reads JSONL from stdin, writes human-readable output to stdout.
Shows thinking content (dimmed) and text content streamed in real-time.

Flags:
  --text-only    Only output the final text content (for programmatic capture).
"""

import fcntl
import json
import os
import pty
import shutil
import struct
import subprocess
import sys
import termios
import threading

PI_SHOW_THINKING = os.environ.get("PI_SHOW_THINKING", "true").lower() not in (
    "false",
    "0",
    "no",
)
TEXT_ONLY = "--text-only" in sys.argv
GLOW_BIN = shutil.which("glow")
_GLOW_STYLE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "markdown-style.json"
)


def _detect_glow_style():
    """Pick glow style based on terminal background color."""
    # Custom style uses standard ANSI colors that work on both light/dark
    if os.path.isfile(_GLOW_STYLE_PATH):
        return _GLOW_STYLE_PATH
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
        master, slave = pty.openpty()
        # Match PTY size to actual terminal so glow wraps correctly
        try:
            size = shutil.get_terminal_size()
            winsize = struct.pack('HHHH', size.lines, size.columns, 0, 0)
            fcntl.ioctl(slave, termios.TIOCSWINSZ, winsize)
        except (OSError, ValueError):
            pass
        _cols = min(shutil.get_terminal_size().columns or 80, 120)
        proc = subprocess.Popen(
            [GLOW_BIN, "-s", GLOW_STYLE, "-w", str(_cols)],
            stdin=subprocess.PIPE,
            stdout=slave,
            stderr=slave,
            env={
                **os.environ,
                "TERM": os.environ.get("TERM", "xterm-256color"),
            },
        )
        os.close(slave)
        proc.stdin.write(content.encode())
        proc.stdin.close()
        output = b""
        while True:
            chunk = os.read(master, 4096)
            if not chunk:
                break
            output += chunk
        os.close(master)
        proc.wait(timeout=5)
        decoded = output.decode("utf-8", errors="replace")
        if proc.returncode == 0 and decoded.strip():
            return decoded
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return content


def _flush_thinking(outfile, state):
    """Flush buffered thinking content to output."""
    if not state["thinking_shown"]:
        return
    if GLOW_BIN and state["thinking_buffer"]:
        spinner = state["spinner"]
        spinner.stop()
        spinner.label = SPINNER_LABEL
        # Normalize LLM thinking newlines: keep paragraph breaks,
        # collapse single mid-sentence newlines to spaces
        raw = state["thinking_buffer"]
        normalized = raw.replace("\n\n", "\x00PARA\x00").replace("\n", " ").replace("\x00PARA\x00", "\n\n")
        rendered = _render_markdown("> " + normalized)
        outfile.write(rendered)
        state["thinking_buffer"] = ""
    else:
        outfile.write(RESET + "\n\n")
    outfile.flush()
    state["thinking_shown"] = False
    state["in_thinking"] = False


def _flush_text(outfile, state):
    """Flush buffered text content to output."""
    if TEXT_ONLY:
        return
    if GLOW_BIN and state["text_buffer"]:
        state["spinner"].stop()
        state["spinner"].label = SPINNER_LABEL
        rendered = _render_markdown(state["text_buffer"])
        outfile.write(rendered)
        if not rendered.endswith("\n"):
            outfile.write("\n")
        state["text_buffer"] = ""
    elif state.get("text_started") and not state.get("text_end_content", "").endswith(
        "\n"
    ):
        outfile.write("\n")
    outfile.flush()


def render_stream(infile, outfile):
    spinner = Spinner(outfile)
    state = {
        "in_thinking": False,
        "thinking_shown": False,
        "thinking_buffer": "",
        "text_started": False,
        "text_buffer": "",
        "text_end_content": "",
        "spinner": spinner,
    }
    turns = 0
    last_text_end_content = None
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
                state["in_thinking"] = True
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
                    if state["thinking_buffer"] == "":
                        state["thinking_buffer"] = "Thinking: "
                    if GLOW_BIN:
                        state["thinking_buffer"] += delta
                    else:
                        outfile.write(delta)
                        outfile.flush()
                    state["thinking_shown"] = True

            elif inner_type == "thinking_end":
                if state["thinking_shown"] and not TEXT_ONLY:
                    _flush_thinking(outfile, state)
                spinner.start()

            elif inner_type == "text_start":
                spinner.stop()
                # End thinking mode when text content begins
                if state["in_thinking"] and state["thinking_shown"] and not TEXT_ONLY:
                    _flush_thinking(outfile, state)
                # Show receiving indicator when buffering for glow
                if GLOW_BIN and not TEXT_ONLY:
                    spinner.label = " Receiving ..."
                    spinner.start()

            elif inner_type == "text_delta":
                if not TEXT_ONLY:
                    state["text_started"] = True
                    delta = msg_event.get("delta", "")
                    if GLOW_BIN:
                        state["text_buffer"] += delta
                    else:
                        outfile.write(delta)
                        outfile.flush()

            elif inner_type == "text_end":
                content = msg_event.get("content", "")
                if TEXT_ONLY:
                    last_text_end_content = content
                elif state["text_started"] and not TEXT_ONLY:
                    state["text_end_content"] = content
                    _flush_text(outfile, state)
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
                if len(summary) >= 30:
                    summary = summary[:27] + '...'
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

#!/usr/bin/env python3

import json
import os
import select
import sys
import termios
import tty

from kitty.boss import Boss

TYPES = {
    "u": ("URL", "url"),
    "y": ("Hyperlink", "hyperlink"),
    "p": ("Path", "path"),
    "n": ("Line number", "linenum"),
    "w": ("Word", "word"),
    "l": ("Line", "line"),
    "h": ("Hash", "hash"),
    "i": ("IP address", "ip"),
    "r": ("Regex", "regex"),
}


PROGRAMS = {
    "o": ("Open / default", "default"),
    "c": ("Copy to clipboard", "@"),
    "p": ("Paste into terminal", "-"),
    "s": ("Primary selection", "*"),
    "n": ("No explicit program", None),
}


def write(text: str = "") -> None:
    sys.stdout.write(text)


def writeln(text: str = "") -> None:
    sys.stdout.write(text + "\r\n")


def flush() -> None:
    sys.stdout.flush()


def clear_screen() -> None:
    write("\x1b[2J\x1b[H")
    flush()


def draw_box(
    title: str,
    rows: list[tuple[str, str]],
    footer: str = "",
    width: int = 40,
) -> None:
    title_part = f"─ {title} "

    writeln("╭" + title_part + "─" * max(0, width - len(title_part)) + "╮")

    for key, label in rows:
        content = f"  {key:<10}{label}"
        writeln("│" + content.ljust(width) + "│")

    if footer:
        writeln("│" + " " * width + "│")
        writeln("│" + f"  {footer}".ljust(width) + "│")

    writeln("╰" + "─" * width + "╯")
    writeln()

    flush()


def get_tty():
    return open("/dev/tty", "rb", buffering=0)


def read_single_key(fd: int) -> str:
    ch = os.read(fd, 1)

    if ch == b"\x1b":
        return "ESC"

    if ch in (b"\x7f", b"\x08"):
        return "BACKSPACE"

    if ch == b"\x03":
        return "CTRL_C"

    try:
        return ch.decode("utf-8").lower()
    except UnicodeDecodeError:
        return ""


def choose_type(fd: int):
    rows = [
        ("u", "URL"),
        ("y", "Hyperlink"),
        ("p", "Path"),
        ("n", "Line number"),
        ("w", "Word"),
        ("l", "Line"),
        ("h", "Hash"),
        ("i", "IP address"),
        ("r", "Regex"),
    ]

    while True:
        clear_screen()

        draw_box(
            "Hints · Type",
            rows,
            "q / Esc   Cancel",
        )

        write("Select: ")
        flush()

        key = read_single_key(fd)

        if key in ("q", "ESC", "CTRL_C"):
            return None

        if key in TYPES:
            return TYPES[key][1]


def redraw_regex(text: list[str], pos: int) -> None:
    value = "".join(text)

    # 回到行首 + 清除当前行
    write("\r\x1b[2K")
    write("Regex: " + value)

    # 输入内容已经全部打印出来，重新把光标移到逻辑位置
    move_left = len(text) - pos

    if move_left > 0:
        write(f"\x1b[{move_left}D")

    flush()


def draw_regex_page(text: list[str], pos: int) -> None:
    clear_screen()

    draw_box(
        "Hints · Regex",
        [
            ("Enter", "Continue"),
            ("Esc", "Back"),
            ("Ctrl+C", "Cancel"),
        ],
    )

    redraw_regex(text, pos)


def edit_regex(fd: int, initial: str = ""):
    text = list(initial)
    pos = len(text)

    draw_regex_page(text, pos)

    while True:
        ch = os.read(fd, 1)

        if ch in (b"\r", b"\n"):
            value = "".join(text)

            if value:
                return "ok", value

            continue

        if ch == b"\x1b":
            # 单独 Esc 与方向键都以 ESC 开头，等待极短时间看看后面还有没有 escape sequence。
            ready, _, _ = select.select([fd], [], [], 0.03)

            if not ready:
                return "back", "".join(text)

            second = os.read(fd, 1)

            if second != b"[":
                return "back", "".join(text)

            key = os.read(fd, 1)

            # Left
            if key == b"D":
                pos = max(0, pos - 1)

            # Right
            elif key == b"C":
                pos = min(len(text), pos + 1)

            # Home
            elif key == b"H":
                pos = 0

            # End
            elif key == b"F":
                pos = len(text)

            # ESC [ number ~
            elif key.isdigit():
                seq = bytearray(key)

                while True:
                    c = os.read(fd, 1)
                    seq.extend(c)

                    if c == b"~":
                        break

                seq = bytes(seq)

                # Delete
                if seq == b"3~":
                    if pos < len(text):
                        del text[pos]

                # Home
                elif seq in (b"1~", b"7~"):
                    pos = 0

                # End
                elif seq in (b"4~", b"8~"):
                    pos = len(text)

            redraw_regex(text, pos)
            continue

        # Ctrl-C

        if ch == b"\x03":
            return "cancel", ""

        # Ctrl-A: 行首
        if ch == b"\x01":
            pos = 0
            redraw_regex(text, pos)
            continue

        # Ctrl-E: 行尾
        if ch == b"\x05":
            pos = len(text)
            redraw_regex(text, pos)
            continue

        # Ctrl-U: 删除光标左边
        if ch == b"\x15":
            del text[:pos]
            pos = 0
            redraw_regex(text, pos)
            continue

        # Ctrl-K: 删除光标右边
        if ch == b"\x0b":
            del text[pos:]
            redraw_regex(text, pos)
            continue

        # Ctrl-W: 删除前一个单词
        if ch == b"\x17":
            while pos > 0 and text[pos - 1].isspace():
                del text[pos - 1]
                pos -= 1

            while pos > 0 and not text[pos - 1].isspace():
                del text[pos - 1]
                pos -= 1

            redraw_regex(text, pos)
            continue

        # Backspace
        if ch in (b"\x7f", b"\x08"):
            if pos > 0:
                del text[pos - 1]
                pos -= 1

            redraw_regex(text, pos)
            continue

        if ch and ch[0] >= 0x20:
            data = bytearray(ch)

            if ch[0] >= 0xC0:
                if ch[0] < 0xE0:
                    needed = 1
                elif ch[0] < 0xF0:
                    needed = 2
                else:
                    needed = 3

                for _ in range(needed):
                    data.extend(os.read(fd, 1))

            try:
                value = data.decode("utf-8")
            except UnicodeDecodeError:
                continue

            text.insert(pos, value)
            pos += 1

            redraw_regex(text, pos)


def choose_program(fd: int):
    rows = [
        ("o", "Open with default program"),
        ("c", "Copy to clipboard"),
        ("p", "Paste into terminal"),
        ("s", "Primary selection"),
        ("n", "Use hints default behavior"),
    ]

    while True:
        clear_screen()

        draw_box(
            "Hints · Program",
            rows,
            "Esc / Backspace   Back",
        )

        write("Select: ")
        flush()

        key = read_single_key(fd)

        if key in ("ESC", "BACKSPACE"):
            return "back", None

        if key == "CTRL_C":
            return "cancel", None

        if key in PROGRAMS:
            return "ok", PROGRAMS[key][1]


def main(args: list[str]) -> str:
    current_type = None
    regex = ""

    with get_tty() as tty_in:
        fd = tty_in.fileno()
        old = termios.tcgetattr(fd)

        try:
            tty.setraw(fd)

            page = "type"

            while True:
                # Type

                if page == "type":
                    current_type = choose_type(fd)

                    if current_type is None:
                        return ""

                    if current_type == "regex":
                        page = "regex"
                    else:
                        page = "program"

                # Regex
                elif page == "regex":
                    result, value = edit_regex(fd, regex)

                    if result == "cancel":
                        return ""

                    if result == "back":
                        regex = value
                        page = "type"
                        continue

                    regex = value
                    page = "program"

                # Program
                elif page == "program":
                    result, program = choose_program(fd)

                    if result == "cancel":
                        return ""

                    if result == "back":
                        if current_type == "regex":
                            page = "regex"
                        else:
                            page = "type"

                        continue

                    # Build native hints arguments
                    hint_args = [
                        "--type",
                        current_type,
                    ]

                    if current_type == "regex":
                        hint_args += [
                            "--regex",
                            regex,
                        ]

                    if program is not None:
                        hint_args += [
                            "--program",
                            program,
                        ]

                    return json.dumps(hint_args)

        finally:
            termios.tcsetattr(
                fd,
                termios.TCSADRAIN,
                old,
            )


def handle_result(
    args: list[str],
    result: str,
    target_window_id: int,
    boss: Boss,
) -> None:
    if not result:
        return

    try:
        hint_args = json.loads(result)
    except (TypeError, json.JSONDecodeError):
        return

    target = boss.window_id_map.get(target_window_id)

    if target is None:
        return

    boss.run_kitten_with_metadata(
        "hints",
        args=hint_args,
        window=target,
    )

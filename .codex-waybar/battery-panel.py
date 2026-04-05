#!/usr/bin/env python3

import math
import os
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Gtk4LayerShell


BAT_PATH = Path("/sys/class/power_supply/BAT0")
LIMIT_PATH = Path("/sys/devices/platform/lg-laptop/battery_care_limit")
TOGGLE_SCRIPT = "/home/Arch/Downloads/vscode/Archthings/.codex-waybar/battery-care-toggle-user.sh"


def read_text(path: Path, default: str = "") -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except Exception:
        return default


def read_int(path: Path, default: int = 0) -> int:
    try:
        return int(read_text(path, str(default)))
    except Exception:
        return default


def format_duration(hours: float) -> str:
    if hours <= 0 or not math.isfinite(hours):
        return "剩余时间：--"
    total_minutes = int(round(hours * 60))
    h, m = divmod(total_minutes, 60)
    return f"剩余时间：{h}:{m:02d}"


class BatteryPanel(Adw.Application):
    def __init__(self) -> None:
        super().__init__(application_id="local.codex.batterypanel")
        self.window = None
        self.profile_buttons = {}
        self.updating_switch = False

    def do_activate(self) -> None:
        if self.window is None:
            self.window = self.build_window()
        self.window.present()
        self.refresh()

    def build_window(self) -> Gtk.ApplicationWindow:
        window = Gtk.ApplicationWindow(application=self)
        window.set_decorated(False)
        window.set_resizable(False)
        window.set_default_size(420, 300)
        window.connect("notify::is-active", self.on_active_changed)

        Gtk4LayerShell.init_for_window(window)
        Gtk4LayerShell.set_namespace(window, "codex-battery-panel")
        Gtk4LayerShell.set_layer(window, Gtk4LayerShell.Layer.TOP)
        Gtk4LayerShell.set_anchor(window, Gtk4LayerShell.Edge.BOTTOM, True)
        Gtk4LayerShell.set_anchor(window, Gtk4LayerShell.Edge.RIGHT, True)
        Gtk4LayerShell.set_margin(window, Gtk4LayerShell.Edge.BOTTOM, 58)
        Gtk4LayerShell.set_margin(window, Gtk4LayerShell.Edge.RIGHT, 12)
        Gtk4LayerShell.set_keyboard_mode(window, Gtk4LayerShell.KeyboardMode.ON_DEMAND)

        provider = Gtk.CssProvider()
        provider.load_from_data(
            """
            window {
              background: transparent;
            }

            .panel {
              background: rgba(24, 26, 38, 0.96);
              border-radius: 18px;
              border: 1px solid rgba(180, 190, 254, 0.45);
              box-shadow: 0 18px 40px rgba(0, 0, 0, 0.35);
              padding: 16px;
            }

            .title {
              font-size: 20px;
              font-weight: 700;
              color: #cdd6f4;
            }

            .subtitle {
              color: rgba(205, 214, 244, 0.78);
              font-size: 13px;
            }

            .section {
              background: rgba(17, 17, 27, 0.82);
              border-radius: 14px;
              padding: 14px;
            }

            .metric {
              font-size: 32px;
              font-weight: 800;
              color: #cdd6f4;
            }

            .metric-small {
              color: rgba(205, 214, 244, 0.78);
              font-size: 14px;
            }

            progressbar trough {
              min-height: 10px;
              border-radius: 999px;
              background: rgba(255, 255, 255, 0.08);
            }

            progressbar progress {
              min-height: 10px;
              border-radius: 999px;
              background: #89b4fa;
            }

            .mode-btn {
              border-radius: 10px;
              padding: 10px 14px;
              background: rgba(255, 255, 255, 0.04);
              color: #cdd6f4;
            }

            .mode-btn.active-mode {
              background: rgba(180, 190, 254, 0.95);
              color: #11111b;
            }

            .switch-label {
              color: #cdd6f4;
              font-size: 15px;
              font-weight: 600;
            }
            """,
            -1,
        )
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        outer.add_css_class("panel")
        outer.set_margin_top(8)
        outer.set_margin_bottom(8)
        outer.set_margin_start(8)
        outer.set_margin_end(8)

        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        title = Gtk.Label(label="电量和电池", xalign=0)
        title.add_css_class("title")
        subtitle = Gtk.Label(label="实验版 Plasma 风格电池面板", xalign=0)
        subtitle.add_css_class("subtitle")
        header.append(title)
        header.append(subtitle)
        outer.append(header)

        summary = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        summary.add_css_class("section")

        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        left = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self.metric_label = Gtk.Label(label="--%", xalign=0)
        self.metric_label.add_css_class("metric")
        self.status_label = Gtk.Label(label="状态读取中", xalign=0)
        self.status_label.add_css_class("metric-small")
        left.append(self.metric_label)
        left.append(self.status_label)

        right = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.time_label = Gtk.Label(label="剩余时间：--", xalign=1)
        self.time_label.add_css_class("metric-small")
        self.limit_label = Gtk.Label(label="充电保护：--", xalign=1)
        self.limit_label.add_css_class("metric-small")
        right.append(self.time_label)
        right.append(self.limit_label)

        top_row.append(left)
        top_row.append(Gtk.Box(hexpand=True))
        top_row.append(right)
        summary.append(top_row)

        self.progress = Gtk.ProgressBar()
        self.progress.set_show_text(False)
        summary.append(self.progress)
        outer.append(summary)

        profiles = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        profiles.add_css_class("section")
        prof_label = Gtk.Label(label="电源管理方案", xalign=0)
        prof_label.add_css_class("switch-label")
        profiles.append(prof_label)

        button_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        for key, label in (
            ("power-saver", "节能"),
            ("balanced", "平衡"),
            ("performance", "性能"),
        ):
            btn = Gtk.Button(label=label)
            btn.add_css_class("mode-btn")
            btn.connect("clicked", self.on_profile_clicked, key)
            btn.set_hexpand(True)
            self.profile_buttons[key] = btn
            button_row.append(btn)
        profiles.append(button_row)
        outer.append(profiles)

        care = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        care.add_css_class("section")
        care_text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        care_title = Gtk.Label(label="限制充电到 80%", xalign=0)
        care_title.add_css_class("switch-label")
        care_sub = Gtk.Label(label="用于日常插电时减少长期满充", xalign=0)
        care_sub.add_css_class("subtitle")
        care_text.append(care_title)
        care_text.append(care_sub)
        care.append(care_text)
        care.append(Gtk.Box(hexpand=True))
        self.limit_switch = Gtk.Switch()
        self.limit_switch.set_valign(Gtk.Align.CENTER)
        self.limit_switch.connect("notify::active", self.on_limit_toggled)
        care.append(self.limit_switch)
        outer.append(care)

        window.set_child(outer)

        GLib.timeout_add_seconds(5, self.refresh)
        return window

    def on_active_changed(self, window, _param) -> None:
        if not window.is_active():
            window.close()
            self.quit()

    def battery_state(self) -> dict:
        capacity = read_int(BAT_PATH / "capacity", 0)
        status = read_text(BAT_PATH / "status", "Unknown")
        energy_now = read_int(BAT_PATH / "energy_now", 0)
        energy_full = read_int(BAT_PATH / "energy_full", 0)
        power_now = read_int(BAT_PATH / "power_now", 0)
        limit = read_int(LIMIT_PATH, 100)

        if power_now > 0:
            if status == "Charging":
                hours = max(0.0, (energy_full - energy_now) / power_now)
            else:
                hours = max(0.0, energy_now / power_now)
        else:
            hours = float("nan")

        return {
            "capacity": capacity,
            "status": status,
            "hours": hours,
            "limit": limit,
        }

    def current_profile(self) -> str:
        try:
            result = subprocess.run(
                ["powerprofilesctl", "get"],
                capture_output=True,
                text=True,
                check=False,
            )
            return result.stdout.strip() or "unknown"
        except Exception:
            return "unknown"

    def refresh(self):
        state = self.battery_state()
        profile = self.current_profile()

        status_map = {
            "Charging": "正在充电",
            "Discharging": "正在耗电",
            "Full": "已充满",
            "Not charging": "未在充电",
            "Unknown": "状态未知",
        }

        self.metric_label.set_label(f"{state['capacity']}%")
        self.status_label.set_label(status_map.get(state["status"], state["status"]))
        self.time_label.set_label(format_duration(state["hours"]))
        self.limit_label.set_label(
            "充电保护：已开启（80%）" if state["limit"] == 80 else "充电保护：已关闭（100%）"
        )
        self.progress.set_fraction(max(0.0, min(1.0, state["capacity"] / 100.0)))

        self.updating_switch = True
        self.limit_switch.set_active(state["limit"] == 80)
        self.updating_switch = False

        for key, btn in self.profile_buttons.items():
            if key == profile:
                btn.add_css_class("active-mode")
            else:
                btn.remove_css_class("active-mode")

        return True

    def on_profile_clicked(self, _button: Gtk.Button, profile: str) -> None:
        result = subprocess.run(
            ["powerprofilesctl", "set", profile],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            subprocess.run(
                ["notify-send", "电源模式", f"无法切换到 {profile}"],
                check=False,
            )
        self.refresh()

    def on_limit_toggled(self, switch: Gtk.Switch, _param) -> None:
        if self.updating_switch:
            return

        target = 80 if switch.get_active() else 100
        current = self.battery_state()["limit"]
        if current != target:
            result = subprocess.run([TOGGLE_SCRIPT], capture_output=True, text=True, check=False)
            if result.returncode != 0:
                subprocess.run(["notify-send", "Battery care", "切换充电限制失败"], check=False)
        self.refresh()


if __name__ == "__main__":
    app = BatteryPanel()
    sys.exit(app.run(sys.argv))

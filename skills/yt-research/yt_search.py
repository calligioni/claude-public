#!/usr/bin/env python3
"""YouTube search script using yt-dlp. Returns video metadata as JSON."""

import argparse
import json
import sys

# Force UTF-8 output on Windows to handle emoji/unicode in video titles
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def format_duration(seconds):
    if seconds is None:
        return "N/A"
    seconds = int(seconds)
    if seconds < 3600:
        return f"{seconds // 60}:{seconds % 60:02d}"
    return f"{seconds // 3600}:{(seconds % 3600) // 60:02d}:{seconds % 60:02d}"


def search_youtube(query: str, count: int) -> list[dict]:
    try:
        import yt_dlp
    except ImportError:
        print(json.dumps({"error": "yt-dlp not installed. Run: pip install yt-dlp"}))
        sys.exit(1)

    search_url = f"ytsearch{count}:{query}"

    ydl_opts = {
        "quiet": True,
        "no_warnings": True,
        "extract_flat": True,
        "ignoreerrors": True,
    }

    results = []
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(search_url, download=False)

    if not info or "entries" not in info:
        return results

    rank = 1
    for entry in info.get("entries", []):
        if not entry:
            continue
        # Skip channel entries (no duration field typically)
        entry_type = entry.get("_type") or ""
        if entry_type == "channel":
            continue

        video_id = entry.get("id") or entry.get("url", "")
        # Build canonical watch URL
        if video_id and not video_id.startswith("http"):
            url = f"https://www.youtube.com/watch?v={video_id}"
        else:
            url = entry.get("url") or entry.get("webpage_url") or ""

        duration_s = entry.get("duration")
        results.append({
            "rank": rank,
            "id": video_id,
            "title": entry.get("title") or "Unknown",
            "channel": entry.get("channel") or entry.get("uploader") or "Unknown",
            "views": entry.get("view_count"),
            "duration": format_duration(duration_s),
            "duration_seconds": duration_s,
            "url": url,
            "upload_date": entry.get("upload_date"),
        })
        rank += 1

    return results


def run_config():
    """Check and fix yt-dlp installation, then run a smoke test."""
    import subprocess

    checks = []

    def emit(step, status, detail, final=True):
        """Print a progress line. Only add to checks when final=True."""
        line = json.dumps({"step": step, "status": status, "detail": detail}, ensure_ascii=False)
        print(line, flush=True)
        if final:
            checks.append({"step": step, "status": status, "detail": detail})

    # Python version
    v = sys.version_info
    py_ok = v >= (3, 10)
    emit("python_version", "ok" if py_ok else "error",
         f"{v.major}.{v.minor}.{v.micro}" + ("" if py_ok else " — need >=3.10"))

    # yt-dlp package
    try:
        import yt_dlp as _yt
        emit("yt_dlp", "ok", getattr(_yt.version, "__version__", "installed"))
    except ImportError:
        emit("yt_dlp", "fixing", "not installed — running pip install yt-dlp...")
        r = subprocess.run(
            [sys.executable, "-m", "pip", "install", "yt-dlp"],
            capture_output=True, text=True,
        )
        if r.returncode == 0:
            emit("yt_dlp", "ok", "installed successfully")
        else:
            emit("yt_dlp", "error", f"install failed: {(r.stderr or r.stdout)[-200:]}")
            print(json.dumps({"summary": True, "overall": "errors", "checks": checks}))
            sys.exit(1)

    # Smoke test — 1 result search
    emit("smoke_test", "running", "searching for 1 video to verify network access...", final=False)
    try:
        results = search_youtube("test", 1)
        if results:
            emit("smoke_test", "ok", f"returned: \"{results[0]['title']}\" ({results[0]['channel']})")
        else:
            emit("smoke_test", "error", "search returned 0 results")
    except Exception as e:
        emit("smoke_test", "error", str(e))

    overall = "ready" if all(c["status"] in ("ok",) for c in checks) else "errors"
    print(json.dumps({"summary": True, "overall": overall, "checks": checks}, indent=2, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description="Search YouTube and return video metadata as JSON")
    parser.add_argument("--query", help="Search query")
    parser.add_argument("--count", type=int, default=25, help="Number of results (default: 25)")
    parser.add_argument("--output", choices=["json", "table"], default="json", help="Output format")
    parser.add_argument("--config", action="store_true", help="Check and fix dependencies, then exit")
    args = parser.parse_args()

    if args.config:
        run_config()
        return

    if not args.query:
        parser.error("--query is required (unless using --config)")

    videos = search_youtube(args.query, args.count)

    if args.output == "table":
        print(f"{'#':<4} {'Title':<60} {'Channel':<30} {'Views':<12} {'Duration':<10} URL")
        print("-" * 130)
        for v in videos:
            views = f"{v['views']:,}" if v["views"] is not None else "N/A"
            title = v["title"][:58] + ".." if len(v["title"]) > 60 else v["title"]
            channel = v["channel"][:28] + ".." if len(v["channel"]) > 30 else v["channel"]
            print(f"{v['rank']:<4} {title:<60} {channel:<30} {views:<12} {v['duration']:<10} {v['url']}")
    else:
        print(json.dumps(videos, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

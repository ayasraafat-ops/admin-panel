"""نقطة التشغيل — python run.py"""

import sys
import subprocess


def check_deps():
    """فحص وتثبيت المتطلبات"""
    needed = {
        "fastapi": "fastapi",
        "uvicorn": "uvicorn",
        "websockets": "websockets",
        "httpx": "httpx",
    }
    missing = []
    for mod, pkg in needed.items():
        try:
            __import__(mod)
        except ImportError:
            missing.append(pkg)

    if missing:
        print(f"\n  تثبيت: {', '.join(missing)}")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install"] + missing,
            stdout=subprocess.DEVNULL,
        )
        print("  ✅ تم\n")


def main():
    check_deps()

    import uvicorn
    from bot import PW_OK

    print()
    print("  ╔═══════════════════════════════════╗")
    print("  ║  Login Bot v9.0 + Screenshots     ║")
    print("  ║  http://localhost:8000             ║")
    print("  ╚═══════════════════════════════════╝")
    pw = "YES" if PW_OK else "NO → HTTP mode"
    print(f"  Playwright: {pw}")
    print()

    uvicorn.run("server:app", host="0.0.0.0", port=5000, reload=False)


if __name__ == "__main__":
    main()
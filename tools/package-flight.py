"""Rebuild the edit-mode flight installer from its single source of truth."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "src/client/ExplorerFlight.client.luau").read_text(encoding="utf-8")
assert "]====]" not in source
header = """-- Run in edit-mode Command Bar.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play first')
local p=game.StarterPlayer.StarterPlayerScripts
local old=p:FindFirstChild('ExplorerFlight') if old then old:Destroy() end
local s=Instance.new('LocalScript') s.Name='ExplorerFlight'
s.Source=[====["""
footer = """
]====]
s.Parent=p
print('EXPLORER_FLIGHT_INSTALLED')
"""
(ROOT / "install-flight.luau").write_text(header + source.rstrip() + footer, encoding="utf-8")
print("Packaged flight installer")

# Innworld RPG

A fan-made, non-commercial RPG set in *The Wandering Inn* by pirateaba.
You play an unnamed Earther who arrives at the start of Book 1.

- Engine: Godot 4.7, GDScript. Tests: GUT 9.7.
- Design: [docs/DESIGN.md](docs/DESIGN.md) · Roadmap: [docs/ROADMAP.md](docs/ROADMAP.md)

This repo holds no book text. The books belong to pirateaba.

## Run the tests (PowerShell)
```powershell
godot --headless --path game --import   # once, after a fresh clone
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

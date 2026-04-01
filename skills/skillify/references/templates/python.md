# Python Domain Guide

## Project Structure Patterns
- `src/<package>/` or `<package>/` — source code
- `tests/` — test files (pytest convention)
- `requirements.txt` — pip dependencies
- `pyproject.toml` — modern project config (PEP 621)
- `setup.py` / `setup.cfg` — legacy packaging
- `venv/` or `.venv/` — virtual environment (gitignored)
- `Makefile` — common task automation

## Build and Test Commands

**pip:**
- Install: `pip install -r requirements.txt`
- Install dev: `pip install -r requirements-dev.txt`
- Install editable: `pip install -e .`

**poetry:**
- Install: `poetry install`
- Run: `poetry run python script.py`
- Add dep: `poetry add <package>`

**pytest:**
- All tests: `pytest`
- Verbose: `pytest -v`
- Specific: `pytest tests/test_foo.py::test_bar`
- With coverage: `pytest --cov=src`

**uv:**
- Install: `uv pip install -r requirements.txt`
- Run: `uv run python script.py`

## Common Step Patterns

- **Environment step**: Create/activate venv, install dependencies
- **Test step**: Run pytest, check for failures and coverage
- **Lint step**: Run ruff/flake8/black before commit
- **Type check step**: Run mypy if type annotations are used
- **Script execution step**: Run Python script, capture output

## Recommended allowed-tools

```yaml
allowed-tools:
  - Bash(python:*)
  - Bash(pip:*)       # or poetry/uv
  - Bash(pytest:*)
  - Read
  - Edit
  - Write
  - Grep
  - Glob
```

## Common Pitfalls

- Virtual environment: always check if venv exists and is activated
- Python version: check `python_requires` or `.python-version`
- Import paths depend on how the package is installed (editable vs regular)
- `requirements.txt` may not pin versions — consider `pip freeze` for reproducibility
- Async code (asyncio) needs different test patterns (pytest-asyncio)

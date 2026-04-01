# Document Processing Domain Guide

## Common Patterns
- Reading documents: PDF, DOCX, XLSX, CSV, Markdown, plain text
- Content extraction: pulling structured data from unstructured documents
- Summarization: condensing long documents into key points
- Format conversion: transforming between file formats
- Template filling: populating templates with extracted data
- Batch processing: applying the same operation to multiple files

## Common Tools

**File reading:**
- PDF: Use `Read` tool (supports PDF with `pages` parameter)
- CSV/JSON/text: Use `Read` tool directly
- XLSX: May need `python` with `openpyxl` or `pandas`
- Images with text: Describe what you see using `Read` tool (multimodal)

**Data processing:**
```bash
# CSV manipulation with Python
python -c "import csv; ..."

# JSON processing
cat data.json | jq '.records[] | {name, email}'

# Text processing
grep -E 'pattern' document.txt
```

## Common Step Patterns

- **Intake step**: Read source document(s), identify format and structure
- **Extract step**: Pull out relevant data, tables, sections
- **Transform step**: Clean, normalize, restructure data
- **Validate step**: Check extracted data for completeness and consistency
- **Output step**: Write results in target format (CSV, JSON, Markdown, new document)
- **Summary step**: Generate human-readable summary of findings

## Recommended allowed-tools

```yaml
allowed-tools:
  - Read                 # PDF, text, images, CSV
  - Write                # Output files
  - Edit                 # Modify existing documents
  - Bash(python:*)       # Complex data processing
  - Bash(jq:*)           # JSON processing
  - Glob                 # Find files by pattern
  - Grep                 # Search within files
```

## Common Pitfalls

- **Large PDFs**: Must specify page ranges (`pages: "1-20"`), max 20 pages per read — plan chunked reading
- **Encoding issues**: Non-UTF-8 files may need explicit encoding handling
- **Table extraction from PDF**: Tables in PDFs are notoriously unreliable — verify extracted structure
- **File paths with spaces**: Always quote file paths in commands
- **Overwriting originals**: Always confirm before modifying source documents — prefer writing to new files
- **Sensitive content**: Documents may contain PII or confidential data — warn before external processing

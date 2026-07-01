# Contributing

Thanks for helping improve SysReport.

## Local Checks

```bash
make check
bash bin/sysreport --list-sections
bash bin/sysreport --section system --no-color
```

## Adding a Report Section

Create a new file under `src/sysreport/modules/` and register it:

```bash
report_example() {
  sysreport_section "Example"
  sysreport_item "Status" "ok"
}

sysreport_register_section "example" "Example report" "report_example"
```

Keep modules read-only by default. A report command should never install packages, restart services, edit configuration, or delete files.

## Style

- Prefer portable Bash and common Linux utilities.
- Check for optional commands with `sysreport_have`.
- If a command is missing or access is denied, print a skipped or unknown result instead of failing the whole report.
- Keep output useful for humans first.

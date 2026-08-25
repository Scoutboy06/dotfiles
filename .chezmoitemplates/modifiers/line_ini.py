def _section_name(line):
    candidate = line.strip()
    if len(candidate) >= 2 and candidate[0] == "[" and candidate[-1] == "]":
        return candidate[1:-1]
    return None


def _assignment(line):
    if line.endswith("\r\n"):
        body, ending = line[:-2], "\r\n"
    elif line.endswith("\n"):
        body, ending = line[:-1], "\n"
    else:
        body, ending = line, ""

    stripped = body.lstrip()
    if not stripped or stripped.startswith(("#", ";")) or "=" not in body:
        return None

    raw_key, value = body.split("=", 1)
    key = raw_key.strip()
    if not key:
        return None
    return key, value, ending


def _newline_for(text):
    return "\r\n" if "\r\n" in text else "\n"


def _append_missing(lines, desired, seen, newline):
    missing = [key for key, value in desired.items() if key not in seen and value is not None]
    if not missing:
        return

    if lines and not lines[-1].endswith(("\n", "\r")):
        lines[-1] += newline
    lines.extend(f"{key}={desired[key]}{newline}" for key in missing)
    seen.update(missing)


def patch_ini_section(text, section_name, desired_values):
    desired = {
        str(key): None if value is None else str(value)
        for key, value in desired_values.items()
    }
    if not desired:
        return text

    newline = _newline_for(text)
    lines = text.splitlines(keepends=True)
    first_start = None
    first_end = len(lines)

    for index, line in enumerate(lines):
        current_section = _section_name(line)
        if current_section is None:
            continue
        if first_start is None:
            if current_section == section_name:
                first_start = index
        else:
            first_end = index
            break

    if first_start is None:
        present = {key: value for key, value in desired.items() if value is not None}
        if not present:
            return text
        block = [f"[{section_name}]{newline}"]
        block.extend(f"{key}={value}{newline}" for key, value in present.items())
        if text:
            block.append(newline)
        return "".join(block) + text

    insertion_index = first_end
    while insertion_index > first_start + 1 and not lines[insertion_index - 1].strip():
        insertion_index -= 1

    output = []
    seen = set()
    in_section = False

    for index, line in enumerate(lines):
        if index == insertion_index:
            _append_missing(output, desired, seen, newline)

        current_section = _section_name(line)
        if current_section is not None:
            in_section = current_section == section_name
            output.append(line)
            continue

        assignment = _assignment(line)
        if not in_section or assignment is None or assignment[0] not in desired:
            output.append(line)
            continue

        key, current_value, ending = assignment
        if key in seen:
            continue
        seen.add(key)

        desired_value = desired[key]
        if desired_value is None:
            continue
        if current_value == desired_value:
            output.append(line)
        else:
            output.append(f"{key}={desired_value}{ending}")

    if insertion_index == len(lines):
        _append_missing(output, desired, seen, newline)

    return "".join(output)

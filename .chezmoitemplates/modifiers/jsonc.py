import json


def _without_jsonc_comments(text):
    output = list(text)
    index = 0
    in_string = False
    escaped = False

    while index < len(text):
        character = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            index += 1
            continue

        if character == '"':
            in_string = True
            index += 1
            continue

        if character == "/" and index + 1 < len(text):
            marker = text[index + 1]
            if marker == "/":
                output[index] = output[index + 1] = " "
                index += 2
                while index < len(text) and text[index] not in "\r\n":
                    output[index] = " "
                    index += 1
                continue
            if marker == "*":
                output[index] = output[index + 1] = " "
                index += 2
                while index + 1 < len(text):
                    if text[index] == "*" and text[index + 1] == "/":
                        output[index] = output[index + 1] = " "
                        index += 2
                        break
                    if text[index] not in "\r\n":
                        output[index] = " "
                    index += 1
                continue

        index += 1

    return "".join(output)


def _without_trailing_commas(text):
    output = []
    index = 0
    in_string = False
    escaped = False

    while index < len(text):
        character = text[index]
        if in_string:
            output.append(character)
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
            index += 1
            continue

        if character == '"':
            in_string = True
            output.append(character)
            index += 1
            continue

        if character == ",":
            lookahead = index + 1
            while lookahead < len(text) and text[lookahead].isspace():
                lookahead += 1
            if lookahead < len(text) and text[lookahead] in "}]":
                index += 1
                continue

        output.append(character)
        index += 1

    return "".join(output)


def _parse_jsonc(text):
    cleaned = _without_trailing_commas(_without_jsonc_comments(text))
    if not cleaned.strip():
        return {}
    return json.loads(cleaned)


def _matches(current, desired):
    if not isinstance(current, dict) or not isinstance(desired, dict):
        return current == desired
    return all(key in current and _matches(current[key], value) for key, value in desired.items())


def _deep_merge(current, desired):
    for key, value in desired.items():
        if isinstance(value, dict) and isinstance(current.get(key), dict):
            _deep_merge(current[key], value)
        else:
            current[key] = value
    return current


def merge_jsonc(text, desired_values):
    if not isinstance(desired_values, dict):
        raise TypeError("desired JSONC values must be an object")

    uncommented = _without_jsonc_comments(text)
    root_start = uncommented.find("{")
    if root_start < 0:
        header = "" if not text.strip() else text
        body = ""
    else:
        header = text[:root_start]
        body = text[root_start:]

    current = _parse_jsonc(body)
    if not isinstance(current, dict):
        raise TypeError("JSONC root must be an object")
    if _matches(current, desired_values):
        return text

    merged = _deep_merge(current, desired_values)
    newline = "\r\n" if "\r\n" in text else "\n"
    rendered = json.dumps(merged, ensure_ascii=False, indent=2) + "\n"
    if newline != "\n":
        rendered = rendered.replace("\n", newline)
    return header + rendered

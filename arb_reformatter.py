#!/usr/bin/env python3

import json
import os


def read_file_lines(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return file.readlines()


def read_file_json(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return json.load(file)


def write_to_file(file_path, text):
    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(text)

# Translation table for unicode characters we want to keep in escaped form.
trans = str.maketrans({
    '\u00a0': r"\u00a0", # No-Break Space (NBSP)
    '\u2026': r"\u2026"  # Horizontal Ellipsis
})

# Move keys in target into same order as in source.
# Keys not present in source are removed from target.
# Returns a new value of target; does not mutate arguments.
def equalize_key_order(source, target):
    if isinstance(source, dict) and isinstance(target, dict):
        target_result = {}
        for key in source.keys():
            if key in target and target[key] is not None:
                source_value = source[key]
                target_value = target[key]

                if key == "placeholders":
                    # Placeholders might use different variable names than in
                    # the source file; don't delete them if they do.
                    target_result[key] = target_value
                else:
                    target_result[key] = equalize_key_order(source_value, target_value)

            else:
                if key.startswith("@"):
                    target_result[key] = source[key]
                else:
                    target_result[key] = None
        return target_result

    else:
        return target


# Function to update the ARB files
def update_arb_file(source_path, target_path, language_code):
    source_lines = read_file_lines(source_path)
    source_json = read_file_json(source_path)
    target_json = read_file_json(target_path)

    target_reordered = equalize_key_order(source_json, target_json)
    target_text = json.dumps(target_reordered, indent=4, ensure_ascii=False)
    target_text = target_text.translate(trans)
    target_lines = target_text.splitlines()

    for i, line in enumerate(source_lines):
        if line.strip() == "":
            target_lines.insert(i, "")

    write_to_file(target_path, "\n".join(target_lines).strip() + "\n")


if __name__ == "__main__":
    source_file_path = 'lib/l10n/app_en.arb'
    target_directory = 'lib/l10n'

    for file_name in os.listdir(target_directory):
        if file_name.startswith('app_') and file_name.endswith('.arb'):
            target_file_path = os.path.join(target_directory, file_name)
            language_code = file_name.split('_')[1].split('.')[0]
            update_arb_file(source_file_path, target_file_path, language_code)
            print(f'File updated: {file_name}')

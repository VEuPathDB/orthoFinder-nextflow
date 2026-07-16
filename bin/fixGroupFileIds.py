#!/usr/bin/env python3

"""
Reconcile sequence IDs in a groups file against real proteome fasta headers.

OrthoFinder is inconsistent about substituting ':' and '_' in sequence IDs
when it builds its internal ID mappings: sometimes ':' becomes '_', sometimes
'_' becomes ':', sometimes neither. Any ID in the groups file that doesn't
exactly match a real fasta header is relinked by comparing a normalized form
(':' and '_' treated as equivalent) against the real headers, in whichever
direction is needed.
"""

import sys
import glob

if len(sys.argv) < 3:
    sys.stderr.write("Usage: fixGroupFileIds.py <proteome_fasta_or_glob> [...] <group_file>\n")
    sys.exit(1)

proteome_args = sys.argv[1:-1]
group_file = sys.argv[-1]


def normalize(seq_id):
    return seq_id.replace(':', '\0').replace('_', '\0')


real_ids = set()
for arg in proteome_args:
    paths = glob.glob(arg) or [arg]
    for path in paths:
        with open(path) as f:
            for line in f:
                if line.startswith('>'):
                    real_ids.add(line[1:].split()[0])

# Map normalized ID -> real ID, tracking any normalized form that more than
# one distinct real ID maps to. Those can't be safely auto-corrected.
normalized_index = {}
ambiguous_keys = set()
for real_id in real_ids:
    key = normalize(real_id)
    existing = normalized_index.get(key)
    if existing is not None and existing != real_id:
        ambiguous_keys.add(key)
    normalized_index[key] = real_id

fixed = 0
unresolved = []


def resolve(seq_id):
    global fixed
    if seq_id in real_ids:
        return seq_id
    key = normalize(seq_id)
    if key in normalized_index and key not in ambiguous_keys:
        fixed += 1
        return normalized_index[key]
    unresolved.append(seq_id)
    return seq_id


lines = []
with open(group_file) as f:
    for line in f:
        parts = line.rstrip('\n').split(': ', 1)
        if len(parts) == 2:
            group_id, seq_ids_str = parts
            fixed_ids = [resolve(s) for s in seq_ids_str.split()]
            lines.append(group_id + ': ' + ' '.join(fixed_ids) + '\n')
        else:
            lines.append(line)

with open('fixedGroupFile.txt', 'w') as f:
    f.writelines(lines)

sys.stderr.write(f"fixGroupFileIds: corrected {fixed} sequence ID(s)\n")

if unresolved:
    preview = ', '.join(unresolved[:5])
    sys.stderr.write(
        f"fixGroupFileIds: ERROR {len(unresolved)} sequence ID(s) in {group_file} could "
        f"not be matched to any proteome header even after ':'/'_' normalization "
        f"(e.g. {preview}). Every sequence must resolve to a group assignment.\n"
    )
    sys.exit(1)

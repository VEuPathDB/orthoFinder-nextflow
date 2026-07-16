#!/usr/bin/env python3

"""
Reconcile sequence IDs in the residual Orthogroups.txt / SequenceIDs.txt files
against the real (pre-OrthoFinder) residual proteome fasta headers.

OrthoFinder is inconsistent about substituting ':' and '_' in sequence IDs:
sometimes ':' becomes '_', sometimes '_' becomes ':', sometimes neither. Any ID
that doesn't exactly match a real fasta header is relinked by comparing a
normalized form (':' and '_' treated as equivalent), in whichever direction is
needed. Every sequence ID must be resolvable after this correction -- an
unresolved ID means a real protein would silently lose its group assignment
downstream, so that is treated as a hard failure rather than a warning.
"""

import sys

residual_fasta = sys.argv[1]

fasta_ids = set()
with open(residual_fasta) as f:
    for line in f:
        if line.startswith('>'):
            fasta_ids.add(line[1:].split()[0])


def normalize(seq_id):
    return seq_id.replace(':', '\0').replace('_', '\0')


normalized_index = {}
ambiguous_keys = set()
for real_id in fasta_ids:
    key = normalize(real_id)
    existing = normalized_index.get(key)
    if existing is not None and existing != real_id:
        ambiguous_keys.add(key)
    normalized_index[key] = real_id

fixed = 0
unresolved = set()


def fix_id(seq_id):
    global fixed
    if seq_id in fasta_ids:
        return seq_id
    key = normalize(seq_id)
    if key in normalized_index and key not in ambiguous_keys:
        fixed += 1
        return normalized_index[key]
    unresolved.add(seq_id)
    return seq_id


lines = []
with open('Orthogroups.txt') as f:
    for line in f:
        parts = line.rstrip().split(': ', 1)
        if len(parts) == 2:
            og_id, seq_ids_str = parts
            fixed_ids = ' '.join(fix_id(s) for s in seq_ids_str.split())
            lines.append(og_id + ': ' + fixed_ids + '\n')
        else:
            lines.append(line)
with open('Orthogroups.txt', 'w') as f:
    f.writelines(lines)

lines = []
with open('SequenceIDs.txt') as f:
    for line in f:
        parts = line.rstrip().split(': ', 1)
        if len(parts) == 2:
            internal_id, defline = parts
            words = defline.split(' ', 1)
            fixed_seq_id = fix_id(words[0])
            rest = (' ' + words[1]) if len(words) > 1 else ''
            lines.append(internal_id + ': ' + fixed_seq_id + rest + '\n')
        else:
            lines.append(line)
with open('SequenceIDs.txt', 'w') as f:
    f.writelines(lines)

# Strip full deflines -- keep only "internal_id: seq_id"
lines = []
with open('SequenceIDs.txt') as f:
    for line in f:
        parts = line.rstrip().split(': ', 1)
        if len(parts) == 2:
            internal_id, defline = parts
            seq_id = defline.split()[0] if defline.split() else defline
            lines.append(internal_id + ': ' + seq_id + '\n')
        else:
            lines.append(line)
with open('SequenceIDs.txt', 'w') as f:
    f.writelines(lines)

sys.stderr.write(f"fixResidualOrthologIds: corrected {fixed} sequence ID(s)\n")

if unresolved:
    preview = ', '.join(list(unresolved)[:5])
    sys.stderr.write(
        f"fixResidualOrthologIds: ERROR {len(unresolved)} sequence ID(s) could not be "
        f"matched to any proteome header in {residual_fasta} even after ':'/'_' "
        f"normalization (e.g. {preview}). Every sequence must resolve to a group "
        f"assignment.\n"
    )
    sys.exit(1)

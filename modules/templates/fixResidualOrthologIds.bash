#!/usr/bin/env bash

set -euo pipefail

python3 << PYEOF
fasta_ids = set()
with open('$residualFasta') as f:
    for line in f:
        if line.startswith('>'):
            fasta_ids.add(line[1:].split()[0])

reverse_map = {}
for fid in fasta_ids:
    modified = fid.replace(':', '_')
    if modified != fid:
        reverse_map[modified] = fid

def fix_id(seq_id):
    if seq_id in fasta_ids:
        return seq_id
    return reverse_map.get(seq_id, seq_id)

lines = []
with open('Orthogroups.txt') as f:
    for line in f:
        parts = line.rstrip('\n').split(': ', 1)
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
        parts = line.rstrip('\n').split(': ', 1)
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
PYEOF

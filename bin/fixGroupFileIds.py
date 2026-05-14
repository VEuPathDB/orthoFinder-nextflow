#!/usr/bin/env python3

import sys

proteome_fasta = sys.argv[1]
group_file = sys.argv[2]

fasta_ids = set()
with open(proteome_fasta) as f:
    for line in f:
        if line.startswith('>'):
            fasta_ids.add(line[1:].split()[0])

def try_fix_id(seq_id):
    if seq_id in fasta_ids:
        return seq_id
    for i, c in enumerate(seq_id):
        if c == '_':
            candidate = seq_id[:i] + ':' + seq_id[i+1:]
            if candidate in fasta_ids:
                return candidate
    return seq_id

lines = []
with open(group_file) as f:
    for line in f:
        parts = line.rstrip().split(': ', 1)
        if len(parts) == 2:
            group_id, seq_ids_str = parts
            fixed_ids = [try_fix_id(s) for s in seq_ids_str.split()]
            lines.append(group_id + ': ' + ' '.join(fixed_ids) + '\n')
        else:
            lines.append(line)

with open('fixedGroupFile.txt', 'w') as f:
    f.writelines(lines)

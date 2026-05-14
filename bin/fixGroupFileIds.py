#!/usr/bin/env python3

import sys
from itertools import combinations

proteome_fasta = sys.argv[1]
group_file = sys.argv[2]

fasta_ids = set()
with open(proteome_fasta) as f:
    for line in f:
        if line.startswith('>'):
            fasta_ids.add(line[1:].split()[0])

def find_fasta_id(seq_id):
    if seq_id in fasta_ids:
        return seq_id
    # Try replacing increasing numbers of '_' with ':' until a fasta match is found.
    # Handles cases where OrthoFinder replaced multiple ':' with '_'.
    underscore_positions = [i for i, c in enumerate(seq_id) if c == '_']
    for n in range(1, len(underscore_positions) + 1):
        for positions in combinations(underscore_positions, n):
            chars = list(seq_id)
            for pos in positions:
                chars[pos] = ':'
            candidate = ''.join(chars)
            if candidate in fasta_ids:
                return candidate
    return seq_id

lines = []
with open(group_file) as f:
    for line in f:
        parts = line.rstrip().split(': ', 1)
        if len(parts) == 2:
            group_id, seq_ids_str = parts
            fixed_ids = [find_fasta_id(s) for s in seq_ids_str.split()]
            lines.append(group_id + ': ' + ' '.join(fixed_ids) + '\n')
        else:
            lines.append(line)

with open('fixedGroupFile.txt', 'w') as f:
    f.writelines(lines)

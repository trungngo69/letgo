import sys
cnf, sol = sys.argv[1], sys.argv[2]
val = set(int(x) for x in open(sol).read().split() if x.strip() and x.strip() != '0')
bad = 0; n = 0
for line in open(cnf):
    if not line or line[0] in 'cp%\n': continue
    lits = [int(x) for x in line.split() if x != '0']
    if not lits: continue
    n += 1
    if not any(l in val for l in lits): bad += 1
print('verify clauses', n, 'unsat', bad); sys.exit(1 if bad or n == 0 else 0)

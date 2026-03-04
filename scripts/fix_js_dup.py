#!/usr/bin/env python3
"""Remove linha duplicada no change handler"""

FILE = "app/assets/javascripts/models/order_services.js"
with open(FILE, "r") as f:
    lines = f.readlines()

# Encontrar e remover a segunda ocorrência consecutiva
new_lines = []
skip_next = False
for i, line in enumerate(lines):
    if skip_next:
        skip_next = False
        continue
    # Check if this line and next 2 lines are a duplicate of the preceding 2
    if (i + 1 < len(lines) and
        "div-requisicao-download" in line and
        "div-requisicao-download" in lines[i+1] and
        "removeClass" in line and 
        "removeClass" in lines[i+1]):
        # Keep only the first one, skip the second
        new_lines.append(line)
        skip_next = True
        print(f"  Removida linha duplicada {i+2}: {lines[i+1].strip()}")
        continue
    new_lines.append(line)

with open(FILE, "w") as f:
    f.writelines(new_lines)

print("OK")
